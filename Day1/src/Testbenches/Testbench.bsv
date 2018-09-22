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

import PriorityArbiter::*;
import RWire::*;

(*synthesize*)
module mkTestbench();

  Reg#(Bit#(16)) cycles <- mkReg(0);
  RWire#(Bit#(3)) winner <- mkRWire;
  PriorityArbiter arbiter <- mkPriorityArbiter;

  rule proceedTest;
    if(cycles == 10) begin
      $finish;
    end
    else begin
	  cycles <= cycles + 1;
    end
  endrule

  rule generateInputs;
    $display("\nCycle %d ----------------------------------------------------", cycles);
    if(cycles == 0) begin
      arbiter.arbitReqPorts[1].reqArbit;
      arbiter.arbitReqPorts[2].reqArbit;
      arbiter.arbitReqPorts[3].reqArbit;
	  $display("Requests from 1, 2, 3");
	  winner.wset(1);
    end
    else if (cycles == 1) begin
      arbiter.arbitReqPorts[2].reqArbit;
      arbiter.arbitReqPorts[3].reqArbit;	
      $display("Requests from 2, 3");
      winner.wset(2);
    end
    else if (cycles == 2) begin
      arbiter.arbitReqPorts[0].reqArbit;
      arbiter.arbitReqPorts[3].reqArbit;		
      $display("Requests from 0, 3");
      winner.wset(0);
    end
    else if (cycles == 3) begin
      arbiter.arbitReqPorts[3].reqArbit;		
      $display("Requests from 3");
      winner.wset(3);
    end
    else if (cycles == 4) begin
      arbiter.arbitReqPorts[2].reqArbit;
      arbiter.arbitReqPorts[3].reqArbit;		
      $display("Requests from 2, 3");
      winner.wset(2);
    end
    else if (cycles == 5) begin
      arbiter.arbitReqPorts[0].reqArbit;
      arbiter.arbitReqPorts[1].reqArbit;
      arbiter.arbitReqPorts[2].reqArbit;
      arbiter.arbitReqPorts[3].reqArbit;
      $display("Requests from 0, 1, 2, 3");
      winner.wset(0);
    end
    else if (cycles == 8) begin
      arbiter.arbitReqPorts[1].reqArbit;
      arbiter.arbitReqPorts[3].reqArbit;
      $display("Requests from 1, 3");
      winner.wset(1);
    end
    else begin
      $display("No requests");
    end

  endrule


  rule readWinners;
    for(Integer prt = 0; prt < valueOf(NumRequesters); prt = prt+1) begin
      let resp = arbiter.arbitRespPorts[prt].respArbit;
      if(resp == 1) begin
        $display("Requester %d won the arbitration", prt);
        if(isValid(winner.wget)) begin
          if(fromInteger(prt) == validValue(winner.wget)) begin
            $display("** Correct Output **");
          end
          else begin
            $display("** Warning! Incorrect Output **");
          end
        end
      end
    end
  endrule


endmodule
