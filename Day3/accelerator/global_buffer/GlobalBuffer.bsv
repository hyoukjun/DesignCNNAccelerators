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

import Vector::*;
import Fifo::*;
import CReg::*;

/* NoC Types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;


/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import DerivedNeuralNetworkConfig::*;
import GlobalBufferTypes::*;

(* synthesize *)
module mkWS_GlobalBuffer(GlobalBuffer);
  Reg#(Bool) isFinishedReg            <- mkReg(False);
  Reg#(Bool) lastWeight               <- mkReg(False);

  Reg#(Data) numRemainingWeights      <- mkReg(fromInteger(valueOf(NumFilterWeights)));
  Reg#(Data) numSentIfMaps            <- mkReg(0);
  CReg#(2, Data) numReceivedPSums     <- mkCReg(0);

  Reg#(GlobalBufferState) bufferState <- mkReg(WeightSend);

  Fifo#(NumPEs, GlobalBufferMsg) outFifo <- mkBypassFifo;


  rule rl_generateFlits;
    Maybe#(Flit) newFlit = Invalid;

    case(bufferState)
      WeightSend: begin
        MS_DestBits dest = 0;
        dest = ~0;
        let newGlobalBufferMsg = GlobalBufferMsg{
                                   msgType: Multicast, 
                                   dataType: Weight,
                                   dests: dest,
                                   pixelData: ?
                                 };

        if(numRemainingWeights < fromInteger(valueOf(NumPEs))) begin
          lastWeight <= True;
        end
        else begin
          numRemainingWeights <= numRemainingWeights - fromInteger(valueOf(NumPEs));
        end
        `ifdef DEBUG_GLOBALBUFFER
          $display("[GlobalBuffer]Send weight broadcast request, remaining weights: %d", numRemainingWeights);
        `endif
        bufferState <= IfMapSend;
        outFifo.enq(newGlobalBufferMsg);
      end

      IfMapSend: begin
        MS_DestBits dest = 0;
        dest = ~0;
        let newGlobalBufferMsg = GlobalBufferMsg{
                                   msgType: Broadcast, 
                                   dataType: IfMap,
                                   dests: dest,
                                   pixelData: ?
                                 };

        numSentIfMaps <= numSentIfMaps + 1;

        `ifdef DEBUG_GLOBALBUFFER
          $display("[GlobalBuffer]: Send IfMap broadcast request");
        `endif
        bufferState <= PSumGather;
        outFifo.enq(newGlobalBufferMsg);
      end

      PSumGather: begin
        if(numReceivedPSums[1] >= fromInteger(valueOf(NumPEs))) begin
          numReceivedPSums[1] <= 0;

          `ifdef DEBUG_GLOBALBUFFER
            $display("numSentIfmaps: %d (Max: %d)", numSentIfMaps, valueOf(NumIfMapPixels));
          `endif
          if(numSentIfMaps >= fromInteger(valueOf(NumIfMapPixels))) begin

            `ifdef DEBUG_GLOBALBUFFER
              $display("to weight braodcast");
            `endif
            numSentIfMaps <= 0;
            bufferState <= WeightSend;
          end
          else begin
            `ifdef DEBUG_GLOBALBUFFER
              $display("to input feature map broadcast");
            `endif
            bufferState <= IfMapSend;
          end

          if(lastWeight) begin
            isFinishedReg <= True;
          end
        end
      end
    endcase

  endrule

  interface GlobalBufferPort bufferPort;
    method Action enqMsg(GlobalBufferMsg msg);
      `ifdef DEBUG_GLOBALBUFFER
        $display("[GlobalBuffer]: Received a PSUM");
      `endif
      numReceivedPSums[0] <= numReceivedPSums[0] + 1;
    endmethod

    method ActionValue#(GlobalBufferMsg) deqMsg;
      `ifdef DEBUG_GLOBALBUFFER
        $display("[GlobalBuffer]: Sending a message");
      `endif
      let flit = outFifo.first;
      outFifo.deq;
      return flit;
    endmethod
  endinterface

  method Bool isFinished;
    return isFinishedReg;
  endmethod

endmodule



