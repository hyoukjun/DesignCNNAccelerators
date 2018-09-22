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

/* Filter Dimensions */
typedef TMul#(FilterSz, FilterSz)                   NumPixelsPerFilterPlane;
typedef TMul#(NumChannels, NumPixelsPerFilterPlane) NumPixelsPerFilter;
typedef TMul#(NumFilters, NumPixelsPerFilter)       NumFilterWeights;

/* Ifmap Dimensions */
typedef TMul#(NumChannels, TMul#(IfMapSz, IfMapSz)) NumPixelsPerIfMap;
typedef TMul#(NumIfMaps, NumPixelsPerIfMap)         NumIfMapPixels;

/* Ofmap Dimensions */
typedef TDiv#(TSub#(IfMapSz, TSub#(FilterSz, Stride)), Stride)  OfMapSz;
typedef TMul#(OfMapSz, OfMapSz)                                 NumPixelsPerOfMapPlane;
typedef TMul#(NumPixelsPerOfMapPlane, NumFilters)               NumPixelsPerOfMap;
typedef TMul#(NumIfMaps, NumPixelsPerOfMap)                     NumOfMapPixels;

//For RS
//typedef TDiv#(NumOfMapPixels, NumPERows) NumPSumsRS; //Assumption: NumPERows == FilterSz
typedef TMul#(NumOfMapPixels, FilterSz) NumPSumsRS;
typedef TDiv#(OfMapSz, NumPEColumns) NumNormalColumnIteration;

/* Effective IfMap Dimensions */

typedef TMul#(NumPixelsPerFilterPlane, NumPixelsPerOfMapPlane) NumEffectiveIfMapPixelsPlane;

typedef TMul#(NumIfMaps, 
            TMul#(NumPixelsPerFilterPlane, 
                  NumPixelsPerOfMapPlane)) 
NumEffectiveIfMapPixelsPerChannel;


typedef TMul#(NumChannels, NumEffectiveIfMapPixelsPerChannel) NumEffectiveIfMapPixels;

