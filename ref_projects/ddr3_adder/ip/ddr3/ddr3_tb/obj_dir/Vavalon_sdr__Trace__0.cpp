// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vavalon_sdr__Syms.h"


void Vavalon_sdr___024root__trace_chg_0_sub_0(Vavalon_sdr___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vavalon_sdr___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root__trace_chg_0\n"); );
    // Init
    Vavalon_sdr___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vavalon_sdr___024root*>(voidSelf);
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vavalon_sdr___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vavalon_sdr___024root__trace_chg_0_sub_0(Vavalon_sdr___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    bufp->chgBit(oldp+0,(vlSelf->clk));
    bufp->chgBit(oldp+1,(vlSelf->reset));
    bufp->chgBit(oldp+2,(vlSelf->avm_m0_read));
    bufp->chgIData(oldp+3,(vlSelf->avm_m0_address),32);
    bufp->chgIData(oldp+4,(vlSelf->avm_m0_readdata),32);
    bufp->chgBit(oldp+5,(vlSelf->avm_m0_readdatavalid));
    bufp->chgIData(oldp+6,(vlSelf->avm_m0_byteenable),32);
    bufp->chgBit(oldp+7,(vlSelf->avm_m0_waitrequest));
    bufp->chgSData(oldp+8,(vlSelf->avm_m0_burstcount),11);
    bufp->chgBit(oldp+9,(vlSelf->do_read));
    bufp->chgIData(oldp+10,(vlSelf->init_addr),20);
    bufp->chgSData(oldp+11,(vlSelf->burst_length),11);
    bufp->chgIData(oldp+12,(vlSelf->out_data_1),32);
    bufp->chgIData(oldp+13,(vlSelf->out_data_2),32);
    bufp->chgSData(oldp+14,(vlSelf->avalon_sdr__DOT__burst_count),11);
    bufp->chgSData(oldp+15,(vlSelf->avalon_sdr__DOT__n_burst_count),11);
    bufp->chgCData(oldp+16,(vlSelf->avalon_sdr__DOT__cur_state),2);
    bufp->chgCData(oldp+17,(vlSelf->avalon_sdr__DOT__next_state),2);
}

void Vavalon_sdr___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root__trace_cleanup\n"); );
    // Init
    Vavalon_sdr___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vavalon_sdr___024root*>(voidSelf);
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
