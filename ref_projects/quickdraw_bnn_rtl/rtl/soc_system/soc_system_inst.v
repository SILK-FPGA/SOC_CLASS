	soc_system u0 (
		.ai_result_i_export      (<connected-to-ai_result_i_export>),      //     ai_result_i.export
		.clk_clk                 (<connected-to-clk_clk>),                 //             clk.clk
		.ext_connect_o_export    (<connected-to-ext_connect_o_export>),    //   ext_connect_o.export
		.hps_0_h2f_reset_reset_n (<connected-to-hps_0_h2f_reset_reset_n>), // hps_0_h2f_reset.reset_n
		.memory_mem_a            (<connected-to-memory_mem_a>),            //          memory.mem_a
		.memory_mem_ba           (<connected-to-memory_mem_ba>),           //                .mem_ba
		.memory_mem_ck           (<connected-to-memory_mem_ck>),           //                .mem_ck
		.memory_mem_ck_n         (<connected-to-memory_mem_ck_n>),         //                .mem_ck_n
		.memory_mem_cke          (<connected-to-memory_mem_cke>),          //                .mem_cke
		.memory_mem_cs_n         (<connected-to-memory_mem_cs_n>),         //                .mem_cs_n
		.memory_mem_ras_n        (<connected-to-memory_mem_ras_n>),        //                .mem_ras_n
		.memory_mem_cas_n        (<connected-to-memory_mem_cas_n>),        //                .mem_cas_n
		.memory_mem_we_n         (<connected-to-memory_mem_we_n>),         //                .mem_we_n
		.memory_mem_reset_n      (<connected-to-memory_mem_reset_n>),      //                .mem_reset_n
		.memory_mem_dq           (<connected-to-memory_mem_dq>),           //                .mem_dq
		.memory_mem_dqs          (<connected-to-memory_mem_dqs>),          //                .mem_dqs
		.memory_mem_dqs_n        (<connected-to-memory_mem_dqs_n>),        //                .mem_dqs_n
		.memory_mem_odt          (<connected-to-memory_mem_odt>),          //                .mem_odt
		.memory_mem_dm           (<connected-to-memory_mem_dm>),           //                .mem_dm
		.memory_oct_rzqin        (<connected-to-memory_oct_rzqin>),        //                .oct_rzqin
		.read_data_o_export      (<connected-to-read_data_o_export>),      //     read_data_o.export
		.read_done_o_export      (<connected-to-read_done_o_export>),      //     read_done_o.export
		.read_enable_o_export    (<connected-to-read_enable_o_export>),    //   read_enable_o.export
		.read_reset_o_export     (<connected-to-read_reset_o_export>),     //    read_reset_o.export
		.read_start_i_export     (<connected-to-read_start_i_export>),     //    read_start_i.export
		.reset_reset_n           (<connected-to-reset_reset_n>)            //           reset.reset_n
	);

