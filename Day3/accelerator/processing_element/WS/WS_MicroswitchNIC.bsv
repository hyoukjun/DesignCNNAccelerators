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

/* NoC types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neural network types */
import NeuralNetworkTypes::*;
import NeuralNetworkConfig::*;
import GlobalBufferTypes::*;
import WeightStationaryPE_Types::*;

/* Neural network modules */
import WS_PE::*;

/*****************************************************************************
  A network interface for weight-statinary processing elements and a mesh NoC
  - Receives PE messages and generates corresponding mesh flits
  - Need to calculate the route information(numXhops, numYhops)
******************************************************************************/

(* synthesize *)
module mkWS_MicroswitchNIC(ProcessingElementNIC);
  Reg#(Bool)  inited <- mkReg(False);

  Reg#(RowID) rID    <- mkRegU;
  Reg#(ColID) cID    <- mkRegU;
  Reg#(Data)  peID   <- mkRegU;

  Fifo#(1, Pixel) weightInFifo <- mkBypassFifo;
  Fifo#(1, Pixel) ifMapInFifo  <- mkBypassFifo;

  Fifo#(1, Pixel) pSumInFifo   <- mkBypassFifo;
  Fifo#(1, Flit)  flitOutFifo  <- mkBypassFifo;

  rule rl_getPSum(inited);
    let pSum = pSumInFifo.first;
    pSumInFifo.deq;

    MS_DestBits dest = 0;
    dest[valueOf(NumPEs)] = 1;
    
    flitOutFifo.enq(
        Flit{
          msgType: PSum,
          dests: dest,
          localDest:?,
          flitData: pSum
         }
    );
  endrule

  method Action initialize(RowID init_rID, ColID init_cID);
    inited <= True;
    rID <= init_rID;
    cID <= init_cID;
    peID <= zeroExtend(init_rID) * fromInteger(valueOf(NumPEColumns)) + zeroExtend(init_cID);
  endmethod

  method ActionValue#(Pixel) getWeight;
    weightInFifo.deq;
    return weightInFifo.first;
  endmethod

  method ActionValue#(Pixel) getIfMap;
    ifMapInFifo.deq;
    return ifMapInFifo.first;
  endmethod

  method Action putPSum(Pixel pSum);
    pSumInFifo.enq(pSum);
  endmethod

  method Action enqFlit(Flit flit);

    if(flit.dests[peID] == 1) begin
      case(flit.msgType)
        Weight: begin 
          weightInFifo.enq(flit.flitData);
         `ifdef DEBUG_WS_MSNIC
           $display("[WS_MSNIC]Received a Weight in (%d, %d)", rID, cID);
         `endif
        end
        IfMap: begin
          ifMapInFifo.enq(flit.flitData);
          `ifdef DEBUG_WS_MSNIC
            $display("[WS_MSNIC]Received an IfMap in (%d, %d)", rID, cID);
          `endif
        end
        default: begin 
         `ifdef DEBUG_WS_MSNIC
           $display("[WS_MSNIC]Received an unknown flit in (%d, %d)", rID, cID);
         `endif
        end 
      endcase
    end
    `ifdef DEBUG_WS_MSNIC
    else begin
      $display("[WS_MSNIC]Received an invalid flit in (%d, %d)", rID, cID);
      $display("Flit dest: %b, peID: %d", flit.dests, peID);
      for(Integer i=0; i<valueOf(NumPEs)+1; i=i+1) begin
        $display("destBit[%d] = %b", i, flit.dests[i]);
      end
    end
    `endif

  endmethod

  method ActionValue#(Flit) deqFlit if(flitOutFifo.notEmpty);
    let outFlit = flitOutFifo.first;
    flitOutFifo.deq;
    return outFlit;
  endmethod

endmodule
