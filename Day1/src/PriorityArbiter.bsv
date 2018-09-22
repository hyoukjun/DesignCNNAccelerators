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

import Vector::*;
import RWire::*;

typedef 4 NumRequesters;
typedef Bit#(TAdd#(1, TLog#(NumRequesters))) RequesterIdx;

interface ArbitReq;
  method Action reqArbit;
endinterface

interface ArbitResp;
  method Bit#(1) respArbit;
endinterface

interface PriorityArbiter;
  interface Vector#(NumRequesters, ArbitReq) arbitReqPorts;
  interface Vector#(NumRequesters, ArbitResp) arbitRespPorts;		
endinterface


(* synthesize *)
module mkPriorityArbiter(PriorityArbiter);

  Vector#(NumRequesters, RWire#(Bit#(1))) reqs <-replicateM(mkRWire); 
  Vector#(NumRequesters, RWire#(Bit#(1))) resps <- replicateM(mkRWire); 


  rule doArbitration;
    Vector#(NumRequesters, Bit#(1)) requests = newVector;
    Bool existsWinner = False;
    RequesterIdx winnerIdx = ?;

    for(Integer prt = 0; prt < valueOf(NumRequesters) ; prt = prt +1) begin
      requests[prt] = isValid(reqs[prt].wget)? 1: 0;
    end

    /****************************************** TODO **********************************************/
    // At this point, you have requester information in the vector requests.
    //   if(reqests[0] == 1), requester 0 requested a hardware resource managed 
    //   by this arbiter
    //  
    // 1) Based on the priority (requester 0 < requester 1 < requester 2 < requester 3), 
    //    implement a logic that determines a winner (investigate reqs[0] ~ reqs[3] and
    //    use that information. (hint: apply if-else if statements)
    //
    // 2) If no one requested the resource, mark "existsWinner" as False. 
    //    If the logic finds a winner, makr existsWinner as True.
    //
    // 3) Store winner index in "winnerIdx." e.g., if requester 1 won the resource, "winnerIdx = 1;"

    // Implement here
    

    /***********************************************************************************************/

    if(existsWinner) begin
      resps[winnerIdx].wset(1);
    end

  endrule

  Vector#(NumRequesters, ArbitReq) arbitReqPortsTmp;
  Vector#(NumRequesters, ArbitResp) arbitRespPortsTmp;

  for(Integer prt = 0; prt < valueOf(NumRequesters); prt = prt + 1) begin
    arbitReqPortsTmp[prt] = 
      interface ArbitReq
        method Action reqArbit;
          reqs[prt].wset(1);
        endmethod
      endinterface;

    arbitRespPortsTmp[prt] = 
      interface ArbitResp
        method Bit#(1) respArbit;
          if(!isValid(resps[prt].wget)) begin
            return 0;
          end
          else begin
            let ret = validValue(resps[prt].wget);
            return ret;
          end
        endmethod
      endinterface;
  end

  interface arbitReqPorts = arbitReqPortsTmp;
  interface arbitRespPorts = arbitRespPortsTmp;

endmodule
