transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work


vlog -vlog01compat -work work {../rtl/picorv32_pcpi_mul.v}
# vlog -vlog01compat -work work {../rtl/picorv32_pcpi_fast_mul.v}
vlog -vlog01compat -work work {../rtl/picorv32_pcpi_div.v}
# vlog -vlog01compat -work work {../rtl/picorv32_axi_adapter.v}
# vlog -vlog01compat -work work +define+DEBUGASM +define+DEBUG +define+FORMAL {../rtl/nanorv32.v}
vlog -vlog01compat -work work +define+FORMAL {../rtl/nanorv32.v}
# vlog -vlog01compat -work work {../rtl/nanorv32_axi.v}

# vlog -vlog01compat -work work {axi4_memory.v}
vlog -vlog01compat -work work +define+COMPRESSED_ISA {nanorv32_wrapper.v}
vlog -vlog01compat -work work {testbench.v}

vsim -t 10ps -L rtl_work -L work -voptargs="+acc" +firmware=../bin/test/firmware.memh testbench

do wave.do
