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
import Fifo::*;
import Connectable::*;

/* NoC types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import WeightStationaryPE_Types::*;

/* Neural network modules */
import WS_PE::*;
import WS_MicroswitchNIC::*;

/*************************************************************
  Weight-statinary processing element unit for mesh network
  - Contains a PE and the network interface module of the PE
  - Manages credit management and VC allocation
**************************************************************/

(* synthesize *)
module mkWS_ProcessingElementUnit(ProcessingElementUnit);

  ProcessingElement     pe          <- mkWS_ProcessingElement;
  ProcessingElementNIC  peMSNIC   <- mkWS_MicroswitchNIC;

  mkConnection(peMSNIC.getWeight, pe.enqWeight);
  mkConnection(peMSNIC.getIfMap, pe.enqIfMap);
  mkConnection(peMSNIC.putPSum, pe.deqPSum);

  interface NetworkExternalInterface ntkPort;
      method Action putFlit(Flit flit);
       `ifdef DEBUG_WS_PE_UNIT
         $display("[WS_PE_Unit]Received a flit");
       `endif
        peMSNIC.enqFlit(flit);
      endmethod
 
      method ActionValue#(Flit) getFlit;
       `ifdef DEBUG_WS_PE_UNIT
         $display("[WS_PE_Unit]Sending a flit");
       `endif
        let flit <- peMSNIC.deqFlit;
        return flit;
      endmethod

  endinterface

  method Action initialize(RowID rID, ColID cID);
    peMSNIC.initialize(rID, cID);
  endmethod

endmodule

