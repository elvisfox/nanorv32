// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

`timescale 1 ns / 1 ps

module testbench #(
	parameter AXI_TEST = 0,
	parameter VERBOSE = 0
);
	reg clk = 1;
	reg resetn = 0;
	// wire trap;

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
	// wire trace_valid;
	// wire [35:0] trace_data;
	// integer trace_file;

	// reg [1023:0] trace_filename;
	// initial begin
	// 	if ($test$plusargs("trace")) begin
	// 		if(!$value$plusargs("trace=%s", trace_filename))
	// 			trace_filename = "testbench.trace";
	// 		trace_file = $fopen(trace_filename, "w");
	// 		repeat (10) @(posedge clk);
	// 		while (!trap) begin
	// 			@(posedge clk);
	// 			if (trace_valid)
	// 				$fwrite(trace_file, "%x\n", trace_data);
	// 		end
	// 		$fclose(trace_file);
	// 		$display("Finished writing testbench.trace.");
	// 	end
	// end

	// uut instance
	wire [3:0] led;

	top #(
		.VERBOSE  (VERBOSE)
	) top (
		.clk(clk),
		.resetn(resetn),
		.led(led)
	);

	// LED monitor
	reg [3:0] led_prev;

	always @(posedge clk) begin
		if(~resetn)
			led_prev <= led;
		else begin
			led_prev <= led;
			if(led_prev[0] ^ led[0]) begin
				if(!led[0])
					$display("%0t: LED0 is lit: prvSetupHardware() is called", $time);
				else
					$display("%0t: LED0 turned off: this is unexpected", $time);
			end
			if(led_prev[1] ^ led[1]) begin
				if(!led[1])
					$display("%0t: LED1 is lit: main() reached vTaskStartScheduler()", $time);
				else
					$display("%0t: LED1 turned off: this is unexpected", $time);
			end
			if(led_prev[2] ^ led[2])
				$display("%0t: LED2 %0s: prvQueueSendTask() sent a value in the queue", $time,
					led[2] ? "turned off" : "is lit");
			if(led_prev[3] ^ led[3])
				$display("%0t: LED3 %0s: prvQueueReceiveTask() received correct value!", $time,
					led[3] ? "turned off" : "is lit");
		end

		// Help Icarus-Verilog to produce messages on console
		$fflush();
	end

endmodule
