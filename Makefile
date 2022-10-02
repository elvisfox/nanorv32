# Give the user some easy overrides for local configuration quirks.
# If you change one of these and it breaks, then you get to keep both pieces.
SHELL = bash
PYTHON = python
VERILATOR = verilator
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
MKDIR = @"mkdir" -pv

TEST_OBJS = $(addprefix bin/test/tests/,$(addsuffix .o,$(basename $(notdir $(wildcard fw/test/tests/*.S)))))
TEST_FW_OBJS = \
	bin/test/start.o \
	bin/test/trap.o \
	bin/test/print.o \
	bin/test/hello.o \
	bin/test/sieve.o \
	bin/test/multest.o \
	bin/test/stats.o
FREERTOS_DEMO_FW_OBJS = \
	bin/freertos_demo/start.o \
	bin/freertos_demo/FreeRTOS-Kernel/portable/GCC/RISC-V/portASM.o \
	bin/freertos_demo/FreeRTOS-Kernel/portable/GCC/RISC-V/port.o \
	bin/freertos_demo/FreeRTOS-Kernel/portable/MemMang/heap_4.o \
	bin/freertos_demo/FreeRTOS-Kernel/tasks.o \
	bin/freertos_demo/FreeRTOS-Kernel/queue.o \
	bin/freertos_demo/FreeRTOS-Kernel/list.o \
	bin/freertos_demo/FreeRTOS-Kernel/timers.o \
	bin/freertos_demo/main.o \
	bin/freertos_demo/main_blinky.o \
	bin/freertos_demo/print.o
DEPS = $(TEST_FW_OBJS:%.o=%.d) $(FREERTOS_DEMO_FW_OBJS:%.o=%.d)
NANORV32_RTL = \
	rtl/nanorv32.v \
	rtl/nanorv32_core.v \
	rtl/nanorv32_timer.v \
	rtl/picorv32_pcpi_mul.v \
	rtl/picorv32_pcpi_div.v
GCC_WARNS  = -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic # -Wconversion
TOOLCHAIN_PREFIX = riscv64-unknown-elf-
COMPRESSED_ISA = C

# Add things like "export http_proxy=... https_proxy=..." here
# GIT_ENV = true

test: tb/test/testbench.vvp bin/test/firmware.memh
	$(VVP) -N $< +firmware=bin/test/firmware.memh

test_vcd: tb/test/testbench.vvp bin/test/firmware.memh
	$(VVP) -N $< +firmware=bin/test/firmware.memh \
		+vcd=$(patsubst %.vvp,%.vcd,$<) \
		+trace=$(patsubst %.vvp,%.trace,$<) \
		+noerror

# test_rvf: testbench_rvf.vvp firmware/firmware.hex
# 	$(VVP) -N $< +vcd +trace +noerror

test_wb: tb/test/testbench_wb.vvp bin/test/firmware.memh
	$(VVP) -N $< +firmware=bin/test/firmware.memh

test_wb_vcd: tb/test/testbench_wb.vvp bin/test/firmware.memh
	$(VVP) -N $< +firmware=bin/test/firmware.memh \
		+vcd=$(patsubst %.vvp,%.vcd,$<) \
		+trace=$(patsubst %.vvp,%.trace,$<) \
		+noerror

test_axi: tb/test/testbench_axi.vvp bin/test/firmware.memh
	$(VVP) -N $< +firmware=bin/test/firmware.memh

test_axi_vcd: tb/test/testbench_axi.vvp bin/test/firmware.memh
	$(VVP) -N $< +firmware=bin/test/firmware.memh \
		+vcd=$(patsubst %.vvp,%.vcd,$<) \
		+trace=$(patsubst %.vvp,%.trace,$<) \
		+noerror

tb/test/testbench.vvp: $(NANORV32_RTL) tb/test/testbench.v tb/test/nanorv32_wrapper.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) -DFORMAL $^
	chmod -x $@

tb/test/testbench_axi.vvp: $(NANORV32_RTL) tb/test/testbench.v tb/test/nanorv32_wrapper_axi.v tb/test/axi4_memory.v \
		rtl/nanorv32_axi.v rtl/picorv32_axi_adapter.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) -DFORMAL -DTESTBENCH_AXI $^
	chmod -x $@

tb/test/testbench_wb.vvp: $(NANORV32_RTL) tb/test/testbench.v tb/test/nanorv32_wrapper_wb.v tb/test/wb_ram.v \
		rtl/nanorv32_wb.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) -DFORMAL -DTESTBENCH_WB $^
	chmod -x $@

# testbench_rvf.vvp: testbench.v picorv32.v rvfimon.v
# 	$(IVERILOG) -o $@ -D RISCV_FORMAL $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
# 	chmod -x $@

fw/test: bin/test/firmware.memh bin/test/firmware.lss
fw/freertos_demo: bin/freertos_demo/firmware.memh bin/freertos_demo/firmware.lss

# Inherit dependencies on header files
-include $(DEPS)

%.memh: %.bin utils/makehex.py
	$(PYTHON) utils/makehex.py $< 32768 > $@

%.bin: %.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

%.lss: %.elf
	$(TOOLCHAIN_PREFIX)objdump -S $< > $@

bin/test/firmware.elf: $(TEST_FW_OBJS) $(TEST_OBJS) fw/test/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,fw/test/sections.lds,-Map,$(dir $@)firmware.map,--strip-debug \
		$(TEST_FW_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

bin/freertos_demo/firmware.elf: $(FREERTOS_DEMO_FW_OBJS) fw/freertos_demo/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,fw/freertos_demo/sections.lds,-Map,$(dir $@)firmware.map,--strip-debug \
		$(FREERTOS_DEMO_FW_OBJS) -lgcc -lc
	chmod -x $@

bin/%.o: fw/%.S
	$(MKDIR) $(dir $@)
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -MMD -o $@ $< \
		-Ifw/freertos_demo

bin/%.o: fw/%.c
	$(MKDIR) $(dir $@)
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -MMD -o $@ $< \
		-Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib \
		-Ifw/freertos_demo/FreeRTOS-Kernel/include -Ifw/freertos_demo \
		-Ifw/freertos_demo/FreeRTOS-Kernel/portable/GCC/RISC-V

bin/test/tests/%.o: fw/test/tests/%.S fw/test/tests/riscv_test.h fw/test/tests/test_macros.h
	$(MKDIR) $(dir $@)
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

# toc:
# 	gawk '/^-+$$/ { y=tolower(x); gsub("[^a-z0-9]+", "-", y); gsub("-$$", "", y); printf("- [%s](#%s)\n", x, y); } { x=$$0; }' README.md

clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) $(FREERTOS_DEMO_FW_OBJS) $(DEPS)
	rm -vrf bin
	rm -vrf \
		tb/test/testbench.vvp \
		tb/test/testbench_axi.vvp \
		tb/test/testbench_wb.vvp \
		tb/test/testbench.vcd \
		tb/test/testbench_axi.vcd \
		tb/test/testbench_wb.vcd \
		tb/test/testbench.trace \
		tb/test/testbench_axi.trace \
		tb/test/testbench_wb.trace \
		tb/test/vsim.wlf \
		tb/test/wlft* \
		tb/test/modelsim.ini \
		tb/test/rtl_work

.PHONY: test test_vcd test_axi test_axi_vcd test_wb test_wb_vcd fw/test fw/freertos_demo clean
