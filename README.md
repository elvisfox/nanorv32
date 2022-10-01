
NanoRV32 - [Work in progress] A small RV32I\[MC\] core capable of running RTOS
======================================

NanoRV32 is a fork of [YosysHQ/picorv32](https://github.com/YosysHQ/picorv32).
Small Q&A below explains certain ideas behind this project.

#### Q: What is NanoRV32?
A: NanoRV32 is a CPU core that implements the [RISC-V RV32IMC Instruction Set](http://riscv.org/).
It can be configured as RV32E, RV32I, RV32IC, RV32IM, or RV32IMC core, and optionally a Machine mode ISA
from the Risc-V Privileged Architecture specification (which implies a built-in interrupt controller).

NanoRV32 is free and open hardware licensed under the [ISC license](http://en.wikipedia.org/wiki/ISC_license)
(a license that is similar in terms to the MIT license or the 2-clause BSD license).

#### Q: Why a separate project?
A: The main reason is the absence of backward compatibility to picorv32 especially when it comes to interrupt handling.
The goal of NanoRV32 is to implement the Priviledged ISA according to the official specification, while still keeping
the core minimalistic and small. The core is limited to Machine mode only. The key features compared to picorv32 are the
nested interrupts, the mechanisms to implement interrupt priorities, more powerful trap handling. Of course one of the 
goals is to reduce the effort when porting an existing Risc-V code (such as FreeRTOS).

#### Q: What is in scope of the project?
- Creating and maintaining a ready-to-use FreeRTOS demo
- Refactoring code for better readbility and maintainability
- Future implementation of the floating point unit
- Future implementation of in-system debugger interface
- Making code ASIC synthesis-friendly
- Providing examples for the cheap and popular FPGA evaluation boards (e.g. Intel Cyclone 10 LP, Digilent Arty S7, etc.)
- Designing a pipelined version of the core

#### Q: What is out of scope of the project?
- Scripts for building the toolchain. You should be able to obtain the toolchain from elsewhere.
- picosoc and other loosely related stuff from the original repo (except if to provide working examples for FPGA boards)
- Benchmarks on performance, area and Fmax (unless you want to contribute by porting them from the original repo).
Please refer to [YosysHQ/picorv32](https://github.com/YosysHQ/picorv32) for reference numbers, though they are not
guaranteed to be met.

#### Q: How to contribute?
A: Any contribution is very welcome. I am going to work on this in my spare time only, so the development may be slow.
If you want to contribute, make a fork, then make a branch and issue a Pull Request. Active contributors will be
provided with the rights to maintain branches directly in my repo.


#### Table of Contents

- [Risc-V ISA Documentation](#risc-v-isa-documentation)
- [Features and Typical Applications](#features-and-typical-applications)
- [Repository Structure](#repository-structure)
- [Verilog Module Parameters](#verilog-module-parameters)
- [Priviledged ISA Control and Status Registers](#priviledged-isa-control-and-status-registers)
- [Cycles per Instruction Performance](#cycles-per-instruction-performance)
- [PicoRV32 Native Memory Interface](#picorv32-native-memory-interface)
- [Pico Co-Processor Interface (PCPI)](#pico-co-processor-interface-pcpi)
- [Obtaining RV32I Toolchain](#obtaining-rv32i-toolchain)


Risc-V ISA Documentation
------------------------

The official [Risc-V](https://riscv.org/technical/specifications/) documentation shall always be used as a reference:
- [Volume 1, Unprivileged Spec v. 20191213](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)
- [Volume 2, Privileged Spec v. 20211203](https://github.com/riscv/riscv-isa-manual/releases/download/Priv-v1.12/riscv-privileged-20211203.pdf)


Features and Typical Applications
---------------------------------

- Small (750-2000 LUTs in 7-Series Xilinx Architecture)
- High f<sub>max</sub> (250-450 MHz on 7-Series Xilinx FPGAs)
- Selectable native memory interface or AXI4-Lite master
- Optional IRQ support (using a simple custom ISA)
- Optional Co-Processor Interface

This CPU is meant to be used as auxiliary processor in FPGA designs and ASICs. Due
to its high f<sub>max</sub> it can be integrated in most existing designs without crossing
clock domains. When operated on a lower frequency, it will have a lot of timing
slack and thus can be added to a design without compromising timing closure.

For even smaller size it is possible disable support for registers `x16`..`x31` as
well as `RDCYCLE[H]`, `RDTIME[H]`, and `RDINSTRET[H]` instructions, turning the
processor into an RV32E core.

Furthermore it is possible to choose between a dual-port and a single-port
register file implementation. The former provides better performance while
the latter results in a smaller core.

*Note: In architectures that implement the register file in dedicated memory
resources, such as many FPGAs, disabling the 16 upper registers and/or
disabling the dual-port register file may not further reduce the core size.*

The core exists in three variations: `nanorv32`, `nanorv32_axi` and `nanorv32_wb`.
The first provides a simple native memory interface, that is easy to use in simple
environments. `nanorv32_axi` provides an AXI-4 Lite controller interface that can
easily be integrated with existing systems that are already using the AXI
standard. `nanorv32_wb` provides a Wishbone controller interface.

A separate module `picorv32_axi_adapter` is provided to bridge between the native
memory interface and AXI4. This module can be used to create custom cores that
include one or more PicoRV32 cores together with local RAM, ROM, and
memory-mapped peripherals, communicating with each other using the native
interface, and communicating with the outside world via AXI4.

The optional Machine mode ISA support can be used to react to events from the outside,
implement fault handlers, or catch instructions from a larger ISA and emulate them in
software.

The optional Pico Co-Processor Interface (PCPI) can be used to implement
non-branching instructions in an external coprocessor. Implementations
of PCPI cores that implement the M Standard Extension instructions
`MUL[H[SU|U]]` and `DIV[U]/REM[U]` are included in this package.


Repository Structure
--------------------

#### README.md

You are reading it right now.

#### rtl

This folder contains the following Verilog modules. Each module is defined in a separate file with
the identical name.

The modules named `picorv32_*` are transferred as-is from [YosysHQ/picorv32](https://github.com/YosysHQ/picorv32).

| Module                   | Description                                                           |
| ------------------------ | --------------------------------------------------------------------- |
| `nanorv32`               | Wrapper that combines the core with the timer                         |
| `nanorv32_core`          | The NanoRV32 CPU                                                      |
| `nanorv32_timer`         | 64-bit timer that enables `mtime`, `mtimecmp` CSRs through I/O space  |
| `nanorv32_axi`           | The version of the CPU with AXI4-Lite interface                       |
| `picorv32_axi_adapter`   | Adapter from PicoRV32 Memory Interface to AXI4-Lite                   |
| `nanorv32_wb`            | The version of the CPU with Wishbone controller interface             |
| `picorv32_pcpi_mul`      | A PCPI core that implements the `MUL[H[SU\|U]]` instructions          |
| `picorv32_pcpi_fast_mul` | A version of `picorv32_pcpi_fast_mul` using a single cycle multiplier |
| `picorv32_pcpi_div`      | A PCPI core that implements the `DIV[U]/REM[U]` instructions          |

#### Makefile and testbenches

A basic test environment. Run `make test` to run the standard test bench (`testbench.v`)
in the standard configurations. There are other test benches and configurations. See
the `test_*` make target in the Makefile for details. These targets are using Icarus Verilog.

Also there are scripts to run the testbenches in [QuestaSim](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/questa-edition.html) (free Starter Edition is enough). See `tb/test/run_questasim*.do`.

#### fw/

Contains the firmwares (each in a separate subfolder)

The folder `fw/test/` contains a simple test firmware. This runs the basic tests from `fw/test/tests/`,
some C code, tests IRQ and trap handling and the multiply PCPI core.

All the code in `fw/` is in the public domain. Simply copy whatever you can use.

#### tb/

Contains the testbenches (each in a separate subfolder).

Verilog Module Parameters
-------------------------

The following Verilog module parameters can be used to configure the PicoRV32
core.

#### ENABLE_COUNTERS (default = 1)

This parameter enables support for the `RDCYCLE[H]`, `RDTIME[H]`, and
`RDINSTRET[H]` instructions. This instructions will cause a hardware
trap (like any other unsupported instruction) if `ENABLE_COUNTERS` is set to zero.

*Note: Strictly speaking the `RDCYCLE[H]`, `RDTIME[H]`, and `RDINSTRET[H]`
instructions are not optional for an RV32I core. But chances are they are not
going to be missed after the application code has been debugged and profiled.
This instructions are optional for an RV32E core.*

#### ENABLE_COUNTERS64 (default = 1)

This parameter enables support for the `RDCYCLEH`, `RDTIMEH`, and `RDINSTRETH`
instructions. If this parameter is set to 0, and `ENABLE_COUNTERS` is set to 1,
then only the `RDCYCLE`, `RDTIME`, and `RDINSTRET` instructions are available.

#### ENABLE_REGS_16_31 (default = 1)

This parameter enables support for registers the `x16`..`x31`. The RV32E ISA
excludes this registers. However, the RV32E ISA spec requires a hardware trap
for when code tries to access this registers. This is not implemented in PicoRV32.

#### ENABLE_REGS_DUALPORT (default = 1)

The register file can be implemented with two or one read ports. A dual ported
register file improves performance a bit, but can also increase the size of
the core.

#### USE_LA_MEM_INTERFACE (default = 0)

Enables look-ahead memory interface in order to provide mem_valid one clock earlier
at the cost of reduced Fmax. This option enables an adapter in `nanorv32` wrapper.
`mem_instr` output is not supported in this mode.

Not recommended to use, because it might be obsoleted in the future.

#### TWO_STAGE_SHIFT (default = 1)

By default shift operations are performed in two stages: first shifts in units
of 4 bits and then shifts in units of 1 bit. This speeds up shift operations,
but adds additional hardware. Set this parameter to 0 to disable the two-stage
shift to further reduce the size of the core.

#### BARREL_SHIFTER (default = 0)

By default shift operations are performed by successively shifting by a
small amount (see `TWO_STAGE_SHIFT` above). With this option set, a barrel
shifter is used instead.

#### TWO_CYCLE_COMPARE (default = 0)

This relaxes the longest data path a bit by adding an additional FF stage
at the cost of adding an additional clock cycle delay to the conditional
branch instructions.

*Note: Enabling this parameter will be most effective when retiming (aka
"register balancing") is enabled in the synthesis flow.*

#### TWO_CYCLE_ALU (default = 0)

This adds an additional FF stage in the ALU data path, improving timing
at the cost of an additional clock cycle for all instructions that use
the ALU.

*Note: Enabling this parameter will be most effective when retiming (aka
"register balancing") is enabled in the synthesis flow.*

#### COMPRESSED_ISA (default = 0)

This enables support for the RISC-V Compressed Instruction Set.

#### CATCH_MISALIGN (default = 1)

If `MACHINE_ISA` is set, a misaligned memory access or jump will generate an exception
and give control to the trap handler. Otherwise the core will stall and set the `trap`
output signal high.

Set this to 0 to disable the circuitry for catching misaligned memory
accesses.

#### CATCH_ILLINSN (default = 1)

If `MACHINE_ISA` is set, an illegal instruction will cause an exception and transfer 
of the control to the trap handler. Otherwise the core will stall and set the `trap`
output signal high.

Set this to 0 to disable the circuitry for catching illegal instructions.

The core will still trap on `EBREAK` instructions with this option
set to 0.

#### ENABLE_PCPI (default = 0)

Set this to 1 to enable the Pico Co-Processor Interface (PCPI).

#### ENABLE_MUL (default = 0)

This parameter internally enables PCPI and instantiates the `picorv32_pcpi_mul`
core that implements the `MUL[H[SU|U]]` instructions. The external PCPI
interface only becomes functional when ENABLE_PCPI is set as well.

#### ENABLE_FAST_MUL (default = 0)

This parameter internally enables PCPI and instantiates the `picorv32_pcpi_fast_mul`
core that implements the `MUL[H[SU|U]]` instructions. The external PCPI

interface only becomes functional when ENABLE_PCPI is set as well.

If both ENABLE_MUL and ENABLE_FAST_MUL are set then the ENABLE_MUL setting
will be ignored and the fast multiplier core will be instantiated.

#### ENABLE_DIV (default = 0)

This parameter internally enables PCPI and instantiates the `picorv32_pcpi_div`
core that implements the `DIV[U]/REM[U]` instructions. The external PCPI
interface only becomes functional when ENABLE_PCPI is set as well.

#### MACHINE_ISA (default = 0)

Set this to 1 in order to enable the instructions `csrrw`, `csrrs`, `csrrc`, `csrrwi`, `csrrsi`, `csrrci`,
`wfi`, `mret`. In such case all exceptions will transfer the control to `PROGADDR_IRQ`.

The list of available CSRs is avaiable in [Priviledged ISA Control and Status Registers](#priviledged-isa-control-and-status-registers).

Access to a non existent CSR causes an invalid instruction exception.

#### ENABLE_CSR_MSCRATCH (default = 1)

Enables `mscratch` CSR which can be used by the software for any purpose. This register is never
written by the implementation.

Has no effect if `MACHINE_ISA` is 0.

#### ENABLE_CSR_MTVAL (default = 1)

Enables `mtval` CSR which is written by the implementation when an exception occurs. It contains
additional information about the exception that can be used by the software.

- Invalid instruction exception: `mtval` is the same as `mepc` and contains the address of the invalid instruction.
- Misaligned jump/branch: `mtval` contains the jump/branch destination, while `mepc` contains the address of 
the jump/branch instruction itself.
- Misaligned load/store: `mtval` contains the memory address that caused the exception, while `mepc` contains
the address of the load/store instruction itself.

Has no effect if `MACHINE_ISA` is 0.

#### ENABLE_CSR_CUSTOM_TRAP (default = 1)

Enables `csr_custom_trap` CSR, which contains bits `mtrap` and `mtrap_prev`.

`mtrap` is set 1 when an exception is generated (but remains unchanged upon an interrupt), while `mtrap_prev` stores
the previous value of `mtrap`. `mtrap_prev` is updated with the value of `mtrap` upon an interrupt too. If another
exception is generated while `mtrap` is 1, the CPU is stalled and `trap` output is set high.

Upon `mret` the `mtrap` is updated with the value of `mtrap_prev`. `mtrap_prev` remains unchanged.

If `ENABLE_CSR_CUSTOM_TRAP` is 0, the CPU is never stalled, and the `trap` output is never set high, but a circular
exception might occur if the trap handler produces another exception.

Has no effect if `MACHINE_ISA` is 0.

#### ENABLE_IRQ_EXTERNAL (default = 1)

Enables external interrupts and two additional CSRs: `csr_custom_irq_mask` and `csr_custom_irq_pend`.
Has no effect if `MACHINE_ISA` is 0.

External interrupts are driven by `irq[31:0]` inputs. `MASKED_IRQ` parameter allows to disable specific inputs, while 
`LATCHED_IRQ` parameter allows to switch between edge and level sensitivity.

The CSR `csr_custom_irq_mask` allows software to enable/disable each interrupt source (logic 1 means interrupt is
enabled). The CSR `csr_custom_irq_pend` contains interrupt pending bits. For the edge sensitive interrupts
(`LATCHED_IRQ`) the software must clear the corresponding bits in `csr_custom_irq_pend` when the interrupt is handled.

Bit `MEIE` in `mie` CSR acts as a global enable bit for the external interrupts. Bit `MEIP` in `mip` CSR is read only
and indicates that an external interrupt is pending. It is automatically cleared when either all interrupt pending bits
are cleared in `csr_custom_irq_pend` or corresponding interrupt sources are disabled in `csr_custom_irq_mask`.

The outputs `eoi[31:0]` generate single clock strobes when a bit in `csr_custom_irq_pend` is cleared. None of the
interrupt enable bits (neither local nor global) have no impact on `eoi[31:0]` behavior.

If `ENABLE_IRQ_EXTERNAL` is 0, all related bits are read-only 0, including `MEIP` and `MEIE`.

#### ENABLE_IRQ_SOFTWARE (default = 1)

Enables the support for the software interrupt. The software interrupt can be triggered by writing 1 in `MSIP` bit in
`mip` CSR. Bit `MSIE` in `mie` CSR acts as an interrupt enable bit for the software interrupt. There is only one
software interrupt, so if multiple software interrupts are required, the software must define its own ways to pass
this information to the handler.

If `ENABLE_IRQ_SOFTWARE` is 0, `MSIP` and `MSIE` bits are read-only 0.

Has no effect if `MACHINE_ISA` is 0.

#### ENABLE_MTIME (default = 1)

Enables support for `mtime` CSR which is accessible through I/O space. It contains a 64-bit read-only clock counter.
The access is not atomic, so it is up to the software to guarantee correct reading of the 64-bit value.

The base address of `mtime` and `mtimecmp` is set through [`MTIME_BASE_ADDR`](#mtime_base_addr-default--28h-ffff_fff).

`mtime` can also be used without `MACHINE_ISA`, but the interrupt will not be available in this case.

#### ENABLE_MTIMECMP (default = 1)

Enables `mtimecmp` CSR available through I/O space. When `mtime` becomes greater than or equal to the 64-bit value of
`mtimecmp`, a timer interrupt is generated

The access is not atomic, so it is up to the software to guarantee correct writing of the 64-bit value.
Spurious interrupt may be generated by a careless write.
[Risc-V Priviledged ISA Specification](#risc-v-isa-documentation) suggests the following code in order to update 
`mtimecmp`. Another option is to keep `MTIE` equal 0 (interrupt disabled) while updating `mtimecmp`.

    # New comparand is in a1:a0.
    li t0, -1
    la t1, mtimecmp
    sw t0, 0(t1) # No smaller than old value.
    sw a1, 4(t1) # No smaller than new value.
    sw a0, 0(t1) # New value.

The timer interrupt sets the bit `MTIP` in `mip` CSR. This bit is automatically cleared when `mtimecmp` is set greater
than `mtime`. Writing `MTIP` has no effect. The timer interrupt is enabled through the bit `MTIE` in `mie` CSR.

The base address of `mtime` and `mtimecmp` is set through [`MTIME_BASE_ADDR`](#mtime_base_addr-default--28h-ffff_fff).

Has no effect if `ENABLE_MTIME` is 0 or `MACHINE_ISA` is 0.

If `ENABLE_MTIME` is 0 or `ENABLE_MTIMECMP` is 0, both `MTIP` and `MTIE` bits are read-only 0.

#### ENABLE_TRACE (default = 0)

NOTE: Trace functionality has not been adjusted to work with the Machine ISA. Please feel free to contribute.

Produce an execution trace using the `trace_valid` and `trace_data` output ports.
For a demontration of this feature run `make test_vcd` to create a trace file
and then run `python3 showtrace.py testbench.trace firmware/firmware.elf` to decode
it.

#### REGS_INIT_ZERO (default = 0)

Set this to 1 to initialize all registers to zero (using a Verilog `initial` block).
This can be useful for simulation or formal verification.

#### MTIME_BASE_ADDR (default = 28'h ffff_fff)

Sets the 28 most significant bits of the base address of the 128-bit structure containing `mtime` and `mtimecmp` CSRs.
This structure is always 128-bit aligned, so the the least significant nibble of the address is omitted.

Has no effect is `ENABLE_MTIME` is 0. In this case the address is available for normal use.

#### MASKED_IRQ (default = 32'h 0000_0000)

A 1 bit in this bitmask corresponds to a permanently disabled IRQ.

#### LATCHED_IRQ (default = 32'h ffff_ffff)

A 1 bit in this bitmask indicates that the corresponding IRQ is "latched", i.e.
when the IRQ line is high for only one cycle, the interrupt will be marked as
pending and stay pending until the interrupt handler is called (aka "pulse
interrupts" or "edge-triggered interrupts").

Set a bit in this bitmask to 0 to convert an interrupt line to operate
as "level sensitive" interrupt.

#### PROGADDR_RESET (default = 32'h 0000_0000)

The start address of the program.

#### PROGADDR_IRQ (default = 32'h 0000_0010)

The start address of the exception handler. The same handler is used for interrupts and traps, but the software
may analyse CSRs and pass control to a dedicated handler.

#### STACKADDR (default = 32'h ffff_ffff)

When this parameter has a value different from 0xffffffff, then register `x2` (the
stack pointer) is initialized to this value on reset. (All other registers remain
uninitialized.) Note that the RISC-V calling convention requires the stack pointer
to be aligned on 16 bytes boundaries (4 bytes for the RV32I soft float calling
convention).


Priviledged ISA Control and Status Registers
--------------------------------------------

All CSRs listed below can be accessed for both reading and writing. Writing read-only fields has no effect.
If some features are disabled through Verilog module parameters, some fields may become read only 0. See
corresponding parameters description for details.

| Address | Name              | 31 |      |  0 |
| --------| ------------------|:--:|:----:|:--:|
| 0xF11   | mvendorid         |    | ro 0 |    |
| 0xF12   | marchid           |    | ro 0 |    |
| 0xF13   | mimpid            |    | ro 0 |    |
| 0xF14   | mhartid           |    | ro 0 |    |
| 0xF15   | mconfigptr        |    | ro 0 |    |

| Address | Name              | 31 |      |  8 |   7  |  6 |      |  4 |  3  |  2 |      |  0 |
| --------| ------------------|:--:|:----:|:--:|:----:|:--:|:----:|:--:|:---:|:--:|:----:|:--:|
| 0x300   | mstatus           |    | ro 0 |    | MPIE |    | ro 0 |    | MIE |    | ro 0 |    |

| Address | Name              | 31 |      |  0 |
| --------| ------------------|:--:|:----:|:--:|
| 0x301   | misa              |    | ro 0 |    |
| 0x310   | mstatush          |    | ro 0 |    |

| Address | Name              | 31 |      | 12 |  11  | 10 |      |  8 |   7  |  6 |      |  4 |   3  |  2 |      |  0 |
| --------| ------------------|:--:|:----:|:--:|:----:|:--:|:----:|:--:|:----:|:--:|:----:|:--:|:----:|:--:|:----:|:--:|
| 0x304   | mie               |    | ro 0 |    | MEIE |    | ro 0 |    | MTIE |    | ro 0 |    | MSIE |    | ro 0 |    |
| 0x344   | mip               |    | ro 0 |    | MEIP |    | ro 0 |    | MTIP |    | ro 0 |    | MSIP |    | ro 0 |    |

| Address | Name              | 31 |                                                               |  0 |
| --------| ------------------|:--:| ------------------------------------------------------------- |:--:|
| 0x305   | mtvec             |    | read only machine trap vector (contains `PROGADDR_IRQ` value) |    |
| 0x340   | mscratch          |    | machine scratch register for any software purpose             |    |
| 0x341   | mepc              |    | machine trap return address (used by `mret` instruction)      |    |
| 0x343   | mtval             |    | machine trap value register                                   |    |

| Address | Name              | 31          | 30 |      |  4 |  3 |                |  0 |
| --------| ------------------|:-----------:|:--:|:----:|:--:|:--:|:--------------:|:--:|
| 0x342   | mcause            | Interrupt   |    | ro 0 |    |    | Exception Code |    |

| Address | Name                | 31 |                                              |  0 |
| --------| --------------------|:--:| -------------------------------------------- |:--:|
| 0x7C0   | csr_custom_irq_mask |    | external interrupt enable bits (1: enabled)  |    |
| 0x7C1   | csr_custom_irq_pend |    | external interrupt pending bits (1: pending) |    |

| Address | Name              | 31 |      |  2 |      1     |   0   |
| --------| ------------------|:--:|:----:|:--:|:----------:|:-----:|
| 0x7C2   | csr_custom_trap   |    | ro 0 |    | mtrap_prev | mtrap |

The CSRs `mtime` and `mtimecmp` are provided through I/O space.
The 28-bit `MTIME_BASE_ADDR` parameter is assumed to be left-justified to the 32-bit address in the table below.
| Address                 | Name              | Description                    |
| ------------------------| ------------------| -------------------------------|
| `MTIME_BASE_ADDR` + 0x0 | mtime (LSB)       | Lower 32 bits of `mtime`       |
| `MTIME_BASE_ADDR` + 0x4 | mtime (MSB)       | Upper 32 bits of `mtime`       |
| `MTIME_BASE_ADDR` + 0x8 | mtimecmp (LSB)    | Lower 32 bits of `mtimecmp`    |
| `MTIME_BASE_ADDR` + 0xC | mtimecmp (MSB)    | Upper 32 bits of `mtimecmp`    |

Valid values of `mcause` CSR are listed in the table below.

| Interrupt | Exception Code | Description                                               |
| ---------:| --------------:| --------------------------------------------------------- |
|         1 |              3 | Machine software interrupt                                |
|         1 |              7 | Machine timer interrupt                                   |
|         1 |             11 | Machine external interrupt                                |
|         0 |              0 | Instruction address misaligned                            |
|         0 |              2 | Illegal instruction                                       |
|         0 |              3 | Breakpoint (`ebreak`)                                     |
|         0 |              4 | Load address misaligned                                   |
|         0 |              6 | Store address misaligned                                  |
|         0 |             11 | Environment call from M-mode (`ecall`)                    |

Cycles per Instruction Performance
----------------------------------

*A short reminder: This core is optimized for size and f<sub>max</sub>, not performance.*

Unless stated otherwise, the following numbers apply to a PicoRV32 with
ENABLE_REGS_DUALPORT active and connected to a memory that can accommodate
requests within one clock cycle.

The average Cycles per Instruction (CPI) is approximately 4, depending on the mix of
instructions in the code. The CPI numbers for the individual instructions can
be found in the table below. The column "CPI (SP)" contains the CPI numbers for
a core built without ENABLE_REGS_DUALPORT.

| Instruction          |  CPI | CPI (SP) |
| ---------------------| ----:| --------:|
| direct jump (jal)    |    3 |        3 |
| ALU reg + immediate  |    3 |        3 |
| ALU reg + reg        |    3 |        4 |
| branch (not taken)   |    3 |        4 |
| memory load          |    5 |        5 |
| memory store         |    5 |        6 |
| branch (taken)       |    5 |        6 |
| indirect jump (jalr) |    6 |        6 |
| shift operations     | 4-14 |     4-15 |

When `ENABLE_MUL` is activated, then a `MUL` instruction will execute
in 40 cycles and a `MULH[SU|U]` instruction will execute in 72 cycles.

`ENABLE_FAST_MUL` parameter can enable the fast multiplication.

When `ENABLE_DIV` is activated, then a `DIV[U]/REM[U]` instruction will
execute in 40 cycles.

When `BARREL_SHIFTER` is activated, a shift operation takes as long as
any other ALU operation.

PicoRV32 Native Memory Interface
--------------------------------

The native memory interface of PicoRV32 is a simple valid-ready interface
that can run one memory transfer at a time:

    output        mem_valid
    output        mem_instr
    input         mem_ready

    output [31:0] mem_addr
    output [31:0] mem_wdata
    output [ 3:0] mem_wstrb
    input  [31:0] mem_rdata

The core initiates a memory transfer by asserting `mem_valid`. The valid
signal stays high until the peer asserts `mem_ready`. All core outputs
are stable over the `mem_valid` period. If the memory transfer is an
instruction fetch, the core asserts `mem_instr`.

#### Read Transfer

In a read transfer `mem_wstrb` has the value 0 and `mem_wdata` is unused.

The memory reads the address `mem_addr` and makes the read value available on
`mem_rdata` in the cycle `mem_ready` is high.

There is no need for an external wait cycle. The memory read can be implemented
asynchronously with `mem_ready` going high in the same cycle as `mem_valid`, or
`mem_ready` being tied to constant 1.

#### Write Transfer

In a write transfer `mem_wstrb` is not 0 and `mem_rdata` is unused. The memory
write the data at `mem_wdata` to the address `mem_addr` and acknowledges the
transfer by asserting `mem_ready`.

The 4 bits of `mem_wstrb` are write enables for the four bytes in the addressed
word. Only the 8 values `0000`, `1111`, `1100`, `0011`, `1000`, `0100`, `0010`,
and `0001` are possible, i.e. no write, write 32 bits, write upper 16 bits,
write lower 16, or write a single byte respectively.

There is no need for an external wait cycle. The memory can acknowledge the
write immediately  with `mem_ready` going high in the same cycle as
`mem_valid`, or `mem_ready` being tied to constant 1.

#### Look-Ahead Interface

The PicoRV32 core also provides a "Look-Ahead Memory Interface" that provides
all information about the next memory transfer one clock cycle earlier than the
normal interface.

    output        mem_la_read
    output        mem_la_write
    output [31:0] mem_la_addr
    output [31:0] mem_la_wdata
    output [ 3:0] mem_la_wstrb

In the clock cycle before `mem_valid` goes high, this interface will output a
pulse on `mem_la_read` or `mem_la_write` to indicate the start of a read or
write transaction in the next clock cycle.

*Note: The signals `mem_la_read`, `mem_la_write`, and `mem_la_addr` are driven
by combinatorial circuits within the PicoRV32 core. It might be harder to
achieve timing closure with the look-ahead interface than with the normal
memory interface described above.*


Pico Co-Processor Interface (PCPI)
----------------------------------

The Pico Co-Processor Interface (PCPI) can be used to implement non-branching
instructions in external cores:

    output        pcpi_valid
    output [31:0] pcpi_insn
    output [31:0] pcpi_rs1
    output [31:0] pcpi_rs2
    input         pcpi_wr
    input  [31:0] pcpi_rd
    input         pcpi_wait
    input         pcpi_ready

When an unsupported instruction is encountered and the PCPI feature is
activated (see ENABLE_PCPI above), then `pcpi_valid` is asserted, the
instruction word itself is output on `pcpi_insn`, the `rs1` and `rs2`
fields are decoded and the values in those registers are output
on `pcpi_rs1` and `pcpi_rs2`.

An external PCPI core can then decode the instruction, execute it, and assert
`pcpi_ready` when execution of the instruction is finished. Optionally a
result value can be written to `pcpi_rd` and `pcpi_wr` asserted. The
PicoRV32 core will then decode the `rd` field of the instruction and
write the value from `pcpi_rd` to the respective register.

When no external PCPI core acknowledges the instruction within 16 clock
cycles, then an illegal instruction exception is raised and the respective
interrupt handler is called. A PCPI core that needs more than a couple of
cycles to execute an instruction, should assert `pcpi_wait` as soon as
the instruction has been decoded successfully and keep it asserted until
it asserts `pcpi_ready`. This will prevent the PicoRV32 core from raising
an illegal instruction exception.


Obtaining RV32I Toolchain
-------------------------

On Windows I recommend the following options:
- [Prebuilt Windows Toolchain for RISC-V](https://gnutoolchains.com/risc-v/)
- Install [MSYS2](https://www.msys2.org/), then install the package group [mingw-w64-i686-riscv64-unknown-elf-toolchain](https://packages.msys2.org/group/mingw-w64-i686-riscv64-unknown-elf-toolchain)

Many Linux distributions now include the tools for RISC-V (for example
Ubuntu 22.04 has [gcc-riscv64-unknown-elf](https://packages.ubuntu.com/search?keywords=gcc-riscv64-unknown-elf)).

On macOS one can use [Homebrew](https://brew.sh/) with the following recipe: [homebrew-riscv](https://github.com/riscv-software-src/homebrew-riscv).

Tools (gcc, binutils, etc..) can also be obtained via the [RISC-V Website](https://riscv.org/software-status/).

In any case be sure to set the correct `TOOLCHAIN_PREFIX` in the `Makefile`. It can also include the
full path to the compiler if it's not on system PATH.
