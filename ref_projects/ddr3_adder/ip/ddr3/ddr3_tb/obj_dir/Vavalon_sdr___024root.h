// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vavalon_sdr.h for the primary calling header

#ifndef VERILATED_VAVALON_SDR___024ROOT_H_
#define VERILATED_VAVALON_SDR___024ROOT_H_  // guard

#include "verilated.h"


class Vavalon_sdr__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vavalon_sdr___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(reset,0,0);
    VL_OUT8(avm_m0_read,0,0);
    VL_IN8(avm_m0_readdatavalid,0,0);
    VL_IN8(avm_m0_waitrequest,0,0);
    VL_IN8(do_read,0,0);
    CData/*1:0*/ avalon_sdr__DOT__cur_state;
    CData/*1:0*/ avalon_sdr__DOT__next_state;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    VL_OUT16(avm_m0_burstcount,10,0);
    VL_IN16(burst_length,10,0);
    SData/*10:0*/ avalon_sdr__DOT__burst_count;
    SData/*10:0*/ avalon_sdr__DOT__n_burst_count;
    VL_OUT(avm_m0_address,31,0);
    VL_IN(avm_m0_readdata,31,0);
    VL_OUT(avm_m0_byteenable,31,0);
    VL_IN(init_addr,19,0);
    VL_OUT(out_data_1,31,0);
    VL_OUT(out_data_2,31,0);
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vavalon_sdr__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vavalon_sdr___024root(Vavalon_sdr__Syms* symsp, const char* v__name);
    ~Vavalon_sdr___024root();
    VL_UNCOPYABLE(Vavalon_sdr___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
