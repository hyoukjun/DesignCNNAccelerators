/******************************************************************************
Author: Hyoukjun Kwon (hyoukjun@gatech.edu)

Copyright (c) 2017 Georgia Instititue of Technology

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*******************************************************************************/

/* Primitives */
import Fifo::*;
import Vector::*;
import CReg::*;

/* Microswitch types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;

interface TopSwitch;
  interface Vector#(3, SwitchInPort)  gatherInPort;
  interface SwitchOutPort             gatherOutPort;
  interface SwitchInPort              scatterInPort;
  interface Vector#(2, SwitchOutPort) scatterOutPort;
  method Action configureSwitch(MS_SetupSignal newControlSignal);
endinterface

(* synthesize *)
module mkTopSwitch(TopSwitch);
  Reg#(MS_SetupSignal)                         controlSignal <- mkReg(0);
  CReg#(3, Bool)                               isSent        <- mkCReg(False);
  Fifo#(1, Flit)                               scatterFifo   <- mkBypassFifo;
  Fifo#(1, Flit)                               gatherOutFifo <- mkBypassFifo;
  Vector#(3, Fifo#(MS_GatherFifoDepth, Flit))  gatherInFifos <- replicateM(mkPipelineFifo);

  rule deqToPEFlit(isSent[2] == True);
    `ifdef DEBUG_TOPSWITCH
    $display("[TopSwitch] deq the scatter out flit");
    `endif
    scatterFifo.deq;
    isSent[2] <= False;
  endrule

  rule sendGatherFlit;
    if(gatherInFifos[0].notEmpty) begin
      gatherOutFifo.enq(gatherInFifos[0].first);
      gatherInFifos[0].deq;
    end
    else if(gatherInFifos[1].notEmpty) begin
      gatherOutFifo.enq(gatherInFifos[1].first);
      gatherInFifos[1].deq;

    end
    else if(gatherInFifos[2].notEmpty) begin
      gatherOutFifo.enq(gatherInFifos[2].first);
      gatherInFifos[2].deq;
    end

  endrule

  Vector#(3, SwitchInPort) gatherInPortDummy;
  for(Integer prt =0; prt<3; prt=prt+1) 
  begin
    gatherInPortDummy[prt] = 
      interface SwitchInPort
        method Action putFlit(Flit flit);
        `ifdef DEBUG_TOPSWITCH
        $display("[TopSwitch] received a gather flit");
        `endif
          gatherInFifos[prt].enq(flit);
        endmethod
      endinterface;
  end


  Vector#(2, SwitchOutPort) scatterOutPortDummy;
  for(Integer prt=0; prt<2; prt=prt+1)
  begin
    scatterOutPortDummy[prt] =
      interface SwitchOutPort
        method ActionValue#(Flit) getFlit if(controlSignal[1-prt] ==1);
        `ifdef DEBUG_TOPSWITCH
        $display("[TopSwitch] send a scatter flit to %d", prt);
        `endif
          isSent[prt] <= True;
          return scatterFifo.first;
        endmethod
      endinterface;
  end
  interface scatterOutPort =  scatterOutPortDummy;
  interface gatherInPort = gatherInPortDummy;

  interface SwitchOutPort gatherOutPort;
    method ActionValue#(Flit) getFlit;
      `ifdef DEBUG_TOPSWITCH
      $display("[TopSwitch] send a gather flit");
      `endif
      gatherOutFifo.deq;
      return gatherOutFifo.first;
    endmethod
  endinterface

  interface SwitchInPort scatterInPort;
    method Action putFlit(Flit flit);
      `ifdef DEBUG_TOPSWITCH
      $display("[TopSwitch] received a scatter flit");
      `endif
      scatterFifo.enq(flit);
    endmethod
  endinterface


  method Action configureSwitch(MS_SetupSignal newControlSignal);
    `ifdef DEBUG_TOPSWITCH
    $display("[TopSwitch] received a controlsignal %b",newControlSignal);
    `endif
    controlSignal <= newControlSignal;
  endmethod
endmodule
