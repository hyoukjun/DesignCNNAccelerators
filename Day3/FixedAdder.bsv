import Fifo::*;
import FixedTypes::*;

(* synthesize *)
module mkFixedAdder(FixedALU);
  Fifo#(1, FixedPoint) argA <- mkPipelineFifo;
  Fifo#(1, FixedPoint) argB <- mkPipelineFifo;

  Fifo#(1, FixedPoint) res <- mkBypassFifo;

  rule doAddition;
    let operandA = argA.first;
    let operandB = argB.first;
    argA.deq;
    argB.deq;

    res.enq(argA.first + argB.first);
  endrule

  method Action putArgA(FixedPoint newArg);
    argA.enq(newArg);
  endmethod

  method Action putArgB(FixedPoint newArg);
    argB.enq(newArg);
  endmethod

  method ActionValue#(FixedPoint) getRes;
    res.deq;
    return res.first;
  endmethod

endmodule
