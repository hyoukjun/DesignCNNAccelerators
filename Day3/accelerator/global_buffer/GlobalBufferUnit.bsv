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
import Connectable::*;

/* NoC Types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neuralnetwork Types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import DerivedNeuralNetworkConfig::*;
import GlobalBufferTypes::*;

/* Neuralnetwork Modules */
`ifdef RS
import RS_GlobalBuffer::*;
import RS_GlobalBufferMicroswitchNIC::*;
`else
import GlobalBuffer::*;
import GlobalBufferMicroswitchNIC::*;
`endif



function Data countOnes(DestBits dest);
  Data oneCount = 0;
  for(Integer d = 0; d<valueOf(NumPEs); d=d+1) begin
    if(dest[d] == 1) oneCount = oneCount +1;
  end
  return oneCount;
endfunction


(* synthesize *)
module mkGlobalBufferUnit(GlobalBufferUnit);
  `ifdef RS
  GlobalBuffer rs_globalBuffer <- mkRS_GlobalBuffer;
  `else
  GlobalBuffer ws_globalBuffer <- mkWS_GlobalBuffer;
  `endif

  GlobalBufferNIC globalBufferNIC <- mkGlobalBufferMicroswitchNIC;

  /* Statistics */
  Reg#(Data) numInjectedWeights <- mkReg(0);
  Reg#(Data) numInjectedIfMaps <- mkReg(0);
  Reg#(Data) numReceivedPSums <- mkReg(0);

  /* Connections between global buffer and NIC*/
  for(Integer prt = 0; prt < valueOf(NumGlobalBufferPorts); prt=prt+1) 
  begin
    `ifdef WS
    mkConnection(ws_globalBuffer.bufferPort.enqMsg,
                   globalBufferNIC.bufferPort.deqMsg);

    mkConnection(ws_globalBuffer.bufferPort.deqMsg,
                   globalBufferNIC.bufferPort.enqMsg);
    `elsif RS
    mkConnection(rs_globalBuffer.bufferPort.enqMsg,
                   globalBufferNIC.bufferPort.deqMsg);

    mkConnection(rs_globalBuffer.bufferPort.deqMsg,
                   globalBufferNIC.bufferPort.enqMsg);
    `endif
  end

  /* Connections between global buffer NIC and NoC */
  Vector#(NumBuffer2NetworkPorts, NetworkExternalInterface) ntkPortsDummy = newVector;
  for(Integer prt = 0; prt < valueOf(NumBuffer2NetworkPorts); prt=prt+1) 
  begin
    ntkPortsDummy[prt] =
      interface NetworkExternalInterface
        method Action putFlit(Flit flit);
          if(flit.dests[valueOf(NumPEs) + prt] == 1) begin
            `ifdef DEBUG_GLOBALBUFFERUNIT
            $display("[GlobalBufferUnit]: Dests: %b Idx:%d Receiving a flit", flit.dests, valueOf(NumPEs)+prt);
            `endif
            numReceivedPSums <= numReceivedPSums + 1;
            globalBufferNIC.ntkPorts[prt].putFlit(flit);
          end
        endmethod

        method ActionValue#(Flit) getFlit;
          `ifdef DEBUG_GLOBALBUFFERUNIT
            $display("[GlobalBufferUnit]: Sending a flit");
          `endif
          let flit <- globalBufferNIC.ntkPorts[prt].getFlit;
          if(flit.msgType == Weight) begin
            `ifdef RS
                numInjectedWeights <= numInjectedWeights + countOnes(flit.dests);
            `elsif WS
              numInjectedWeights <= numInjectedWeights + 1;
            `endif
          end
          else begin
            `ifdef WS
              numInjectedIfMaps  <= numInjectedIfMaps + fromInteger(valueOf(NumPEs));
            `elsif RS
              numInjectedIfMaps  <= numInjectedIfMaps + countOnes(flit.dests);
            `endif
          end

          return flit;
        endmethod
      endinterface;
  end

  interface ntkPorts = ntkPortsDummy;

  interface GlobalBufferStat stats;
    method Data getNumWeights;
      return numInjectedWeights;
    endmethod

    method Data getNumIfMaps;
      return numInjectedIfMaps;
    endmethod

    method Data getNumPSums;
      return numReceivedPSums;
    endmethod
  endinterface

  method ActionValue#(MS_ScatterSetupSignal) getSetupSignal;
    let controlSignal <- globalBufferNIC.getSetupSignal;
    return controlSignal;
  endmethod

  method Bool isFinished;
    `ifdef WS
      return ws_globalBuffer.isFinished;
    `elsif RS
      return rs_globalBuffer.isFinished;
    `endif
  endmethod

endmodule
