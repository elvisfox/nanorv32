// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

module top #(
	parameter VERBOSE = 0
) (
	input clk,
	input resetn,
	output reg [3:0] led
);

	wire mem_valid;
	wire mem_instr;
	reg mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg  [31:0] mem_rdata;

	nanorv32 #(
		.COMPRESSED_ISA(1),
		.ENABLE_MUL(1),
		.ENABLE_DIV(1),
		.MACHINE_ISA(1),
		.ENABLE_TRACE(1)
	) nanorv32(
		.clk						(clk),
		.resetn						(resetn),
		// .trap						(trap),
		.mem_valid					(mem_valid),
		.mem_instr					(mem_instr),
		.mem_ready					(mem_ready),
		.mem_addr					(mem_addr),
		.mem_wdata					(mem_wdata),
		.mem_wstrb					(mem_wstrb),
		.mem_rdata					(mem_rdata)
		// .irq						(irq)
	);

	reg [31:0]						memory [0:128*1024/4-1];

	// Read firmware into memory
	reg [1023:0] firmware_file;
	initial begin
		if (!$value$plusargs("firmware=%s", firmware_file))
			firmware_file = "firmware/firmware.hex";
		$readmemh(firmware_file, memory);
	end

	// Memory model
	always @(posedge clk) begin
		if(~resetn) begin
			led <= 4'hF;
			mem_ready <= 1'b0;
			mem_rdata <= 32'hxxxx_xxxx;
		end
		else begin
			mem_ready <= 0;
			if (mem_valid && !mem_ready) begin
				// 0000_0000..0001_FFFF - Memory access
				if (mem_addr < 128*1024) begin
					mem_ready <= 1'b1;
					mem_rdata <= memory[mem_addr >> 2];
					if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
					if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
					if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
				end

				// 1000_0000 - Output
				else if(mem_addr == 32'h1000_0000) begin
					if(mem_wstrb[0]) begin
						if(VERBOSE) begin
							if(32 <= mem_wdata && mem_wdata < 128)
								$display("OUT: '%c'", mem_wdata[7:0]);
							else
								$display("OUT: %3d", mem_wdata);
						end
						else begin
							$write("%c", mem_wdata[7:0]);
`ifndef VERILATOR
							$fflush();
`endif
						end
					end
					mem_rdata <= 0;
					mem_ready <= 1'b1;
				end

				// 2000_0000 - led
				else if(mem_addr == 32'h2000_0000) begin
					if(mem_wstrb[0])
						led <= mem_wdata[3:0];
					mem_rdata <= {28'h0000_000, led};
					mem_ready <= 1'b1;
				end
				
				// Invalid address?
				else begin
					$display("OUT-OF-BOUNDS MEMORY ACCESS TO %08x, wstrb=%04b", mem_wdata, mem_wstrb);
					$finish;
				end
			end

			else begin
				mem_rdata <= 32'hxxxx_xxxx;
			end
		end
	end

endmodule
