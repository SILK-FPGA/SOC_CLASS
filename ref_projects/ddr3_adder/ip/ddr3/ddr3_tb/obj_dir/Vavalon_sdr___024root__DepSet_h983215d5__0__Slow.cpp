// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vavalon_sdr.h for the primary calling header

#include "Vavalon_sdr__pch.h"
#include "Vavalon_sdr___024root.h"

VL_ATTR_COLD void Vavalon_sdr___024root___eval_static(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vavalon_sdr___024root___eval_initial(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
}

VL_ATTR_COLD void Vavalon_sdr___024root___eval_final(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__stl(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vavalon_sdr___024root___eval_phase__stl(Vavalon_sdr___024root* vlSelf);

VL_ATTR_COLD void Vavalon_sdr___024root___eval_settle(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vavalon_sdr___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("avalon_sdr.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vavalon_sdr___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__stl(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vavalon_sdr___024root___stl_sequent__TOP__0(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___stl_sequent__TOP__0\n"); );
    // Body
    vlSelf->avm_m0_read = 0U;
    vlSelf->avm_m0_byteenable = 0U;
    vlSelf->avm_m0_address = 0U;
    vlSelf->avm_m0_burstcount = 0U;
    if ((1U == (IData)(vlSelf->avalon_sdr__DOT__cur_state))) {
        vlSelf->avm_m0_read = 1U;
        vlSelf->avm_m0_byteenable = 0xfU;
        vlSelf->avm_m0_address = (vlSelf->init_addr 
                                  << 0xcU);
        vlSelf->avm_m0_burstcount = vlSelf->burst_length;
    }
    vlSelf->avalon_sdr__DOT__next_state = vlSelf->avalon_sdr__DOT__cur_state;
    if ((0U == (IData)(vlSelf->avalon_sdr__DOT__cur_state))) {
        if (vlSelf->do_read) {
            vlSelf->avalon_sdr__DOT__next_state = 1U;
        }
    } else {
        vlSelf->avalon_sdr__DOT__next_state = ((1U 
                                                == (IData)(vlSelf->avalon_sdr__DOT__cur_state))
                                                ? ((IData)(vlSelf->avm_m0_waitrequest)
                                                    ? 1U
                                                    : 2U)
                                                : (
                                                   (2U 
                                                    == (IData)(vlSelf->avalon_sdr__DOT__cur_state))
                                                    ? 
                                                   ((0U 
                                                     != (IData)(vlSelf->avalon_sdr__DOT__burst_count))
                                                     ? 2U
                                                     : 0U)
                                                    : 0U));
    }
    vlSelf->avalon_sdr__DOT__n_burst_count = vlSelf->burst_length;
    if ((1U != (IData)(vlSelf->avalon_sdr__DOT__cur_state))) {
        if ((2U == (IData)(vlSelf->avalon_sdr__DOT__cur_state))) {
            if (vlSelf->avm_m0_readdatavalid) {
                vlSelf->avalon_sdr__DOT__n_burst_count 
                    = (0x7ffU & ((IData)(vlSelf->avalon_sdr__DOT__burst_count) 
                                 - (IData)(1U)));
            }
        }
    }
}

VL_ATTR_COLD void Vavalon_sdr___024root___eval_stl(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vavalon_sdr___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vavalon_sdr___024root___eval_triggers__stl(Vavalon_sdr___024root* vlSelf);

VL_ATTR_COLD bool Vavalon_sdr___024root___eval_phase__stl(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vavalon_sdr___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vavalon_sdr___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__ico(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VicoTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__act(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__nba(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vavalon_sdr___024root___ctor_var_reset(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->reset = VL_RAND_RESET_I(1);
    vlSelf->avm_m0_read = VL_RAND_RESET_I(1);
    vlSelf->avm_m0_address = VL_RAND_RESET_I(32);
    vlSelf->avm_m0_readdata = VL_RAND_RESET_I(32);
    vlSelf->avm_m0_readdatavalid = VL_RAND_RESET_I(1);
    vlSelf->avm_m0_byteenable = VL_RAND_RESET_I(32);
    vlSelf->avm_m0_waitrequest = VL_RAND_RESET_I(1);
    vlSelf->avm_m0_burstcount = VL_RAND_RESET_I(11);
    vlSelf->do_read = VL_RAND_RESET_I(1);
    vlSelf->init_addr = VL_RAND_RESET_I(20);
    vlSelf->burst_length = VL_RAND_RESET_I(11);
    vlSelf->out_data_1 = VL_RAND_RESET_I(32);
    vlSelf->out_data_2 = VL_RAND_RESET_I(32);
    vlSelf->avalon_sdr__DOT__burst_count = VL_RAND_RESET_I(11);
    vlSelf->avalon_sdr__DOT__n_burst_count = VL_RAND_RESET_I(11);
    vlSelf->avalon_sdr__DOT__cur_state = VL_RAND_RESET_I(2);
    vlSelf->avalon_sdr__DOT__next_state = VL_RAND_RESET_I(2);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
}
