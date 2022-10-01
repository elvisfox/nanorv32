transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

do nanorv32_rtl.do

vlog -vlog01compat -work work {../../rtl/nanorv32_wb.v}
vlog -vlog01compat -work work {wb_ram.v}
vlog -vlog01compat -work work +define+COMPRESSED_ISA {nanorv32_wrapper_wb.v}
vlog -vlog01compat -work work +define+TESTBENCH_WB {testbench.v}

vsim -t 10ps -L rtl_work -L work -voptargs="+acc" +firmware=../../bin/test/firmware.memh testbench

do wave.do
