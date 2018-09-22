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
import FixedMultiplier::*;


(* synthesize *)
module mkTestbench();

  Reg#(Bit#(32)) cycleReg <- mkReg(0);

  FixedALU multiplier <- mkFixedMultiplier;

  Fifo#(5, FixedPoint) correctAnswers <- mkPipelineFifo;
  
  rule proceedTest;
    if(cycleReg < 10) begin
      cycleReg <= cycleReg + 1;
    end
    else begin
      $finish;
    end

  endrule

  rule genTestPattern;
    if(cycleReg == 0) begin
	  $display("request 1.5 x (-0.1234)");
      multiplier.putArgA(16'b0001100000000000);      //1.5
      multiplier.putArgB(16'b1111111000000110);      //-0.1234
      correctAnswers.enq(16'b1111110100001001); //-0.1851
    end
    else if (cycleReg == 1) begin
	  $display("request 1.732 x 0.512");
      multiplier.putArgA(16'b0001101110110110);      //1.732
      multiplier.putArgB(16'b0000100000110001);      //0.512
      correctAnswers.enq(16'b0000111000101111); //0.886784
    end
    else if (cycleReg == 2) begin
	  $display("request (-0.0312) x (-1.329)");
      multiplier.putArgA(16'b1111111110000000);      //-0.0312
      multiplier.putArgB(16'b1110101010111100);      //-1.329
      correctAnswers.enq(16'b0000000010101010); //0.0414648
    end
    else if (cycleReg == 3) begin
	  $display("request (-1.215523) x 2.6321");
      multiplier.putArgA(16'b1110110010001101);      //-1.215523
      multiplier.putArgB(16'b0010101000011101);      //2.6321
      correctAnswers.enq(16'b1100110011001110); //-3.199378088
    end
    else if (cycleReg == 4) begin
	  $display("request (-0.25) x 0.875");
      multiplier.putArgA(16'b1111110000000000);      //-0.25
      multiplier.putArgB(16'b0000111000000000);      //0.875
      correctAnswers.enq(16'b1111110010000000); //-0.21875
    end

  endrule

  rule checkResults;
    let res <- multiplier.getRes;
    let answer = correctAnswers.first;
    correctAnswers.deq;

	$display("Cycle %d", cycleReg);

    if(res == answer) begin
      $display("Correct Answer");
    end
    else begin
      $display("Warning! wrong answer! Result: %b, Answer: %b",res, answer);
    end
  endrule


endmodule
