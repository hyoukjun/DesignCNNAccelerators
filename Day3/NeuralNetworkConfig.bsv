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

/***************  User-defined Neural Network Configuration **************/

/* Data type */
typedef 16 PixelBitSz;

/* PE configurations */
//You need to make the number of PEs to be the power of 2 to get microswitch network work
typedef 16 NumPERows;
typedef 8 NumPEColumns;  //For RS, NumPEColumns should be greater or equal than the FilterSz.

typedef 1 PEDelay;

/* CNN configurations */

// Experimental small size
typedef 3  NumChannels;  //C
typedef 8  NumFilters;  //M, Indicates the number of 3D filters
typedef 1  NumIfMaps;    //N
typedef 3  FilterSz;    // 'R' in Eyeriss paper
typedef 100  IfMapSz;    // 'H' in Eyeriss paper
typedef 1  Stride;       //U


//Alexnet Conv1
/*
typedef 3  NumChannels; //C
typedef 96  NumFilters;  //M, Indicates the number of 3D filters
typedef 1  NumIfMaps;   //N
typedef 11  FilterSz;   // 'R' in Eyeriss paper
typedef 227  IfMapSz;    // 'H' in Eyeriss paper
typedef 4  Stride;     //U
*/


//Alexnet Conv2
/*
typedef 48  NumChannels; //C
typedef 256  NumFilters;  //M, Indicates the number of 3D filters
typedef 1  NumIfMaps;   //N
typedef 5  FilterSz;   // 'R' in Eyeriss paper
typedef 31  IfMapSz;    // 'H' in Eyeriss paper
typedef 1  Stride;     //U
*/

//VGGnet Conv 8
/*
typedef 512  NumChannels; //C
typedef 512  NumFilters;  //M, Indicates the number of 3D filters
typedef 1  NumIfMaps;   //N
typedef 3  FilterSz;   // 'R' in Eyeriss paper
typedef 28  IfMapSz;    // 'H' in Eyeriss paper
typedef 1  Stride;     //U
*/
//typedef 10 OFmapWidth;    // 'E' in Eyeriss paper; will be automatically derived
//typedef 10 OFmapHeight;


typedef 1 NumBuffer2NetworkPorts;
typedef 1 NumGlobalBufferPorts;
