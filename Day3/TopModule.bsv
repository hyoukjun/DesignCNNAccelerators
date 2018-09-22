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

/* Primitive Types */
import Fifo::*;
import Vector::*;
import Connectable::*;

/* NoC Types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

/* Neuralnetwork Types */
import NeuralNetworkConfig::*;
import DerivedNeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
`ifdef WS
import WeightStationaryPE_Types::*;
`elsif RS
import RowStationaryPE_Types::*;
`endif
import GlobalBufferTypes::*;

/* Neuralnetwork Modules */
import GlobalBufferUnit::*;
`ifdef WS
import WS_PE_Array::*;
`elsif RS
import RS_PE_Array::*;
`endif

/* NoC modules */
import MicroswitchNetwork::*;

(* synthesize *)
module mkTopModule();
  Reg#(Data) cycleCount <- mkReg(0);

  ProcessingElementArray peArray      <- mkPE_Array;
  GlobalBufferUnit       globalBuffer <- mkGlobalBufferUnit;
  MicroswitchNetwork     network      <- mkMicroswitchNetwork;

  rule doCount;
    cycleCount <= cycleCount + 1;
  endrule

  rule checkFinish;
    if(globalBuffer.isFinished) begin
      $display("Elapsed cycle time: %d", cycleCount);
      $display("Num injected Weights: %d", globalBuffer.stats.getNumWeights);
      $display("Num injected IfMaps: %d", globalBuffer.stats.getNumIfMaps);
      $display("Num received PSums: %d", globalBuffer.stats.getNumPSums);

      $finish;
    end
    else if(cycleCount % 10000 == 0) begin
      if(cycleCount == 0) begin
        $display("Basic parameters");
        $display("PE dimension: %d x %d", valueOf(NumPERows), valueOf(NumPEColumns));
        $display("PE Delay: %d", valueOf(PEDelay));
        $display("NumChannels: %d, numFilters: %d, numIfMaps: %d",valueOf(NumChannels), valueOf(NumFilters), valueOf(NumIfMaps));
        $display("FilterSz: %d, IfMapSz: %d, Stride: %d", valueOf(FilterSz), valueOf(IfMapSz), valueOf(Stride));
          
        $display("");
        $display("Filter dimensions");
        $display("NumPixelsPerFilterPlane (RxR): %d", valueOf(NumPixelsPerFilterPlane));
        $display("NumPixelsPerFilter: %d", valueOf(NumPixelsPerFilter));
        $display("NumFilterWeights: %d", valueOf(NumFilterWeights));  
        $display("");
        $display("IfMap dimensions");
        $display("NumPixelsPerIfMap: %d", valueOf(NumPixelsPerIfMap));
        $display("NumIfMapPixels: %d", valueOf(NumIfMapPixels));
        $display("");
        $display("OfMap dimensions");
        $display("OfMapSz: %d", valueOf(OfMapSz));
        $display("NumOfMapPixels: %d", valueOf(NumOfMapPixels));
        $display("NumPSumsRS: %d", valueOf(NumPSumsRS));
        $display("OfMapSz: %d", valueOf(OfMapSz));

        $display("NumIfMaps: %d", valueOf(NumIfMapPixels));
        $display("NumFilter: %d", valueOf(NumFilterWeights));

      end
      $display("Elapsed cycle time: %d", cycleCount);
      $display("Num injected Weights: %d", globalBuffer.stats.getNumWeights);
      $display("Num injected IfMaps: %d", globalBuffer.stats.getNumIfMaps);
      $display("Num received PSums: %d", globalBuffer.stats.getNumPSums);
    end
  endrule


  //PE-network connections
  /***************************************************************************/
  //TODO: Interconnect PE array and network
  //        Implement inter-module connection using mkConnection statement
  //          1. NoC -> PE connection
  //          Interconnect (1) peArray.pePorts[rowID][columnID].putFlit
  //          and (2) network.peDataPorts[rowID * valueOf(NumPEColumns) + columnID].getFlit 
  //
  //          2. PE -> NoC connection
  //          Interconnect (1) peArray.pePorts[rowID][columnID].getFlit
  //          and (2) network.peDataPorts[rowID * valueOf(NumPEColumns) + columnID].putFlit 
  //
  //          * Hints: you will need to use a nested for-loop; replafce "rowID" and "columnID"
  //                   with your for-loop iteration value


  //Implement here




  /***************************************************************************/

  //Global buffer - network connection
  mkConnection(globalBuffer.ntkPorts[0].putFlit, network.hostDataPort.getFlit);
  mkConnection(globalBuffer.ntkPorts[0].getFlit, network.hostDataPort.putFlit);

  mkConnection(globalBuffer.getSetupSignal, network.controlPort.setSwitches);

endmodule
