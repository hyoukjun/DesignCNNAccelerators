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

/* Neural network types */
import NeuralNetworkTypes::*;
import NeuralNetworkConfig::*;

/* NoC Types */
import MicroswitchTypes::*;
import MicroswitchMessageTypes::*;
import MicroswitchNetworkTypes::*;

typedef 1 WeightFifoDepth;
typedef 3 IfMapFifoDepth;
typedef 1 PSumFifoDepth;

interface ProcessingElementArray;
  interface Vector#(NumPERows, Vector#(NumPEColumns, NetworkExternalInterface)) pePorts;
endinterface

interface ProcessingElementUnit;
  method Action initialize(RowID rID, ColID cID);
  interface NetworkExternalInterface ntkPort;
endinterface

interface ProcessingElementNIC;
  method Action initialize(RowID rID, ColID cID);
  method ActionValue#(Pixel) getWeight;
  method ActionValue#(Pixel) getIfMap;
  method Action putPSum(Pixel pSum);
  method Action enqFlit(Flit flit);
  method ActionValue#(Flit) deqFlit;
endinterface

interface ProcessingElement;

  method Action enqWeight(Pixel weight);
  method Action enqIfMap(Pixel ifPixel);
  method Action enqPSum(Pixel pSum);

  method ActionValue#(Pixel) deqPSum;
endinterface
