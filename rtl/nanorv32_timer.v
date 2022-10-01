/*
 *  NanoRV32 -- A small RV32I[MC] core capable of running RTOS
 *
 *  Modifications authored by Elvis Fox <elvisfox@github.com>
 *
 *  nanoRV32 is a fork of PicoRV32:
 *  https://github.com/YosysHQ/picorv32
 *  Copyright (C) 2015  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PE RFORMANCE OF THIS SOFTWARE.
 *
 */

module nanorv32_timer(
	// clock and reset
	input							resetn,
	input							clk,

	// I/O access
	input		[1:0]				io_mtime_valid,
	input		[1:0]				io_mtimecmp_valid,
	output reg						io_ready,
	input		[31:0]				io_wdata,
	input		[3:0]				io_wstrb,
	output reg	[31:0]				io_rdata,

	// interrupt request
	output wire						mtip
);

	// 64-bit counter
	reg			[31:0]				cnt[1:0];
	reg								inc_cnt1;

	always @(posedge clk) begin
		if(~resetn) begin
			cnt[1] <= 0;
			cnt[0] <= 0;
			inc_cnt1 <= 1'b0;
		end
		else begin
			// Lower part of the counter
			cnt[0] <= cnt[0] + 1'b1;
			inc_cnt1 <= cnt[0] == 32'hffff_fffe;

			// Upper part of the counter
			if(inc_cnt1)
				cnt[1] <= cnt[1] + 1'b1;
		end
	end

	// Interrupt comparator
	reg			[31:0]				cmp_val[1:0];

	wire signed	[32:0]				cmp_sub[1:0];
	reg			[1:0]				cmp;

	assign		cmp_sub[1]			= cnt[1] - cmp_val[1];	// subtraction forces synthesiser to use carry chain
	assign		cmp_sub[0]			= cnt[0] - cmp_val[0];

	always @(posedge clk) begin
		if(~resetn)
			cmp <= 2'b00;
		else
			cmp <= {cmp_sub[1][32], cmp_sub[0][32]};
	end

	assign		mtip				= ~|cmp;

	// I/O interface
	integer i;
	always @(posedge clk) begin
		if(~resetn) begin
			for(i = 0; i < 2; i = i + 1)
				cmp_val[i] <= 0;
		end
		else begin
			for(i = 0; i < 2; i = i + 1) begin
				if(io_mtimecmp_valid[i]) begin
					if(io_wstrb[3])
						cmp_val[i][31:24]	<= io_wdata[31:24];
					if(io_wstrb[2])
						cmp_val[i][23:16]	<= io_wdata[23:16];
					if(io_wstrb[1])
						cmp_val[i][15:8]	<= io_wdata[15:8];
					if(io_wstrb[0])
						cmp_val[i][7:0]		<= io_wdata[7:0];
				end
			end
		end
	end
	
	always @* begin
		io_ready = |{io_mtimecmp_valid, io_mtime_valid};

		case({io_mtimecmp_valid, io_mtime_valid})
			4'b1000:	io_rdata = cmp_val[1];
			4'b0100:	io_rdata = cmp_val[0];
			4'b0010:	io_rdata = cnt[1];
			4'b0001:	io_rdata = cnt[0];
			default:	io_rdata = 32'hxxxx_xxxx;
		endcase
	end

endmodule
