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

/* NoC types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import WeightStationaryPE_Types::*;

/* Neural network modules */
import WS_PE_Unit::*;
import WS_MicroswitchNIC::*;

(* synthesize *)
module mkPE_Array(ProcessingElementArray);
  Reg#(Bool) inited <- mkReg(False);
  /**************************************************************************/
  //TODO: Initialize a PE array using name "peArray". The size of peArray (number of PEs in the array) is NumPERows x NumPEColumns
  // To instantiate a PE, sytax is as the following: ProcessingElementUnit singlePE <- mkWS_ProcessingElementUnit;
  // * You will need to use a nested Vector. 

  // Implement here

 
  /**************************************************************************/

  rule doInitialize(!inited);
    $display("[WS_PE_Array]Initialize");
    inited <= True;
    for(Integer i = 0; i<valueOf(NumPERows); i=i+1) begin
      for(Integer j=0; j<valueOf(NumPEColumns); j=j+1) begin
        peArray[i][j].initialize(fromInteger(i), fromInteger(j));
      end
    end
  endrule

  Vector#(NumPERows, Vector#(NumPEColumns, NetworkExternalInterface)) dummy_PE_Array_Ports = newVector;
  for(Integer i = 0; i<valueOf(NumPERows); i=i+1) begin
    for(Integer j=0; j<valueOf(NumPEColumns); j=j+1) begin
      dummy_PE_Array_Ports[i][j] =
        interface NetworkExternalInterface

          method Action putFlit(Flit flit) if(inited);
            peArray[i][j].ntkPort.putFlit(flit);
          endmethod

          method ActionValue#(Flit) getFlit if(inited);
            let flit <- peArray[i][j].ntkPort.getFlit;
            return flit;
          endmethod
        endinterface;
    end
  end
  interface pePorts = dummy_PE_Array_Ports;
endmodule
