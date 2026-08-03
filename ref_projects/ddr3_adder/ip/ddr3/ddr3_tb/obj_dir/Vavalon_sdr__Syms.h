// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VAVALON_SDR__SYMS_H_
#define VERILATED_VAVALON_SDR__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vavalon_sdr.h"

// INCLUDE MODULE CLASSES
#include "Vavalon_sdr___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vavalon_sdr__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vavalon_sdr* const __Vm_modelp;
    bool __Vm_activity = false;  ///< Used by trace routines to determine change occurred
    uint32_t __Vm_baseCode = 0;  ///< Used by trace routines when tracing multiple models
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vavalon_sdr___024root          TOP;

    // CONSTRUCTORS
    Vavalon_sdr__Syms(VerilatedContext* contextp, const char* namep, Vavalon_sdr* modelp);
    ~Vavalon_sdr__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
