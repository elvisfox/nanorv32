onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Testbench /testbench/clk
add wave -noupdate -expand -group Testbench /testbench/resetn
add wave -noupdate -expand -group Testbench /testbench/trap
add wave -noupdate -expand -group Testbench /testbench/trace_valid
add wave -noupdate -expand -group Testbench /testbench/trace_data
add wave -noupdate -expand -group Testbench /testbench/trace_file
add wave -noupdate -expand -group Testbench /testbench/irq
add wave -noupdate -expand -group Testbench /testbench/count_cycle
add wave -noupdate -expand -group Testbench /testbench/tests_passed
add wave -noupdate -expand -group Testbench /testbench/cycle_counter
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_valid
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_instr
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_ready
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_addr
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_wdata
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_wstrb
add wave -noupdate -expand -group {IO bus} /testbench/top/mem_rdata
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_la_read
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_la_write
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_la_addr
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_la_wdata
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_la_wstrb
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_do_prefetch
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_do_rinst
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_do_rdata
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_do_wdata
add wave -noupdate -expand -group {Memory Interface} /testbench/top/uut/mem_err_misaligned
add wave -noupdate -expand -group CSR /testbench/top/uut/mstatus_mie
add wave -noupdate -expand -group CSR /testbench/top/uut/mstatus_mpie
add wave -noupdate -expand -group CSR /testbench/top/uut/mie
add wave -noupdate -expand -group CSR /testbench/top/uut/mip
add wave -noupdate -expand -group CSR /testbench/top/uut/mepc
add wave -noupdate -expand -group CSR /testbench/top/uut/mcause_irq
add wave -noupdate -expand -group CSR /testbench/top/uut/mcause_code
add wave -noupdate -expand -group CSR /testbench/top/uut/mtval
add wave -noupdate -expand -group CSR /testbench/top/uut/mscratch
add wave -noupdate -expand -group CSR /testbench/top/uut/irq_mask
add wave -noupdate -expand -group CSR /testbench/top/uut/irq_pending
add wave -noupdate -expand -group CSR /testbench/top/uut/mtrap
add wave -noupdate -expand -group CSR /testbench/top/uut/mtrap_prev
add wave -noupdate -expand -group Instruction /testbench/top/uut/reg_pc
add wave -noupdate -expand -group Instruction -radix ascii /testbench/top/uut/dbg_ascii_state
add wave -noupdate -expand -group Instruction -radix hexadecimal /testbench/top/uut/mem_rdata_latched
add wave -noupdate -expand -group Instruction /testbench/top/uut/mem_done
add wave -noupdate -expand -group Instruction /testbench/top/uut/instr_wfi
add wave -noupdate -expand -group Instruction -radix ascii /testbench/top/uut/dbg_ascii_instr
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_insn_imm
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_insn_rs1
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_insn_rs2
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_insn_rd
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_rs1val
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_rs2val
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_rs1val_valid
add wave -noupdate -expand -group Instruction /testbench/top/uut/dbg_rs2val_valid
add wave -noupdate -expand -group Instruction /testbench/top/uut/latched_store
add wave -noupdate -expand -group Instruction /testbench/top/uut/latched_branch
add wave -noupdate -expand -group Instruction /testbench/top/uut/reg_out
add wave -noupdate -expand -group Instruction /testbench/top/uut/next_pc
add wave -noupdate -expand -group Instruction -expand /testbench/top/uut/cpuregs
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {452121340 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 238
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
WaveRestoreZoom {451938290 ps} {452431370 ps}
