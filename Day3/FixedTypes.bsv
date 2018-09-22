
typedef 16 FixedPointSz;
typedef Bit#(FixedPointSz) FixedPoint;

interface FixedALU;
  method Action putArgA(FixedPoint newArg);
  method Action putArgB(FixedPoint newArg);
  method ActionValue#(FixedPoint) getRes;
endinterface

