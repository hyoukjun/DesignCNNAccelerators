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

/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;


interface BottomSwitch;
  interface SwitchInPort              gatherInPort;
  interface SwitchOutPort             gatherOutPort;
  interface SwitchInPort              scatterInPort;
  interface SwitchOutPort             scatterOutPort;
  interface Vector#(3, SwitchInPort)  interPEInPort;
  interface Vector#(3, SwitchOutPort) interPEOutPort;
  method Action initialize(NumPEsBit initPEID);
endinterface

(* synthesize *)
module mkBottomSwitch(BottomSwitch);

  Reg#(Bool)                 inited           <- mkReg(False);
  Reg#(NumPEsBit)            peID             <- mkRegU;
  Reg#(MS_SetupSignal)       controlSignal    <- mkReg(0);
//  CReg#(2, Bool)             isScatterSent    <- mkCReg(False);
  Fifo#(1, Flit)             gatherFlitFifo    <- mkBypassFifo;
  Fifo#(1, Flit)             scatterFlitFifo   <- mkBypassFifo;

  Vector#(3, Fifo#(1, Flit)) localFlitOutFifos <- replicateM(mkBypassFifo);
  Vector#(3, Fifo#(1, Flit)) localFlitInFifos  <- replicateM(mkBypassFifo);
  Fifo#(1, Flit)             localFlitToHost   <- mkBypassFifo;

  Vector#(3, CReg#(3, Bit#(1))) deqBits        <- replicateM(mkCReg(0));

  /*
  rule deqScatterFlit(isScatterSent[1] == True);
    scatterFlitFifo.deq;
    isScatterSent[1] <= False;
  endrule
  */

  rule deqScatterFlit;
    scatterFlitFifo.deq;
  endrule

  /* Dequeue Local flits */
  rule setupDeqBit_0;
    if(localFlitInFifos[0].notEmpty) begin
      deqBits[0][0] <= 1;
    end
    else if (localFlitInFifos[2].notEmpty && localFlitInFifos[2].first.localDest < peID) begin
      deqBits[2][0] <= 1;
    end
  endrule

  rule setupDeqBit_1;
    if(localFlitInFifos[1].notEmpty) begin
      //If localFlit[0] and [1] wants to go to the host output, prioritize the localFlit[0] over [1]
      if(!(localFlitInFifos[0].notEmpty && localFlitInFifos[0].first.localDest == peID && localFlitInFifos[1].first.localDest == peID))
        deqBits[1][0] <= 1;
    end
    else if (localFlitInFifos[2].notEmpty && localFlitInFifos[2].first.localDest > peID) begin
      deqBits[2][1] <= 1;
    end
  endrule

  rule deqLocalFifos;
    for(Integer prt = 0; prt<3; prt=prt+1)
    begin
      if(deqBits[prt][2] == 1) begin
        localFlitInFifos[prt].deq;
        deqBits[prt][2] <= 0;
      end
    end
  endrule

  /* LocalFlit traverse */
  rule selectHostPortWinner;
    if(localFlitInFifos[0].notEmpty && localFlitInFifos[0].first.localDest == peID) begin
      `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] local flit port %d -> %d", peID, 0, 2);
      `endif
      localFlitOutFifos[2].enq(localFlitInFifos[0].first);
    end
    else if(localFlitInFifos[1].notEmpty && localFlitInFifos[1].first.localDest == peID) begin
      `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] local flit in port %d -> %d", peID, 1, 2);
      `endif
      localFlitOutFifos[2].enq(localFlitInFifos[1].first);
    end
  endrule

  rule selectLocalPortWinner0;
    if(localFlitInFifos[0].notEmpty && localFlitInFifos[0].first.localDest != peID) begin
      `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] local flit in port %d -> %d", peID, 0, 0);
      `endif
      localFlitOutFifos[0].enq(localFlitInFifos[0].first);
    end
    else if(localFlitInFifos[2].notEmpty && localFlitInFifos[2].first.localDest < peID) begin
      `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] local flit in port %d -> %d", peID, 2, 0);
      `endif
      localFlitOutFifos[0].enq(localFlitInFifos[2].first);
    end
  endrule

  rule selectLocalPortWinner1;
    if(localFlitInFifos[1].notEmpty && localFlitInFifos[1].first.localDest != peID) begin
      `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] local flit in port %d -> %d", peID, 1, 1);
      `endif
      localFlitOutFifos[1].enq(localFlitInFifos[1].first);
    end
    else if(localFlitInFifos[2].notEmpty && localFlitInFifos[2].first.localDest > peID) begin
      `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] local flit in port %d -> %d", peID, 2, 1);
      `endif
      localFlitOutFifos[1].enq(localFlitInFifos[2].first);
    end
  endrule

  Vector#(3, SwitchInPort)  interPEInPortDummy;
  Vector#(3, SwitchOutPort) interPEOutPortDummy;
  for(Integer dirn = 0; dirn < 3 ; dirn = dirn+1)
  begin
     interPEInPortDummy[dirn] =
      interface SwitchInPort
        method Action putFlit(Flit flit) if(inited);
        `ifdef DEBUG_BOTTOMSWITCH
          $display("[BottomSwitch[%d]] Received a local flit in %d", peID, dirn);
        `endif

          localFlitInFifos[dirn].enq(flit);
        //TODO Need to arbitrate with broadcast; add another buffer to control this and give priority
        endmethod
      endinterface;

    interPEOutPortDummy[dirn] =
      interface SwitchOutPort
        method ActionValue#(Flit) getFlit if(inited);
        `ifdef DEBUG_BOTTOMSWITCH
          $display("[BottomSwitch[%d]] Sending a local flit to %d", peID, dirn);
        `endif
          localFlitOutFifos[dirn].deq;
          return  localFlitOutFifos[dirn].first;
        endmethod
      endinterface;
  end 
  interface interPEInPort = interPEInPortDummy;
  interface interPEOutPort = interPEOutPortDummy;

  interface SwitchInPort gatherInPort;
    method Action putFlit(Flit flit) if(inited);
      `ifdef DEBUG_BOTTOMSWITCH
      $display("[BottomSwitch[%d]] Received a gather flit", peID);
      `endif
      gatherFlitFifo.enq(flit);
    endmethod
  endinterface

  interface SwitchOutPort gatherOutPort;
    method ActionValue#(Flit) getFlit if(inited);
      `ifdef DEBUG_BOTTOMSWITCH
      $display("[BottomSwitch[%d]] Sending a gather flit", peID);
      `endif
      gatherFlitFifo.deq;
      return gatherFlitFifo.first;
    endmethod
  endinterface

  interface SwitchInPort scatterInPort;
    method Action putFlit(Flit flit) if(inited);
      `ifdef DEBUG_BOTTOMSWITCH
      $display("[BottomSwitch[%d]] Received a scatter flit", peID);
      `endif
      scatterFlitFifo.enq(flit);
    endmethod
  endinterface

  interface SwitchOutPort scatterOutPort;
    method ActionValue#(Flit) getFlit if(inited && (scatterFlitFifo.notEmpty || localFlitOutFifos[2].notEmpty));
      //Prioritize scatter Flits
      if(scatterFlitFifo.notEmpty) begin
        `ifdef DEBUG_BOTTOMSWITCH
        $display("[BottomSwitch[%d]] Delivered the scatter flit to PE", peID);
        `endif
//        isScatterSent[0] <= True;
        return scatterFlitFifo.first;
      end
      else begin
        localFlitOutFifos[2].deq;
        return localFlitOutFifos[2].first;
      end
    endmethod
  endinterface

  method Action initialize(NumPEsBit initPEID) if(!inited);
    peID <= initPEID;
    inited <= True;
  endmethod

endmodule
