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
import CReg::*;
import Vector::*;

/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import DerivedNeuralNetworkConfig::*;
import WeightStationaryPE_Types::*;

/* Submodules */
import FixedTypes::*;
import FixedMultiplier::*;

/*****************************************************************************
  A weight-statinary processing element
******************************************************************************/

(* synthesize *)
module mkWS_ProcessingElement(ProcessingElement);

  /* Input Queues */
  Fifo#(WeightFifoDepth, Pixel)  weightFifo <- mkPipelineFifo;
  Fifo#(IfMapFifoDepth, Pixel)   ifMapFifo <- mkPipelineFifo;

  /* Output Queues */
  Fifo#(PSumFifoDepth, Pixel)    pSumFifo   <- mkBypassFifo;

  CReg#(2, NumPixelsBit) ifMapCount <- mkCReg(0);

  //TODO Instantiate a fixed mutiplier

  rule requestMult(weightFifo.notEmpty && ifMapFifo.notEmpty);
    // Do not touch the following statement
    ifMapCount[0] <= ifMapCount[0] + 1;
	
    /**************************************************************************/
    //TODO: using putArgA and putArgB methods of your fixed point multiplier, 
    //     put weightFifo.first and ifMapFifo.first to request multiplicaiton
    //      * Note that both Pixel and FixedPoint are Bit#(16), which means 
    //        you can regard type Pixel and FixedPoint are the same type
	//      * You need to dequeue ifMapFifo to keep weight and iterate over ifMaps

	// Implement here

    /**************************************************************************/
  endrule


  rule calculatePSum;
    /**************************************************************************/
    //TODO: replace the following multipication using your fixed point multiplier
    //      (use getRes method)
    //      * To receive a return value of an ActionValue, you need to use "<-"
    //         ex) let ret <- multiplier.getRes;

    // Implement here
		let pixel = ?;
    let res = zeroExtend(weightFifo.first) * pixel; //Dummy Multiplication

    /**************************************************************************/

    pSumFifo.enq(res); //Store result to the output Fifo results

	// Dataflow control; if 
     if(ifMapCount[1] >= fromInteger(valueOf(NumIfMapPixels)) ) begin
       `ifdef DEBUG_WS_PE_WEIGHT
         $display("[WS_PE]Deque a weight");
       `endif
        ifMapCount[1] <= 0;
        weightFifo.deq;
      end
  endrule

  method Action enqWeight(Pixel weight);
    `ifdef DEBUG_WS_PE_WEIGHT
      $display("[WS_PE]Received a Weight");
    `endif
    weightFifo.enq(weight);
  endmethod

  method Action enqIfMap(Pixel ifPixel);
    `ifdef DEBUG_WS_PE
      $display("[WS_PE]Received an IfMap");
    `endif
    ifMapFifo.enq(ifPixel);
  endmethod

  method ActionValue#(Pixel) deqPSum;
    `ifdef DEBUG_WS_PE
      $display("[WS_PE]Sending a PSum");
    `endif
    pSumFifo.deq;
    return pSumFifo.first;
  endmethod

  method Action enqPSum(Pixel pSum);
    `ifdef DEBUG_WS_PE
      $display("[WS_PE]Received an IfMap");
    `endif
    noAction;
  endmethod

endmodule
