// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vavalon_sdr__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Vavalon_sdr::Vavalon_sdr(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vavalon_sdr__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , reset{vlSymsp->TOP.reset}
    , avm_m0_read{vlSymsp->TOP.avm_m0_read}
    , avm_m0_readdatavalid{vlSymsp->TOP.avm_m0_readdatavalid}
    , avm_m0_waitrequest{vlSymsp->TOP.avm_m0_waitrequest}
    , do_read{vlSymsp->TOP.do_read}
    , avm_m0_burstcount{vlSymsp->TOP.avm_m0_burstcount}
    , burst_length{vlSymsp->TOP.burst_length}
    , avm_m0_address{vlSymsp->TOP.avm_m0_address}
    , avm_m0_readdata{vlSymsp->TOP.avm_m0_readdata}
    , avm_m0_byteenable{vlSymsp->TOP.avm_m0_byteenable}
    , init_addr{vlSymsp->TOP.init_addr}
    , out_data_1{vlSymsp->TOP.out_data_1}
    , out_data_2{vlSymsp->TOP.out_data_2}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vavalon_sdr::Vavalon_sdr(const char* _vcname__)
    : Vavalon_sdr(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vavalon_sdr::~Vavalon_sdr() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vavalon_sdr___024root___eval_debug_assertions(Vavalon_sdr___024root* vlSelf);
#endif  // VL_DEBUG
void Vavalon_sdr___024root___eval_static(Vavalon_sdr___024root* vlSelf);
void Vavalon_sdr___024root___eval_initial(Vavalon_sdr___024root* vlSelf);
void Vavalon_sdr___024root___eval_settle(Vavalon_sdr___024root* vlSelf);
void Vavalon_sdr___024root___eval(Vavalon_sdr___024root* vlSelf);

void Vavalon_sdr::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vavalon_sdr::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vavalon_sdr___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vavalon_sdr___024root___eval_static(&(vlSymsp->TOP));
        Vavalon_sdr___024root___eval_initial(&(vlSymsp->TOP));
        Vavalon_sdr___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vavalon_sdr___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vavalon_sdr::eventsPending() { return false; }

uint64_t Vavalon_sdr::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vavalon_sdr::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vavalon_sdr___024root___eval_final(Vavalon_sdr___024root* vlSelf);

VL_ATTR_COLD void Vavalon_sdr::final() {
    Vavalon_sdr___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vavalon_sdr::hierName() const { return vlSymsp->name(); }
const char* Vavalon_sdr::modelName() const { return "Vavalon_sdr"; }
unsigned Vavalon_sdr::threads() const { return 1; }
void Vavalon_sdr::prepareClone() const { contextp()->prepareClone(); }
void Vavalon_sdr::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vavalon_sdr::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vavalon_sdr___024root__trace_decl_types(VerilatedVcd* tracep);

void Vavalon_sdr___024root__trace_init_top(Vavalon_sdr___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vavalon_sdr___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vavalon_sdr___024root*>(voidSelf);
    Vavalon_sdr__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    Vavalon_sdr___024root__trace_decl_types(tracep);
    Vavalon_sdr___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vavalon_sdr___024root__trace_register(Vavalon_sdr___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Vavalon_sdr::trace(VerilatedVcdC* tfp, int levels, int options) {
    if (tfp->isOpen()) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vavalon_sdr::trace()' shall not be called after 'VerilatedVcdC::open()'.");
    }
    if (false && levels && options) {}  // Prevent unused
    tfp->spTrace()->addModel(this);
    tfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vavalon_sdr___024root__trace_register(&(vlSymsp->TOP), tfp->spTrace());
}
