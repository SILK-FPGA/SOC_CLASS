// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vavalon_sdr.h for the primary calling header

#include "Vavalon_sdr__pch.h"
#include "Vavalon_sdr__Syms.h"
#include "Vavalon_sdr___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__ico(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG

void Vavalon_sdr___024root___eval_triggers__ico(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_triggers__ico\n"); );
    // Body
    vlSelf->__VicoTriggered.set(0U, (IData)(vlSelf->__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vavalon_sdr___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__act(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG

void Vavalon_sdr___024root___eval_triggers__act(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, ((IData)(vlSelf->clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__clk__0))));
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vavalon_sdr___024root___dump_triggers__act(vlSelf);
    }
#endif
}
