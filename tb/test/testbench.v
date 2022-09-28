// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

`timescale 1 ns / 1 ps

`ifndef VERILATOR
module testbench #(
	parameter AXI_TEST = 0,
	parameter VERBOSE = 0
);
	reg clk = 1;
	reg resetn = 0;
	wire trap;

	always #5 clk = ~clk;

	initial begin
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	reg [1023:0] vcd_filename;
	initial begin
		if ($test$plusargs("vcd")) begin
			if(!$value$plusargs("vcd=%s", vcd_filename))
				vcd_filename = "testbench.vcd";
			$dumpfile(vcd_filename);
			$dumpvars(0, testbench);
		end
		repeat (1000000) @(posedge clk);
		$display("TIMEOUT");
		$finish;
	end

	// Trace recorder
	wire trace_valid;
	wire [35:0] trace_data;
	integer trace_file;

	reg [1023:0] trace_filename;
	initial begin
		if ($test$plusargs("trace")) begin
			if(!$value$plusargs("trace=%s", trace_filename))
				trace_filename = "testbench.trace";
			trace_file = $fopen(trace_filename, "w");
			repeat (10) @(posedge clk);
			while (!trap) begin
				@(posedge clk);
				if (trace_valid)
					$fwrite(trace_file, "%x\n", trace_data);
			end
			$fclose(trace_file);
			$display("Finished writing testbench.trace.");
		end
	end

	// IRQ driver
	reg [31:0] irq = 0;

	reg [15:0] count_cycle = 0;
	always @(posedge clk) count_cycle <= resetn ? count_cycle + 1 : 0;

	always @* begin
		irq = 0;
		irq[4] = &count_cycle[12:0];
		irq[5] = &count_cycle[15:0];
	end

	// uut instance
	wire tests_passed;

`ifdef TESTBENCH_AXI
	nanorv32_wrapper_axi #(
		.AXI_TEST (AXI_TEST),
		.VERBOSE  (VERBOSE)
	) top (
		.clk(clk),
		.resetn(resetn),
		.irq(irq),
		.trap(trap),
		.trace_valid(trace_valid),
		.trace_data(trace_data),
		.tests_passed(tests_passed)
	);
`else
`ifdef TESTBENCH_WB
	nanorv32_wrapper_wb #(
		.VERBOSE (VERBOSE)
	) top (
		.wb_clk(clk),
		.wb_rst(~resetn),
		.irq(irq),
		.trap(trap),
		.trace_valid(trace_valid),
		.trace_data(trace_data),
		.tests_passed(tests_passed)
	);
`else
	nanorv32_wrapper #(
		.VERBOSE  (VERBOSE)
	) top (
		.clk(clk),
		.resetn(resetn),
		.irq(irq),
		.trap(trap),
		.trace_valid(trace_valid),
		.trace_data(trace_data),
		.tests_passed(tests_passed)
	);
`endif
`endif

	// Cycle counter
	integer cycle_counter;
	always @(posedge clk) begin
		cycle_counter <= resetn ? cycle_counter + 1 : 0;
		if (resetn && trap) begin
`ifndef VERILATOR
			repeat (10) @(posedge clk);
`endif
			$display("TRAP after %1d clock cycles", cycle_counter);
			if (tests_passed) begin
				$display("ALL TESTS PASSED.");
				$finish;
			end else begin
				$display("ERROR!");
				if ($test$plusargs("noerror"))
					$finish;
				$stop;
			end
		end
	end
endmodule
`endif
