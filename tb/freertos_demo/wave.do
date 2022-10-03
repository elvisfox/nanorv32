onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Testbench /testbench/clk
add wave -noupdate -expand -group Testbench /testbench/resetn
add wave -noupdate -expand -group Testbench /testbench/top/nanorv32/core/eoi
add wave -noupdate -expand -group Testbench /testbench/led
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_valid
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_instr
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_ready
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_addr
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_wdata
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_wstrb
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_rdata
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_read
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_write
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_addr
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_wdata
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_wstrb
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_do_prefetch
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_do_rinst
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_do_rdata
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_do_wdata
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_use_prefetched_high_word
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_state
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_xfer
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_firstword
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_secondword
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/last_mem_valid
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_la_firstword_reg
add wave -noupdate -group {Memory Interface} /testbench/top/nanorv32/core/mem_done
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mstatus_mie
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mstatus_mpie
add wave -noupdate -group CSR -expand /testbench/top/nanorv32/core/mie
add wave -noupdate -group CSR -expand /testbench/top/nanorv32/core/mip
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mepc
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mcause_irq
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mcause_code
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mtval
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mscratch
add wave -noupdate -group CSR /testbench/top/nanorv32/core/irq_mask
add wave -noupdate -group CSR /testbench/top/nanorv32/core/irq_pending
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mtrap
add wave -noupdate -group CSR /testbench/top/nanorv32/core/mtrap_prev
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/reg_pc
add wave -noupdate -group Instruction -radix ascii /testbench/top/nanorv32/core/dbg_ascii_state
add wave -noupdate -group Instruction -radix hexadecimal /testbench/top/nanorv32/core/mem_rdata_latched
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/mem_done
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/instr_wfi
add wave -noupdate -group Instruction -radix ascii /testbench/top/nanorv32/core/dbg_ascii_instr
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_insn_imm
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_insn_rs1
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_insn_rs2
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_insn_rd
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_rs1val
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_rs2val
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_rs1val_valid
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/dbg_rs2val_valid
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/latched_store
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/latched_branch
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/reg_out
add wave -noupdate -group Instruction /testbench/top/nanorv32/core/next_pc
add wave -noupdate -group Instruction -expand /testbench/top/nanorv32/core/cpuregs
add wave -noupdate -expand -group Timer /testbench/top/nanorv32/genblk1/timer/mtip
add wave -noupdate -expand -group Timer -expand /testbench/top/nanorv32/genblk1/timer/cnt
add wave -noupdate -expand -group Timer /testbench/top/nanorv32/genblk1/timer/inc_cnt1
add wave -noupdate -expand -group Timer -expand /testbench/top/nanorv32/genblk1/timer/cmp_val
add wave -noupdate -expand -group Timer -expand /testbench/top/nanorv32/genblk1/timer/cmp_sub
add wave -noupdate -expand -group Timer -expand /testbench/top/nanorv32/genblk1/timer/cmp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {339991000 ps} 0} {{Cursor 2} {94094260 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 279
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {1734953840 ps} {4729065590 ps}
