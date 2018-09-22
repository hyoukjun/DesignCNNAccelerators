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
import Vector::*;
import Fifo::*;

/* NoC types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neural network types */
import NeuralNetworkTypes::*;
import NeuralNetworkConfig::*;

interface MicroswitchController;
  method MS_ScatterSetupSignal getScatterControlSignal(MS_DestBits destBits);
endinterface

(* synthesize *)
module mkMicroswitchController(MicroswitchController);
  let targ_branchNodes = valueOf(MS_NumLowestBranchNodes); // First targets: NumPEs/2 branch nodes in the lowest level.
  let targ_width = 2;

  function MS_ScatterSetupSignal calculateScatterControlSignal(MS_DestBits destBits);

    Vector#(MS_NumMicroswitchLevels, Integer) baseIdx = newVector;

    baseIdx[0] = valueOf(MS_NumBranchNodes) - 1;// - valueOf(MS_NumLowestBranchNodes);
    for(Integer idx = 1; idx < valueOf(MS_NumMicroswitchLevels); idx = idx+1) begin
      baseIdx[idx] = baseIdx[idx-1] - 2**(valueOf(MS_NumMicroswitchLevels)-idx);
    end

    MS_ScatterSetupSignal results = newVector;

    //First level
    for(Integer j=0; j<valueOf(MS_NumLowestBranchNodes); j=j+1) begin
      Bit#(1) rightBit = destBits[2*j];
      Bit#(1) leftBit = destBits[2*j+1];
      results[baseIdx[0]-j] = {rightBit, leftBit};
    end

    for(Integer i=1; i<valueOf(MS_NumMicroswitchLevels); i=i+1) begin
      for(Integer j=0; j< 2**(valueOf(MS_NumMicroswitchLevels)-1-i); j=j+1) begin
        Bit#(1) rightBit = (results[baseIdx[i-1]-2*j] != 0)? 1:0;
        Bit#(1) leftBit = (results[baseIdx[i-1]-2*j-1] != 0)? 1:0; 
        results[baseIdx[i]-j] = {rightBit,leftBit};
      end
    end
    return results;
  endfunction
  
  method MS_ScatterSetupSignal getScatterControlSignal(MS_DestBits destBits) = calculateScatterControlSignal(destBits);

endmodule
