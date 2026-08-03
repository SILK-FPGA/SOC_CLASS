// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vavalon_sdr.h for the primary calling header

#include "Vavalon_sdr__pch.h"
#include "Vavalon_sdr___024root.h"

VL_INLINE_OPT void Vavalon_sdr___024root___ico_sequent__TOP__0(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSelf->avm_m0_address = 0U;
    vlSelf->avm_m0_burstcount = 0U;
    if ((1U == (IData)(vlSelf->avalon_sdr__DOT__cur_state))) {
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

void Vavalon_sdr___024root___eval_ico(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_ico\n"); );
    // Body
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        Vavalon_sdr___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void Vavalon_sdr___024root___eval_triggers__ico(Vavalon_sdr___024root* vlSelf);

bool Vavalon_sdr___024root___eval_phase__ico(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_phase__ico\n"); );
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vavalon_sdr___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelf->__VicoTriggered.any();
    if (__VicoExecute) {
        Vavalon_sdr___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vavalon_sdr___024root___eval_act(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vavalon_sdr___024root___nba_sequent__TOP__0(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___nba_sequent__TOP__0\n"); );
    // Body
    if (vlSelf->reset) {
        vlSelf->out_data_2 = 0U;
        vlSelf->out_data_1 = 0U;
        vlSelf->avalon_sdr__DOT__burst_count = 0U;
        vlSelf->avalon_sdr__DOT__cur_state = 0U;
    } else {
        if ((2U == (IData)(vlSelf->avalon_sdr__DOT__cur_state))) {
            if (vlSelf->avm_m0_readdatavalid) {
                if ((1U & (~ (IData)(vlSelf->avalon_sdr__DOT__burst_count)))) {
                    vlSelf->out_data_2 = vlSelf->avm_m0_readdata;
                }
                if ((1U & (IData)(vlSelf->avalon_sdr__DOT__burst_count))) {
                    vlSelf->out_data_1 = vlSelf->avm_m0_readdata;
                }
            }
        }
        vlSelf->avalon_sdr__DOT__burst_count = vlSelf->avalon_sdr__DOT__n_burst_count;
        vlSelf->avalon_sdr__DOT__cur_state = vlSelf->avalon_sdr__DOT__next_state;
    }
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

void Vavalon_sdr___024root___eval_nba(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vavalon_sdr___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vavalon_sdr___024root___eval_triggers__act(Vavalon_sdr___024root* vlSelf);

bool Vavalon_sdr___024root___eval_phase__act(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vavalon_sdr___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vavalon_sdr___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vavalon_sdr___024root___eval_phase__nba(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vavalon_sdr___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__ico(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__nba(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vavalon_sdr___024root___dump_triggers__act(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG

void Vavalon_sdr___024root___eval(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelf->__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY((0x64U < __VicoIterCount))) {
#ifdef VL_DEBUG
            Vavalon_sdr___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("avalon_sdr.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vavalon_sdr___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelf->__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vavalon_sdr___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("avalon_sdr.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vavalon_sdr___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("avalon_sdr.sv", 1, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vavalon_sdr___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vavalon_sdr___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vavalon_sdr___024root___eval_debug_assertions(Vavalon_sdr___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vavalon_sdr___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->reset & 0xfeU))) {
        Verilated::overWidthError("reset");}
    if (VL_UNLIKELY((vlSelf->avm_m0_readdatavalid & 0xfeU))) {
        Verilated::overWidthError("avm_m0_readdatavalid");}
    if (VL_UNLIKELY((vlSelf->avm_m0_waitrequest & 0xfeU))) {
        Verilated::overWidthError("avm_m0_waitrequest");}
    if (VL_UNLIKELY((vlSelf->do_read & 0xfeU))) {
        Verilated::overWidthError("do_read");}
    if (VL_UNLIKELY((vlSelf->init_addr & 0xfff00000U))) {
        Verilated::overWidthError("init_addr");}
    if (VL_UNLIKELY((vlSelf->burst_length & 0xf800U))) {
        Verilated::overWidthError("burst_length");}
}
#endif  // VL_DEBUG
