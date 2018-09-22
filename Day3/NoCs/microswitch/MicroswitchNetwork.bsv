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
import Connectable::*;

/* Microswitch types */
import MicroswitchTypes::*;
import MicroswitchNetworkTypes::*;
import MicroswitchMessageTypes::*;

/* Neural network types */
import NeuralNetworkConfig::*;
import NeuralNetworkTypes::*;
import GlobalBufferTypes::*;

/* Microswitch modules */
import TopSwitch::*;
import MiddleSwitch::*;
import BottomSwitch::*;

interface MicroswitchNetworkDataPort;
  method Action putFlit(Flit flit);
  method ActionValue#(Flit) getFlit;
endinterface

interface MicroswitchNetworkControlPort;
  method Action setSwitches(MS_ScatterSetupSignal setupSignal);
endinterface

interface MicroswitchNetwork;
  interface MicroswitchNetworkDataPort hostDataPort;
  interface Vector#(NumPEs, MicroswitchNetworkDataPort) peDataPorts;
  interface MicroswitchNetworkControlPort controlPort; 
endinterface

(* synthesize *)
module mkMicroswitchNetwork(MicroswitchNetwork);
  Reg#(Bool) inited <- mkReg(False);
  /* Microswitch array */
  Vector#(NumPEs, TopSwitch) topSwitches <- replicateM(mkTopSwitch);
  Vector#(MS_NumMiddleSwitchLevels, Vector#(NumPEs, MiddleSwitch)) middleSwitches <- replicateM(replicateM(mkMiddleSwitch));
  Vector#(NumPEs, BottomSwitch) bottomSwitches <- replicateM(mkBottomSwitch);
  Vector#(NumPEs, Fifo#(1, Flit)) bottomSwitchDummies <- replicateM(mkBypassFifo);

  Fifo#(1, Flit) gatherOutFifo <- mkBypassFifo;

  rule doInitialize(!inited);
    for(Integer id = 0; id<valueOf(NumPEs); id=id+1) begin
      bottomSwitches[id].initialize(fromInteger(id));
    end
    inited <= True;
  endrule


  /* Gather line connection */
  //Top-middle switches and middle-bottom switches connection
  for(Integer swID = 0; swID < valueOf(NumPEs); swID=swID+1)
  begin
    mkConnection(topSwitches[swID].gatherInPort[0].putFlit,
                   middleSwitches[0][swID].gatherOutPort.getFlit);

    mkConnection(middleSwitches[valueOf(MS_NumMiddleSwitchLevels)-1][swID].gatherInPort.putFlit,
                   bottomSwitches[swID].gatherOutPort.getFlit);
  end

  //Inter middleswitches 
  for(Integer level = 0; level < valueOf(MS_NumMiddleSwitchLevels)-1; level = level+1)
  begin
    for(Integer swID =0; swID < valueOf(NumPEs); swID=swID+1)
    begin
      mkConnection(middleSwitches[level][swID].gatherInPort.putFlit,
                     middleSwitches[level+1][swID].gatherOutPort.getFlit);
    end
  end

  //Inter top switches
  for(Integer swID = 0; swID < valueOf(NumPEs); swID=swID+1)
  begin
    if(swID < valueOf(MS_RootTopSwitchID)) begin
      mkConnection(topSwitches[swID+1].gatherInPort[1].putFlit,
                    topSwitches[swID].gatherOutPort.getFlit);
    end
    else if(swID == valueOf(MS_RootTopSwitchID)) begin
      rule rl_getGatherFlit;
        let gatherFlit <- topSwitches[swID].gatherOutPort.getFlit;
        gatherOutFifo.enq(gatherFlit);
      endrule
    end
    else begin
      mkConnection(topSwitches[swID-1].gatherInPort[2].putFlit,
                     topSwitches[swID].gatherOutPort.getFlit);
    end
  end

  /* Scatter links */
  //The first layer
  Integer firstOffset = valueOf(NumPEs)/4;
  mkConnection(middleSwitches[0][valueOf(MS_RootTopSwitchID)-firstOffset].scatterInPort.putFlit,
                topSwitches[valueOf(MS_RootTopSwitchID)].scatterOutPort[0].getFlit);

  mkConnection(middleSwitches[0][valueOf(MS_RootTopSwitchID)+firstOffset].scatterInPort.putFlit,
                topSwitches[valueOf(MS_RootTopSwitchID)].scatterOutPort[1].getFlit);

  //Middle layers
  for(Integer level = 0; level < valueOf(MS_NumMiddleSwitchLevels)-2; level = level+1)
  begin
    Integer offset = valueOf(NumPEs)/(2**(level+1));
    Integer nextOffset = offset/2;
    Integer firstID = valueOf(NumPEs)/(2**(level+2));

    for(Integer brSwitchID = firstID; brSwitchID < valueOf(NumPEs); brSwitchID=brSwitchID+offset)
    begin
      mkConnection(middleSwitches[level+1][brSwitchID-nextOffset/2].scatterInPort.putFlit,
                     middleSwitches[level][brSwitchID].scatterOutPort[0].getFlit);

      mkConnection(middleSwitches[level+1][brSwitchID+nextOffset/2].scatterInPort.putFlit,
                     middleSwitches[level][brSwitchID].scatterOutPort[1].getFlit);
    end
  end

  Integer lastLevel = valueOf(MS_NumMiddleSwitchLevels)-1;
  for(Integer brSwitchID = 1; brSwitchID < valueOf(NumPEs); brSwitchID=brSwitchID+2)
  begin
    mkConnection(middleSwitches[lastLevel][brSwitchID-1].scatterInPort.putFlit,
                   middleSwitches[lastLevel-1][brSwitchID].scatterOutPort[0].getFlit);

    mkConnection(middleSwitches[lastLevel][brSwitchID].scatterInPort.putFlit,
                   middleSwitches[lastLevel-1][brSwitchID].scatterOutPort[1].getFlit);
  end

  //The last layer
  for(Integer swID = 0; swID<valueOf(NumPEs); swID=swID+1)
  begin
    mkConnection(bottomSwitches[swID].scatterInPort.putFlit,
      middleSwitches[valueOf(MS_NumMiddleSwitchLevels)-1][swID].scatterOutPort[0].getFlit);
  end

  /* Inter PE links*/
  for(Integer swID = 0; swID < valueOf(NumPEs)-1; swID=swID+1)
  begin
    mkConnection(bottomSwitches[swID].interPEInPort[0].putFlit,
                   bottomSwitches[swID+1].interPEOutPort[0].getFlit);
  end
  for(Integer swID = 1; swID < valueOf(NumPEs); swID=swID+1)
  begin
    mkConnection(bottomSwitches[swID-1].interPEInPort[1].putFlit,
                   bottomSwitches[swID].interPEOutPort[1].getFlit);
  end

  /* PE-network connections  */
  Vector#(NumPEs, MicroswitchNetworkDataPort) peDataPortsDummy;
  for(Integer prt=0; prt<valueOf(NumPEs); prt=prt+1)
  begin
    peDataPortsDummy[prt] =
      interface MicroswitchNetworkDataPort
        method Action putFlit(Flit flit);
          `ifdef DEBUG_MICROSWITCHNETWORK
            $display("[Microswitch Network] received a flit from PE[%d]", prt);
          `endif
          if(flit.dests == 0) begin
            bottomSwitches[prt].interPEInPort[2].putFlit(flit);
          end
          else begin
            bottomSwitches[prt].gatherInPort.putFlit(flit);
          end
        endmethod

        method ActionValue#(Flit) getFlit;
          `ifdef DEBUG_MICROSWITCHNETWORK
            $display("[Microswitch Network] send a flit to PE[%d]", prt);
          `endif
          let flit <- bottomSwitches[prt].scatterOutPort.getFlit;
          return flit;
        endmethod
      endinterface;
  end
  interface peDataPorts = peDataPortsDummy;

  /* Microswitch Setup */
  interface MicroswitchNetworkControlPort controlPort; 
    method Action setSwitches(MS_ScatterSetupSignal setupSignal);
      `ifdef DEBUG_MICROSWITCHNETWORK
      $display("[Microswitch Network] Setup switches.");
      for(Integer i =0; i<valueOf(MS_NumBranchNodes);i=i+1) begin
      $display("controlsignal[%d] = %b", i, setupSignal[i]);
      end
      `endif

      `ifdef DEBUG_MICROSWITCHNETWORK
      $display("[Microswitch Network] topSwitch[%d] <- controlSig[%d] = %b", valueOf(MS_RootTopSwitchID), 0, setupSignal[0]);
      `endif

      topSwitches[valueOf(MS_RootTopSwitchID)].configureSwitch(setupSignal[0]);

      for(Integer brSwLevel = 0; brSwLevel < valueOf(MS_NumMiddleSwitchLevels)-1; brSwLevel = brSwLevel+1)
      begin
        Integer controlSigBaseIdx = 2 ** (brSwLevel+2)-2;
        Integer offset = valueOf(NumPEs)/(2**(brSwLevel+1));
        Integer firstBrSwID = valueOf(NumPEs)/(2**(brSwLevel+2));

        for(Integer brSw = firstBrSwID; brSw < valueOf(NumPEs); brSw = brSw + offset) begin
          Integer controlSigOfs = (brSw-firstBrSwID)/offset;
          `ifdef DEBUG_MICROSWITCHNETWORK
          $display("[Microswitch Network] middleSwitch[%d][%d] <- controlSig[%d] = %b", brSwLevel, brSw, controlSigBaseIdx - controlSigOfs, setupSignal[controlSigBaseIdx-controlSigOfs]);
          `endif
          middleSwitches[brSwLevel][brSw].configureSwitch(setupSignal[controlSigBaseIdx - controlSigOfs]);
        end
      end

      for(Integer swID=0; swID<valueOf(NumPEs); swID=swID+1) begin
        middleSwitches[valueOf(MS_NumMiddleSwitchLevels)-1][swID].configureSwitch(2'b10);
      end

    endmethod
  endinterface

  /* Global buffer - network connections */
  interface MicroswitchNetworkDataPort hostDataPort;
    method Action putFlit(Flit flit);
      topSwitches[valueOf(MS_RootTopSwitchID)].scatterInPort.putFlit(flit);
    endmethod

    method ActionValue#(Flit) getFlit;
      gatherOutFifo.deq;
      return gatherOutFifo.first;
    endmethod
  endinterface

endmodule
