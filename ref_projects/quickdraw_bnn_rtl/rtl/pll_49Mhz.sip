set_global_assignment -entity "pll_49Mhz" -library "lib_pll_49Mhz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_49Mhz" -library "lib_pll_49Mhz" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "pll_49Mhz" -library "lib_pll_49Mhz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_49Mhz" -name SPD_FILE [file join $::quartus(sip_path) "pll_49Mhz.spd"]

set_global_assignment -library "lib_pll_49Mhz" -name MISC_FILE [file join $::quartus(sip_path) "pll_49Mhz_sim/pll_49Mhz.vo"]
