transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

do nanorv32_rtl.do

vlog -vlog01compat -work work {top.v}
vlog -vlog01compat -work work {testbench.v}

vsim -t 10ps -L rtl_work -L work -voptargs="+acc" +firmware=../../bin/freertos_demo/firmware.memh testbench

do wave.do
