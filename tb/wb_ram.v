/* ISC License
 *
 * Verilog on-chip RAM with Wishbone interface
 *
 * Copyright (C) 2014, 2016 Olof Kindgren <olof.kindgren@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

module wb_ram #(
	parameter depth = 256,
	parameter memfile = "",
	parameter VERBOSE = 0
) (
	input wb_clk_i,
	input wb_rst_i,

	input [31:0] wb_adr_i,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_we_i,
	input wb_cyc_i,
	input wb_stb_i,

	output reg wb_ack_o,
	output reg [31:0] wb_dat_o,

	input mem_instr,
	output reg tests_passed
);

	reg verbose;
	initial verbose = $test$plusargs("verbose") || VERBOSE;

	initial tests_passed = 0;

	reg [31:0] adr_r;
	wire valid = wb_cyc_i & wb_stb_i;

	always @(posedge wb_clk_i) begin
		adr_r <= wb_adr_i;
		// Ack generation
		wb_ack_o <= valid & !wb_ack_o;
		if (wb_rst_i)
		begin
			adr_r <= {32{1'b0}};
			wb_ack_o <= 1'b0;
		end
	end

	wire ram_we = wb_we_i & valid & wb_ack_o;

	wire [31:0] waddr = adr_r[31:2];
	wire [31:0] raddr = wb_adr_i[31:2];
	wire [3:0] we = {4{ram_we}} & wb_sel_i;

	wire [$clog2(depth/4)-1:0] raddr2 = raddr[$clog2(depth/4)-1:0];
	wire [$clog2(depth/4)-1:0] waddr2 = waddr[$clog2(depth/4)-1:0];

	reg [31:0] mem [0:depth/4-1] /* verilator public */;

	always @(posedge wb_clk_i) begin
		if (ram_we) begin
			if (verbose)
				$display("WR: ADDR=%08x DATA=%08x STRB=%04b",
					adr_r, wb_dat_i, we);

			if (adr_r[31:0] == 32'h1000_0000)
				if (verbose) begin
					if (32 <= wb_dat_i[7:0] && wb_dat_i[7:0] < 128)
						$display("OUT: '%c'", wb_dat_i[7:0]);
					else
						$display("OUT: %3d", wb_dat_i[7:0]);
				end else begin
					$write("%c", wb_dat_i[7:0]);
`ifndef VERILATOR
					$fflush();
`endif
				end
			else
			if (adr_r[31:0] == 32'h2000_0000)
				if (wb_dat_i[31:0] == 123456789)
					tests_passed = 1;
		end
	end

	always @(posedge wb_clk_i) begin
		if (waddr2 < 128 * 1024 / 4) begin
			if (we[0])
				mem[waddr2][7:0] <= wb_dat_i[7:0];

			if (we[1])
				mem[waddr2][15:8] <= wb_dat_i[15:8];

			if (we[2])
				mem[waddr2][23:16] <= wb_dat_i[23:16];

			if (we[3])
				mem[waddr2][31:24] <= wb_dat_i[31:24];

		end

		if (valid & wb_ack_o & !ram_we)
			if (verbose)
				$display("RD: ADDR=%08x DATA=%08x%s", adr_r, mem[raddr2], mem_instr ? " INSN" : "");

		wb_dat_o <= mem[raddr2];
	end

	initial begin
		if (memfile != "")
			$readmemh(memfile, mem);
	end
endmodule
