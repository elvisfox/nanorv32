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

module nanorv32 #(
	parameter [ 0:0] ENABLE_COUNTERS = 1,
	parameter [ 0:0] ENABLE_COUNTERS64 = 1,
	parameter [ 0:0] ENABLE_REGS_16_31 = 1,
	parameter [ 0:0] ENABLE_REGS_DUALPORT = 1,
	// parameter [ 0:0] LATCHED_MEM_RDATA = 0,
	parameter [ 0:0] USE_LA_MEM_INTERFACE = 0,
	parameter [ 0:0] TWO_STAGE_SHIFT = 1,
	parameter [ 0:0] BARREL_SHIFTER = 0,
	parameter [ 0:0] TWO_CYCLE_COMPARE = 0,
	parameter [ 0:0] TWO_CYCLE_ALU = 0,
	parameter [ 0:0] COMPRESSED_ISA = 0,
	parameter [ 0:0] CATCH_MISALIGN = 1,
	parameter [ 0:0] CATCH_ILLINSN = 1,
	parameter [ 0:0] ENABLE_PCPI = 0,
	parameter [ 0:0] ENABLE_MUL = 0,
	parameter [ 0:0] ENABLE_FAST_MUL = 0,
	parameter [ 0:0] ENABLE_DIV = 0,
	parameter [ 0:0] MACHINE_ISA = 0,
	parameter [ 0:0] ENABLE_CSR_MSCRATCH = 1,
	parameter [ 0:0] ENABLE_CSR_MTVAL = 1,
	parameter [ 0:0] ENABLE_CSR_CUSTOM_TRAP = 1,
	parameter [ 0:0] ENABLE_IRQ_EXTERNAL = 1,
	parameter [ 0:0] ENABLE_IRQ_SOFTWARE = 1,
	parameter [ 0:0] ENABLE_MTIME = 1,
	parameter [ 0:0] ENABLE_TRACE = 0,
	parameter [ 0:0] REGS_INIT_ZERO = 0,
	parameter [31:4] MTIME_BASE_ADDR = 28'hffff_fff,
	parameter [31:0] MASKED_IRQ = 32'h 0000_0000,
	parameter [31:0] LATCHED_IRQ = 32'h ffff_ffff,
	parameter [31:0] PROGADDR_RESET = 32'h 0000_0000,
	parameter [31:0] PROGADDR_IRQ = 32'h 0000_0010,
	parameter [31:0] STACKADDR = 32'h ffff_ffff
) (
	input							clk, 
	input							resetn,
	output wire						trap,

	output reg						mem_valid,
	output wire						mem_instr,
	input							mem_ready,

	output reg	[31:0]				mem_addr,
	output reg	[31:0]				mem_wdata,
	output reg	[ 3:0]				mem_wstrb,
	input		[31:0]				mem_rdata,

	// Pico Co-Processor Interface (PCPI)
	output wire						pcpi_valid,
	output wire	[31:0]				pcpi_insn,
	output wire	[31:0]				pcpi_rs1,
	output wire	[31:0]				pcpi_rs2,
	input							pcpi_wr,
	input		[31:0]				pcpi_rd,
	input							pcpi_wait,
	input							pcpi_ready,

	// IRQ Interface
	input		[31:0]				irq,
	output wire	[31:0]				eoi,

`ifdef RISCV_FORMAL
	output wire						rvfi_valid,
	output wire	[63:0]				rvfi_order,
	output wire	[31:0]				rvfi_insn,
	output wire						rvfi_trap,
	output wire						rvfi_halt,
	output wire						rvfi_intr,
	output wire	[ 1:0]				rvfi_mode,
	output wire	[ 1:0]				rvfi_ixl,
	output wire	[ 4:0]				rvfi_rs1_addr,
	output wire	[ 4:0]				rvfi_rs2_addr,
	output wire	[31:0]				rvfi_rs1_rdata,
	output wire	[31:0]				rvfi_rs2_rdata,
	output wire	[ 4:0]				rvfi_rd_addr,
	output wire	[31:0]				rvfi_rd_wdata,
	output wire	[31:0]				rvfi_pc_rdata,
	output wire	[31:0]				rvfi_pc_wdata,
	output wire	[31:0]				rvfi_mem_addr,
	output wire	[ 3:0]				rvfi_mem_rmask,
	output wire	[ 3:0]				rvfi_mem_wmask,
	output wire	[31:0]				rvfi_mem_rdata,
	output wire	[31:0]				rvfi_mem_wdata,

	output wire	[63:0]				rvfi_csr_mcycle_rmask,
	output wire	[63:0]				rvfi_csr_mcycle_wmask,
	output wire	[63:0]				rvfi_csr_mcycle_rdata,
	output wire	[63:0]				rvfi_csr_mcycle_wdata,

	output wire	[63:0]				rvfi_csr_minstret_rmask,
	output wire	[63:0]				rvfi_csr_minstret_wmask,
	output wire	[63:0]				rvfi_csr_minstret_rdata,
	output wire	[63:0]				rvfi_csr_minstret_wdata,
`endif

	// Trace Interface
	output wire						trace_valid,
	output wire	[35:0]				trace_data
);

	wire							mem_valid_int;
	wire	[31:0]					mem_addr_int;
	wire	[31:0]					mem_wdata_int;
	wire	[3:0]					mem_wstrb_int;

	wire							mem_la_read;
	wire							mem_la_write;
	wire	[31:0]					mem_la_addr;
	wire	[31:0]					mem_la_wdata;
	wire	[3:0]					mem_la_wstrb;

	reg			 					core_mem_valid;
	reg								core_mem_ready;
	reg		[31:0]					core_mem_rdata;

	wire							mtip;		// timer interrupt pending bit

	nanorv32_core #(
		.ENABLE_COUNTERS			(ENABLE_COUNTERS),
		.ENABLE_COUNTERS64			(ENABLE_COUNTERS64),
		.ENABLE_REGS_16_31			(ENABLE_REGS_16_31),
		.ENABLE_REGS_DUALPORT		(ENABLE_REGS_DUALPORT),
		.LATCHED_MEM_RDATA			(0),
		.TWO_STAGE_SHIFT			(TWO_STAGE_SHIFT),
		.BARREL_SHIFTER				(BARREL_SHIFTER),
		.TWO_CYCLE_COMPARE			(TWO_CYCLE_COMPARE),
		.TWO_CYCLE_ALU				(TWO_CYCLE_ALU),
		.COMPRESSED_ISA				(COMPRESSED_ISA),
		.CATCH_MISALIGN				(CATCH_MISALIGN),
		.CATCH_ILLINSN				(CATCH_ILLINSN),
		.ENABLE_PCPI				(ENABLE_PCPI),
		.ENABLE_MUL					(ENABLE_MUL),
		.ENABLE_FAST_MUL			(ENABLE_FAST_MUL),
		.ENABLE_DIV					(ENABLE_DIV),
		.MACHINE_ISA				(MACHINE_ISA),
		.ENABLE_CSR_MSCRATCH		(ENABLE_CSR_MSCRATCH),
		.ENABLE_CSR_MTVAL			(ENABLE_CSR_MTVAL),
		.ENABLE_CSR_CUSTOM_TRAP		(ENABLE_CSR_CUSTOM_TRAP),
		.ENABLE_IRQ_EXTERNAL		(ENABLE_IRQ_EXTERNAL),
		.ENABLE_IRQ_SOFTWARE		(ENABLE_IRQ_SOFTWARE),
		.ENABLE_TRACE				(ENABLE_TRACE),
		.REGS_INIT_ZERO				(REGS_INIT_ZERO),
		.MASKED_IRQ					(MASKED_IRQ),
		.LATCHED_IRQ				(LATCHED_IRQ),
		.PROGADDR_RESET				(PROGADDR_RESET),
		.PROGADDR_IRQ				(PROGADDR_IRQ),
		.STACKADDR					(STACKADDR)
	) core(
		.clk						(clk), 
		.resetn						(resetn),
		.trap						(trap),

		.mem_valid					(mem_valid_int),
		.mem_instr					(mem_instr),
		.mem_ready					(core_mem_ready),

		.mem_addr					(mem_addr_int),
		.mem_wdata					(mem_wdata_int),
		.mem_wstrb					(mem_wstrb_int),
		.mem_rdata					(core_mem_rdata),

		// Look-Ahead Interface
		.mem_la_read				(mem_la_read),
		.mem_la_write				(mem_la_write),
		.mem_la_addr				(mem_la_addr),
		.mem_la_wdata				(mem_la_wdata),
		.mem_la_wstrb				(mem_la_wstrb),

		// Pico Co-Processor Interface (PCPI)
		.pcpi_valid					(pcpi_valid),
		.pcpi_insn					(pcpi_insn),
		.pcpi_rs1					(pcpi_rs1),
		.pcpi_rs2					(pcpi_rs2),
		.pcpi_wr					(pcpi_wr),
		.pcpi_rd					(pcpi_rd),
		.pcpi_wait					(pcpi_wait),
		.pcpi_ready					(pcpi_ready),

		// IRQ Interface
		.mtip						(mtip),
		.irq						(irq),
		.eoi						(eoi),

`ifdef RISCV_FORMAL
		.rvfi_valid					(rvfi_valid),
		.rvfi_order					(rvfi_order),
		.rvfi_insn					(rvfi_insn),
		.rvfi_trap					(rvfi_trap),
		.rvfi_halt					(rvfi_halt),
		.rvfi_intr					(rvfi_intr),
		.rvfi_mode					(rvfi_mode),
		.rvfi_ixl					(rvfi_ixl),
		.rvfi_rs1_addr				(rvfi_rs1_addr),
		.rvfi_rs2_addr				(rvfi_rs2_addr),
		.rvfi_rs1_rdata				(rvfi_rs1_rdata),
		.rvfi_rs2_rdata				(rvfi_rs2_rdata),
		.rvfi_rd_addr				(rvfi_rd_addr),
		.rvfi_rd_wdata				(rvfi_rd_wdata),
		.rvfi_pc_rdata				(rvfi_pc_rdata),
		.rvfi_pc_wdata				(rvfi_pc_wdata),
		.rvfi_mem_addr				(rvfi_mem_addr),
		.rvfi_mem_rmask				(rvfi_mem_rmask),
		.rvfi_mem_wmask				(rvfi_mem_wmask),
		.rvfi_mem_rdata				(rvfi_mem_rdata),
		.rvfi_mem_wdata				(rvfi_mem_wdata),

		.rvfi_csr_mcycle_rmask		(rvfi_csr_mcycle_rmask),
		.rvfi_csr_mcycle_wmask		(rvfi_csr_mcycle_wmask),
		.rvfi_csr_mcycle_rdata		(rvfi_csr_mcycle_rdata),
		.rvfi_csr_mcycle_wdata		(rvfi_csr_mcycle_wdata),

		.rvfi_csr_minstret_rmask	(rvfi_csr_minstret_rmask),
		.rvfi_csr_minstret_wmask	(rvfi_csr_minstret_wmask),
		.rvfi_csr_minstret_rdata	(rvfi_csr_minstret_rdata),
		.rvfi_csr_minstret_wdata	(rvfi_csr_minstret_wdata),
`endif

		// Trace Interface
		.trace_valid				(trace_valid),
		.trace_data					(trace_data)
	);

	// Selection between look-ahead and normal memory interface
	always @* begin
		// TODO: provide a better usage of Look-Ahead memory interface
		if(USE_LA_MEM_INTERFACE) begin
			core_mem_valid	= mem_la_read | mem_la_write | mem_valid_int;
			mem_addr		= (mem_la_read | mem_la_write) ? mem_la_addr : mem_addr_int;
			mem_wdata		= (mem_la_read | mem_la_write) ? ({32{mem_la_write}} & mem_la_wdata) : mem_wdata_int;
			mem_wstrb		= (mem_la_read | mem_la_write) ? ({4{mem_la_write}} & mem_la_wstrb) : mem_wstrb_int;
		end
		else begin
			core_mem_valid	= mem_valid_int;
			mem_addr		= mem_addr_int;
			mem_wdata		= mem_wdata_int;
			mem_wstrb		= mem_wstrb_int;
		end
	end

	// Timer (provides mtime, mtimecmp accessible through I/O space)
	reg		[1:0]					timer_io_mtime_valid;
	reg		[1:0]					timer_io_mtimecmp_valid;
	wire							timer_io_ready;
	wire	[31:0]					tiemr_io_rdata;

	generate
		if(ENABLE_MTIME)
			nanorv32_timer timer(
				// clock and reset
				.resetn				(resetn),
				.clk				(clk),

				// I/O access
				.io_mtime_valid		(timer_io_mtime_valid),
				.io_mtimecmp_valid	(timer_io_mtimecmp_valid),
				.io_ready			(timer_io_ready),
				.io_wdata			(mem_wdata),
				.io_wstrb			(mem_wstrb),
				.io_rdata			(tiemr_io_rdata),

				// interrupt request
				.mtip				(mtip)
			);
	endgenerate

	// Address decoder
	always @* begin
		mem_valid = 1'b0;
		timer_io_mtime_valid = 2'b00;
		timer_io_mtimecmp_valid = 2'b00;

		casez({ENABLE_MTIME, mem_addr})
			{1'b1, MTIME_BASE_ADDR, 4'b????}: begin
				case(mem_addr[3:2])
					2'b00:	timer_io_mtime_valid[0] = 1'b1;
					2'b01:	timer_io_mtime_valid[1] = 1'b1;
					2'b10:	timer_io_mtimecmp_valid[0] = 1'b1;
					2'b11:	timer_io_mtimecmp_valid[1] = 1'b1;
				endcase
				core_mem_ready = timer_io_ready;
				core_mem_rdata = tiemr_io_rdata;
			end

			default: begin
				mem_valid = core_mem_valid;
				core_mem_ready = mem_ready;
				core_mem_rdata = mem_rdata;
			end
		endcase
	end

endmodule
