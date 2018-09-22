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
import Vector::*;
import Fifo::*;
import CReg::*;
import Randomizable::*;

/* NoC types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import GlobalBufferTypes::*;

/* NoC modules */
import MicroswitchController::*;

/* Neural network modules */
import GlobalBuffer::*;

(* synthesize *)
module mkGlobalBufferMicroswitchNIC(GlobalBufferNIC);

  function Flit globalBufferMsg2Flit(GlobalBufferMsg msg);
    Flit flit = ?;
    flit.msgType = msg.dataType;
    flit.dests = msg.dests;
    flit.flitData = msg.pixelData;
    return flit;
  endfunction

  Reg#(Maybe#(GlobalBufferMsg)) currMsg          <- mkReg(Invalid);
  CReg#(2, Bool)                injectionSuccess <- mkCReg(False);

  /* For broadcasting */
  Reg#(RowID) currRowID <- mkReg(0);
  Reg#(ColID) currColID <- mkReg(0);

  Reg#(Bool) inited <- mkReg(False);

  Fifo#(1, GlobalBufferMsg)     outMsgFifo <- mkBypassFifo;

  Randomize#(Data)     recvRand  <- mkConstrainedRandomizer(0, 99);
  Randomize#(Data)     delayRand  <- mkConstrainedRandomizer(1,3);
  Reg#(Data)           delayReg <- mkReg(0);

  MicroswitchController msController <- mkMicroswitchController;


  Fifo#(2, MS_ScatterSetupSignal) controlSignalOutFifo <- mkBypassFifo;
  Fifo#(2, Flit)                  flitOutFifo          <- mkPipelineFifo;
  Fifo#(1, Flit)                  flitInFifo           <- mkPipelineFifo;

  let runningBroadcast = isValid(currMsg) 
                         && (validValue(currMsg).msgType == Broadcast);

  let runningMulticast = isValid(currMsg) 
                         && (validValue(currMsg).msgType == Multicast);

  rule doInit(!inited);
    inited <= True;
    delayRand.cntrl.init;
    recvRand.cntrl.init;
  endrule


  rule do_Broadcast(runningBroadcast);
    Flit newFlit = ?;
    newFlit.msgType = validValue(currMsg).dataType;
    //Destination
    MS_DestBits dest = 0;
    for(Integer targ = 0; targ < valueOf(NumPEs); targ = targ+1) begin
      dest[targ] = 1;
    end
    newFlit.dests = dest;
    newFlit.flitData = validValue(currMsg).pixelData;

    `ifdef DEBUG_GLOBALBUFFERNIC
      $display("[GlobalBufferNIC] Broadcast. Destination encoding: %b", dest);
    `endif

    let controlSignal = msController.getScatterControlSignal(dest);
    controlSignalOutFifo.enq(controlSignal);
    flitOutFifo.enq(newFlit);
    currMsg <= Invalid;
  endrule

  rule do_MulticastControl(runningMulticast && injectionSuccess[1] == True);
    //Check Finish broadcasting
    `ifdef DEBUG_GLOBALBUFFERNIC
      $display("[GlobalBufferNIC]Multicasting, current target: (%d, %d)", currRowID, currColID);
    `endif
    if((currRowID == fromInteger(valueOf(NumPERows))-1)
        && (currColID == fromInteger(valueOf(NumPEColumns))-1)
    ) begin
      `ifdef DEBUG_GLOBALBUFFERNIC
        $display("[GlobalBufferNIC]Finished multicasting. Invalidate current message");
      `endif
      currRowID <= 0;
      currColID <= 0;
      currMsg <= Invalid;
    end
    else if(currColID == fromInteger(valueOf(NumPEColumns))-1) begin
      currRowID <= currRowID +1;
      currColID <= 0;
    end
    else begin
      currColID <= currColID + 1;
    end
    injectionSuccess[1] <= False;
  endrule

  rule do_receiveFlits;
    let recvFlit = flitInFifo.first;
    flitInFifo.deq;
    GlobalBufferMsg outMsg = GlobalBufferMsg{msgType: Gather, dataType: ?, dests: 0, pixelData:1};
    outMsgFifo.enq(outMsg);
  endrule

  rule do_multicastFlitInjection(runningMulticast);
    Flit newFlit = ?;
    newFlit.msgType = validValue(currMsg).dataType;
    //Destination
    MS_DestBits dest = 0;
    Data targIdx = zeroExtend(currRowID) * fromInteger(valueOf(NumPEColumns)) + zeroExtend(currColID);
    dest[targIdx] = 1;
    newFlit.dests = dest;

    newFlit.flitData = validValue(currMsg).pixelData;

    `ifdef DEBUG_GLOBALBUFFERNIC
      $display("[GlobalBufferNIC] currRowID, currColID = (%d, %d) ", currRowID, currColID);
      $display("[GlobalBufferNIC] Destination: %d Destination encoding: %b", targIdx, dest);
    `endif

    let controlSignal = msController.getScatterControlSignal(dest);
    controlSignalOutFifo.enq(controlSignal);

    flitOutFifo.enq(newFlit);
    injectionSuccess[0] <= True;
  endrule

  Vector#(NumBuffer2NetworkPorts, NetworkExternalInterface) ntkPortsDummy;
  for(Integer prt = 0; prt < valueOf(NumBuffer2NetworkPorts); prt = prt+1) begin
    ntkPortsDummy[prt] = 
      interface NetworkExternalInterface
        method Action putFlit(Flit flit);
          `ifdef DEBUG_GLOBALBUFFERNIC
            $display("[GlobalBufferNIC] port[%d]: receiving a flit", prt);
         `endif
          flitInFifo.enq(flit);
        endmethod

        method ActionValue#(Flit) getFlit;
          `ifdef DEBUG_GLOBALBUFFERNIC
            $display("[GlobalBufferNIC] port[%d]: sending a flit", prt);
          `endif
          flitOutFifo.deq;
          let flit = flitOutFifo.first;
          return flit;
        endmethod

      endinterface;
  end
  interface ntkPorts = ntkPortsDummy; 

  interface GlobalBufferPort bufferPort;
    method Action enqMsg(GlobalBufferMsg msg) if(!isValid(currMsg));
      currMsg <= Valid(msg);
    endmethod

    method ActionValue#(GlobalBufferMsg) deqMsg;
      outMsgFifo.deq;
      return outMsgFifo.first;
    endmethod
  endinterface

  method ActionValue#(MS_ScatterSetupSignal) getSetupSignal;
    `ifdef DEBUG_GLOBALBUFFERNIC
     $display("[GlobalBufferNIC] sending a control signal");
    `endif

    controlSignalOutFifo.deq;
    let controlSignal = controlSignalOutFifo.first;
    return controlSignal;
  endmethod

endmodule
