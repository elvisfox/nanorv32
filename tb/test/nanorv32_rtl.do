vlog -vlog01compat -work work {../../rtl/picorv32_pcpi_mul.v}
# vlog -vlog01compat -work work {../../rtl/picorv32_pcpi_fast_mul.v}
vlog -vlog01compat -work work {../../rtl/picorv32_pcpi_div.v}
# vlog -vlog01compat -work work +define+DEBUGASM +define+DEBUG +define+FORMAL {../../rtl/nanorv32.v}
vlog -vlog01compat -work work +define+FORMAL {../../rtl/nanorv32_core.v}
vlog -vlog01compat -work work {../../rtl/nanorv32.v}
