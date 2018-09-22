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

/* Neural network Types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;




typedef enum {Idle, WeightSend, IfMapSend, PSumGather} GlobalBufferState deriving(Bits, Eq);

typedef enum {Broadcast, Multicast, Gather, Point2Point} GlobalBufferMessageType deriving(Bits, Eq);

typedef NeuralNetworkFlitType GlobalBufferDataType;

typedef struct {
  GlobalBufferMessageType msgType;
  GlobalBufferDataType    dataType;
  DestBits dests;
  Pixel                   pixelData;
} GlobalBufferMsg deriving(Bits, Eq); 

interface GlobalBufferPort;
  method Action enqMsg(GlobalBufferMsg msg);
  method ActionValue#(GlobalBufferMsg) deqMsg;
endinterface

interface GlobalBuffer;
  method Bool isFinished;
  interface GlobalBufferPort bufferPort;
endinterface

interface GlobalBufferNIC;
  interface Vector#(NumBuffer2NetworkPorts, NetworkExternalInterface) ntkPorts;
  interface GlobalBufferPort bufferPort;
   method ActionValue#(MS_ScatterSetupSignal) getSetupSignal;
endinterface

interface GlobalBufferStat;
  method Data getNumWeights;
  method Data getNumIfMaps;
  method Data getNumPSums;
endinterface

interface GlobalBufferUnit;
  method Bool isFinished;
  interface GlobalBufferStat stats;
  interface Vector#(NumBuffer2NetworkPorts, NetworkExternalInterface) ntkPorts;
   method ActionValue#(MS_ScatterSetupSignal) getSetupSignal;
endinterface

