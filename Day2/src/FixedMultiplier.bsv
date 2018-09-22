/*
Copyright (c) 2017
	Hyoukjun Kwon (hyoukjun@gatech.edu)

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
*/



import Fifo::*;
import FixedTypes::*;

(* synthesize *)
module mkFixedMultiplier(FixedALU);
  //TODO
  // 1) instantiate two input FIFOs for two operands
  // 2) instantiate an output FIFO for the results

  rule doMultiplication;
    noAction();
    //TODO:
    // 1) Implement fixed point multiplication using two operands stored in your input FIFOs 
    //    (use pipelineFifo ; e.g., Fifo#(1, FixedPoint) exFifo <- mkPipelineFifo)
    // 2) Store the addition results to your output FIFO
    //    (use bypassFifo ; e.g., Fifo#(1, FixedPoint) exFifo <- mkBypassFifo)
    // * Please note that our FixedPoint is Bit#(16)
  endrule

  method Action putArgA(FixedPoint newArg);
    noAction();
    //TODO: store newArg to one of your input FIFO
  endmethod

  method Action putArgB(FixedPoint newArg);
    noAction();
    //TODO: store newArg to one of your input FIFO
  endmethod

  method ActionValue#(FixedPoint) getRes;
    //TODO: dequeue your output FIFO and return the first value of your output FIFO
    return ?;
  endmethod

endmodule
