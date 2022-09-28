// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.


module nanorv32_wrapper_wb #(
	parameter VERBOSE = 0
) (
	input wb_clk,
	input wb_rst,
	input [31:0] irq,
	output trap,
	output trace_valid,
	output [35:0] trace_data,
	output tests_passed
);
	wire mem_instr;

	wire [31:0] wb_m2s_adr;
	wire [31:0] wb_m2s_dat;
	wire [3:0] wb_m2s_sel;
	wire wb_m2s_we;
	wire wb_m2s_cyc;
	wire wb_m2s_stb;
	wire [31:0] wb_s2m_dat;
	wire wb_s2m_ack;

	wb_ram #(
		.depth (128*1024),
		.VERBOSE (VERBOSE)
	) ram ( // Wishbone interface
		.wb_clk_i(wb_clk),
		.wb_rst_i(wb_rst),

		.wb_adr_i(wb_m2s_adr),
		.wb_dat_i(wb_m2s_dat),
		.wb_stb_i(wb_m2s_stb),
		.wb_cyc_i(wb_m2s_cyc),
		.wb_dat_o(wb_s2m_dat),
		.wb_ack_o(wb_s2m_ack),
		.wb_sel_i(wb_m2s_sel),
		.wb_we_i(wb_m2s_we),

		.mem_instr(mem_instr),
		.tests_passed(tests_passed)
	);

	nanorv32_wb #(
`ifndef SYNTH_TEST
`ifdef SP_TEST
		.ENABLE_REGS_DUALPORT(0),
`endif
`ifdef COMPRESSED_ISA
		.COMPRESSED_ISA(1),
`endif
		.ENABLE_MUL(1),
		.ENABLE_DIV(1),
		.MACHINE_ISA(1),
		.ENABLE_TRACE(1)
`endif
	) uut (
		.trap (trap),
		.irq (irq),
		.trace_valid (trace_valid),
		.trace_data (trace_data),
		.mem_instr(mem_instr),

		.wb_clk_i(wb_clk),
		.wb_rst_i(wb_rst),

		.wbm_adr_o(wb_m2s_adr),
		.wbm_dat_i(wb_s2m_dat),
		.wbm_stb_o(wb_m2s_stb),
		.wbm_ack_i(wb_s2m_ack),
		.wbm_cyc_o(wb_m2s_cyc),
		.wbm_dat_o(wb_m2s_dat),
		.wbm_we_o(wb_m2s_we),
		.wbm_sel_o(wb_m2s_sel)
	);

	reg [1023:0] firmware_file;
	initial begin
		if (!$value$plusargs("firmware=%s", firmware_file))
			firmware_file = "firmware/firmware.hex";
		$readmemh(firmware_file, ram.mem);
	end
endmodule
