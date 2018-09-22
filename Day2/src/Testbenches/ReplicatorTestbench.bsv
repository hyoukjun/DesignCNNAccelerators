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
import DataReplicator::*;


(* synthesize *)
module mkTestbench();

  Reg#(Bit#(32)) cycleReg <- mkReg(0);

  DataReplicator replicator <- mkDataReplicator;
  
  rule proceedTest;
    if(cycleReg < 50) begin
      cycleReg <= cycleReg + 1;
    end
    else begin
      $finish;
    end

  endrule

  rule genTestPattern;
    if(cycleReg == 0) begin
	  $display("@Cycle %d, Request to repeat 15 three times", cycleReg);
      replicator.putData(15, 3);
    end
    else if (cycleReg == 10) begin
	  $display("@Cycle %d, Request to repeat 21 five times", cycleReg);
      replicator.putData(21, 5);
    end
    else if (cycleReg == 20) begin
	  $display("@Cycle %d, Request to repeat 17 ten times", cycleReg);
      replicator.putData(17, 10);
    end
  endrule

  rule checkResults;
    let outData <- replicator.getData;

	$display("\n@Cycle %d, received %d", cycleReg, outData);

  endrule


endmodule
