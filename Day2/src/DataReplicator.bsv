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

typedef Bit#(16) RepData;
typedef Bit#(16) RepIdx;

interface DataReplicator;
  method Action putData(RepData value, RepIdx numRepeats);
  method ActionValue#(RepData) getData;
endinterface


(* synthesize *)
module mkDataReplicator(DataReplicator);
  Fifo#(1, RepData) inputFifo <- mkPipelineFifo;
  Fifo#(1, RepData) outputFifo <- mkBypassFifo;

  Reg#(RepIdx) repCounts <- mkReg(0);


  rule sendRepData(repCounts != 0);
    //TODO:
    // 1) store the value stored in inputFifo to output Fifo
    // 2) decrement repCounts
    // 3) if you finished repeats, deque inputFifo. (inputFifo.deq)
  endrule

  method Action putData(RepData value, RepIdx numRepeats) if(repCounts == 0);
    //TODO:
    // 1) store value to inputFifo using enq method
    // 2) store numRepeats to register repCounts
  endmethod

  method ActionValue#(RepData) getData;
    //TODO:
    // 1) dequeue outputFifo
    // 2) return outputFifo's first element
    outputFifo.deq;
    return outputFifo.first;
  endmethod

endmodule
