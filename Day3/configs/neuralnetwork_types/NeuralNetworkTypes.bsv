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

import NeuralNetworkConfig::*;
import DerivedNeuralNetworkConfig::*;

/********** Derived parameters ************/

/* Pixel */
typedef Bit#(PixelBitSz) Pixel;

/* PE Dimensions */
typedef TAdd#(1, TLog#(NumPERows))    RowIDBitSz;
typedef TAdd#(1, TLog#(NumPEColumns)) ColIDBitSz;

typedef Bit#(RowIDBitSz) RowID;
typedef Bit#(ColIDBitSz) ColID;

typedef TMul#(NumPERows, NumPEColumns) NumPEs;

typedef TAdd#(TLog#(NumPEs), 1) NumPEsBitSz;
typedef Bit#(NumPEsBitSz) NumPEsBit;

typedef Bit#(TAdd#(NumPEs, 1)) DestBits;

/* Foldings */
typedef TDiv#(IfMapSz, NumPEs) RowFoldings;
typedef TDiv#(IfMapSz, NumPEs) ColumnFoldings;

/* IF dimensions */
typedef TAdd#( TLog#(NumIfMapPixels), 1) NumPixelsBitSz;
typedef Bit#(NumPixelsBitSz) NumPixelsBit;

typedef TAdd#(TLog#(FilterSz), 1) WeightBitSize;
typedef Bit#(WeightBitSize) Weight;

typedef Bit#(TAdd#(TLog#(PEDelay), 1)) PEDelayBit;

typedef enum {Idle, LoadWeight, Calculate} WS_Status deriving(Bits, Eq);

typedef enum {Weight, IfMap, PSum, OfMap, RecurrWeight} NeuralNetworkFlitType deriving(Bits, Eq);

