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

interface MiddleSwitch;
  interface SwitchInPort              scatterInPort;
  interface Vector#(2, SwitchOutPort) scatterOutPort;
  interface SwitchInPort              gatherInPort;
  interface SwitchOutPort             gatherOutPort;
  method Action configureSwitch(MS_SetupSignal newControlSignal);
endinterface

(* synthesize *)
module mkMiddleSwitch(MiddleSwitch);

  Reg#(MS_SetupSignal)   controlSignal   <- mkReg(0);
  Fifo#(1, Flit)         gatherFlitFifo  <- mkBypassFifo;
  Fifo#(1, Flit)         scatterFlitFifo <- mkBypassFifo;

  rule deqFlit;
    scatterFlitFifo.deq;
  endrule

  Vector#(2, SwitchOutPort) scatterOutPortDummy;
  for(Integer prt = 0; prt<2; prt=prt+1) begin
    scatterOutPortDummy[prt] =
      interface SwitchOutPort
        method ActionValue#(Flit) getFlit if(controlSignal[1-prt] == 1);
          `ifdef DEBUG_MIDDLESWITCH
          $display("[MiddleSwitch] Send a scatter flit to port %d", prt);
          `endif
          let flit = scatterFlitFifo.first;
          return flit;
        endmethod
      endinterface;
  end
  interface scatterOutPort = scatterOutPortDummy;

  interface SwitchInPort scatterInPort;
    method Action putFlit(Flit flit);
      `ifdef DEBUG_MIDDLESWITCH
      $display("[MiddleSwitch] Received a scatter flit");
      `endif
      scatterFlitFifo.enq(flit);
    endmethod
  endinterface

  interface SwitchInPort gatherInPort;
    method Action putFlit(Flit flit);
      `ifdef DEBUG_MIDDLESWITCH
      $display("[MiddleSwitch] Received a gather flit");
      `endif
      gatherFlitFifo.enq(flit);
    endmethod
  endinterface

  interface SwitchOutPort gatherOutPort;
    method ActionValue#(Flit) getFlit;
      `ifdef DEBUG_MIDDLESWITCH
      $display("[MiddleSwitch] Sending a gather flit");
      `endif
      let flit = gatherFlitFifo.first;
      gatherFlitFifo.deq;
      return flit;
    endmethod
  endinterface

  method Action configureSwitch(MS_SetupSignal newControlSignal);
    controlSignal <= newControlSignal;
  endmethod

endmodule
