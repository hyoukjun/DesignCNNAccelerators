import Fifo::*;
import FixedTypes::*;

(* synthesize *)
module mkFixedMultiplier(FixedALU);
  Fifo#(1, FixedPoint) argA <- mkPipelineFifo;
  Fifo#(1, FixedPoint) argB <- mkPipelineFifo;

  Fifo#(1, FixedPoint) res <- mkBypassFifo;

  rule doMultiplication;
    let operandA = argA.first;
    let operandB = argB.first;
    argA.deq;
    argB.deq;

    Bit#(32) extendedA = signExtend(operandA);
    Bit#(32) extendedB = signExtend(operandB);

    Bit#(32) extendedRes = extendedA * extendedB;

    FixedPoint resValue = {extendedRes[31], extendedRes[26:24], extendedRes[23:12]};

    res.enq(resValue);
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
