// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#define ENABLE_CSR_MSCRATCH
#define ENABLE_HELLO
#define ENABLE_RVTST
#define ENABLE_SIEVE
#define ENABLE_MULTST
#define ENABLE_STATS

// #ifndef ENABLE_QREGS
// #  undef ENABLE_RVTST
// #endif

// Only save registers in IRQ wrapper that are to be saved by the caller in
// the RISC-V ABI, with the excpetion of the stack pointer. The IRQ handler
// will save the rest if necessary. I.e. skip x3, x4, x8, x9, and x18-x27.
#undef ENABLE_FASTIRQ

// CSRs
#define csr_custom_irq_mask		0x7C0
#define csr_custom_irq_pend		0x7C1
#define csr_custom_trap			0x7C2

#define MTIME_BASE_ADDR			0xfffffff0

// #include "custom_ops.S"

	.section .text
	.global irq
	.global trap
	.global hello
	.global sieve
	.global multest
	.global hard_mul
	.global hard_mulh
	.global hard_mulhsu
	.global hard_mulhu
	.global hard_div
	.global hard_divu
	.global hard_rem
	.global hard_remu
	.global stats
	.global clear_bits_mip
	.global clear_bits_mie
	.global clear_bits_custom_irq_pend

reset_vec:
	// no more than 16 bytes here !
	j start


/* Interrupt handler
 **********************************/

.balign 16
irq_vec:
	/* save registers */

#ifdef ENABLE_CSR_MSCRATCH
	// Store ra in mscratch
	csrw mscratch, x1
#else
	// Store ra directly in application stack
	addi sp, sp, -4
	sw x1, 0*4(sp)
#endif

	// ra = &irq_regs
	lui x1, %hi(irq_regs)
	addi x1, x1, %lo(irq_regs)

	// Store sp
	sw sp, 0*4(x1)

#ifdef ENABLE_FASTIRQ
	sw x5,   5*4(x1)
	sw x6,   6*4(x1)
	sw x7,   7*4(x1)
	sw x10, 10*4(x1)
	sw x11, 11*4(x1)
	sw x12, 12*4(x1)
	sw x13, 13*4(x1)
	sw x14, 14*4(x1)
	sw x15, 15*4(x1)
	sw x16, 16*4(x1)
	sw x17, 17*4(x1)
	sw x28, 28*4(x1)
	sw x29, 29*4(x1)
	sw x30, 30*4(x1)
	sw x31, 31*4(x1)
#else
	sw x3,   3*4(x1)
	sw x4,   4*4(x1)
	sw x5,   5*4(x1)
	sw x6,   6*4(x1)
	sw x7,   7*4(x1)
	sw x8,   8*4(x1)
	sw x9,   9*4(x1)
	sw x10, 10*4(x1)
	sw x11, 11*4(x1)
	sw x12, 12*4(x1)
	sw x13, 13*4(x1)
	sw x14, 14*4(x1)
	sw x15, 15*4(x1)
	sw x16, 16*4(x1)
	sw x17, 17*4(x1)
	sw x18, 18*4(x1)
	sw x19, 19*4(x1)
	sw x20, 20*4(x1)
	sw x21, 21*4(x1)
	sw x22, 22*4(x1)
	sw x23, 23*4(x1)
	sw x24, 24*4(x1)
	sw x25, 25*4(x1)
	sw x26, 26*4(x1)
	sw x27, 27*4(x1)
	sw x28, 28*4(x1)
	sw x29, 29*4(x1)
	sw x30, 30*4(x1)
	sw x31, 31*4(x1)
#endif

	/* call interrupt handler C function */

	lui sp, %hi(irq_stack)
	addi sp, sp, %lo(irq_stack)

	// Is it a trap?
	csrr ra, csr_custom_trap
	andi ra, ra, 1		// mask mtrap bit
	beqz ra, not_a_trap

	// call trap handler
	csrr a0, mepc
	csrr a1, mcause
	csrr a2, mtval

	jal ra, trap

	// if return value is not zero, consider trap correctly handled
	bnez a0, trap_handled

	// stop CPU
	ebreak

trap_handled:
	// ok, trap handled, clear mtrap and return

	// mtrap_prev = 0
	csrci csr_custom_trap, 2

	// check whether trapped instruction is a compressed one
	csrr x1, mepc
	lh x2, 0(ra)
	andi x2, x2, 3		// mask op[1:0]
	addi x3, zero, 3
	bne x2, x3, not_compressed
	addi x1, x1, 2

not_compressed:
	addi x1, x1, 2

	// x1 contains pointer to the next instruction
	csrw mepc, x1

	// Proceed to recalling registers
	j irq_vec_end

not_a_trap:
	// It's a normal IRQ

	// arg0 = mip & mie
	csrr a0, mip
	csrr ra, mie
	and a0, a0, ra

	// arg1 = custom_csr_irq_pend
	csrr a1, csr_custom_irq_pend

	// call to C function
	jal ra, irq

	/* restore registers */

irq_vec_end:
	lui x1, %hi(irq_regs)
	addi x1, x1, %lo(irq_regs)

#ifdef ENABLE_FASTIRQ
	lw x5,   5*4(x1)
	lw x6,   6*4(x1)
	lw x7,   7*4(x1)
	lw x10, 10*4(x1)
	lw x11, 11*4(x1)
	lw x12, 12*4(x1)
	lw x13, 13*4(x1)
	lw x14, 14*4(x1)
	lw x15, 15*4(x1)
	lw x16, 16*4(x1)
	lw x17, 17*4(x1)
	lw x28, 28*4(x1)
	lw x29, 29*4(x1)
	lw x30, 30*4(x1)
	lw x31, 31*4(x1)
#else
	lw x3,   3*4(x1)
	lw x4,   4*4(x1)
	lw x5,   5*4(x1)
	lw x6,   6*4(x1)
	lw x7,   7*4(x1)
	lw x8,   8*4(x1)
	lw x9,   9*4(x1)
	lw x10, 10*4(x1)
	lw x11, 11*4(x1)
	lw x12, 12*4(x1)
	lw x13, 13*4(x1)
	lw x14, 14*4(x1)
	lw x15, 15*4(x1)
	lw x16, 16*4(x1)
	lw x17, 17*4(x1)
	lw x18, 18*4(x1)
	lw x19, 19*4(x1)
	lw x20, 20*4(x1)
	lw x21, 21*4(x1)
	lw x22, 22*4(x1)
	lw x23, 23*4(x1)
	lw x24, 24*4(x1)
	lw x25, 25*4(x1)
	lw x26, 26*4(x1)
	lw x27, 27*4(x1)
	lw x28, 28*4(x1)
	lw x29, 29*4(x1)
	lw x30, 30*4(x1)
	lw x31, 31*4(x1)
#endif

	// Restore sp
	lw sp, 0*4(x1)

#ifdef ENABLE_CSR_MSCRATCH
	// Restore ra from mscratch
	csrr x1, mscratch
#else
	// Restore ra from application stack
	lw x1, 0*4(sp)
	addi sp, sp, 4
#endif

	mret

# #ifndef ENABLE_QREGS
.balign 0x200
# #endif
irq_regs:
	// registers are saved to this memory region during interrupt handling
	// the program counter is saved as register 0
	.fill 32,4

	// stack for the interrupt handler
	.fill 128,4
irq_stack:

// routines to access CSR from C code
clear_bits_mip:
	csrc mip, a0
	ret

clear_bits_mie:
	csrc mie, a0
	ret

clear_bits_custom_irq_pend:
	csrc csr_custom_irq_pend, a0
	ret

setup_timer:
	// a0 contains number of clocks

	// Disable timer interrupt
	addi t0, zero, 0x80
	csrc mie, t0

	// Prepare MTIME_BASE_ADDR in t2
	lui t2, %hi(MTIME_BASE_ADDR)
	addi t2, t2, %lo(MTIME_BASE_ADDR)
	
	// read mtime into t1:t0
atomic_read_mtime:
	lw t1, 4(t2)
	lw t0, 0(t2)
	lw t3, 4(t2)
	bne t1, t3, atomic_read_mtime

	// Calculate mtimecmp = t1:t0 + a0
	add t0, t0, a0
	sltu t3, t0, a0
	add t1, t1, t3

	// Store mtimecmp
	li t3, -1
	sw t3, 8(t2) # No smaller than old value.
	sw t1, 12(t2) # No smaller than new value.
	sw t0, 8(t2) # New value.

	// Reenable timer interrupt
	addi t0, zero, 0x80
	csrs mie, t0

	ret


/* Main program
 **********************************/

start:
	// Enable external interrupt
	lui x1, %hi(0x800)
	addi x1, x1, %lo(0x800)
	csrw mie, x1

	// Enable all external interrupts
	addi x1, zero, -1		// x1 = 0xffff_ffff
	csrw csr_custom_irq_mask, x1

	// wait irq
	wfi

	// global enable IRQ handling
	csrwi mstatus, 8		// mie = 1

	/* zero-initialize all registers */
	addi x1, zero, 0
	addi x2, zero, 0
	addi x3, zero, 0
	addi x4, zero, 0
	addi x5, zero, 0
	addi x6, zero, 0
	addi x7, zero, 0
	addi x8, zero, 0
	addi x9, zero, 0
	addi x10, zero, 0
	addi x11, zero, 0
	addi x12, zero, 0
	addi x13, zero, 0
	addi x14, zero, 0
	addi x15, zero, 0
	addi x16, zero, 0
	addi x17, zero, 0
	addi x18, zero, 0
	addi x19, zero, 0
	addi x20, zero, 0
	addi x21, zero, 0
	addi x22, zero, 0
	addi x23, zero, 0
	addi x24, zero, 0
	addi x25, zero, 0
	addi x26, zero, 0
	addi x27, zero, 0
	addi x28, zero, 0
	addi x29, zero, 0
	addi x30, zero, 0
	addi x31, zero, 0

#ifdef ENABLE_HELLO
	/* set stack pointer */
	lui sp,(128*1024)>>12

	/* call hello C code */
	jal ra,hello
#endif

	/* running tests from riscv-tests */

#ifdef ENABLE_RVTST
#  define TEST(n) \
	.global n; \
	addi a0, zero, 1000; \
	jal ra, setup_timer; \
	jal zero,n; \
	.global n ## _ret; \
	n ## _ret:
#else
#  define TEST(n) \
	.global n ## _ret; \
	n ## _ret:
#endif

	TEST(lui)
	TEST(auipc)
	TEST(j)
	TEST(jal)
	TEST(jalr)

	TEST(beq)
	TEST(bne)
	TEST(blt)
	TEST(bge)
	TEST(bltu)
	TEST(bgeu)

	TEST(lb)
	TEST(lh)
	TEST(lw)
	TEST(lbu)
	TEST(lhu)

	TEST(sb)
	TEST(sh)
	TEST(sw)

	TEST(misalign)

	TEST(addi)
	TEST(slti) // also tests sltiu
	TEST(xori)
	TEST(ori)
	TEST(andi)
	TEST(slli)
	TEST(srli)
	TEST(srai)

	TEST(add)
	TEST(sub)
	TEST(sll)
	TEST(slt) // what is with sltu ?
	TEST(xor)
	TEST(srl)
	TEST(sra)
	TEST(or)
	TEST(and)

	TEST(mulh)
	TEST(mulhsu)
	TEST(mulhu)
	TEST(mul)

	TEST(div)
	TEST(divu)
	TEST(rem)
	TEST(remu)

	TEST(simple)

	/* set stack pointer */
	lui sp,(128*1024)>>12

	/* set gp and tp */
	lui gp, %hi(0xdeadbeef)
	addi gp, gp, %lo(0xdeadbeef)
	addi tp, gp, 0

#ifdef ENABLE_SIEVE
	/* call sieve C code */
	jal ra,sieve
#endif

#ifdef ENABLE_MULTST
	/* call multest C code */
	jal ra,multest
#endif

#ifdef ENABLE_STATS
	/* call stats C code */
	jal ra,stats
#endif

	/* print "DONE\n" */
	lui a0,0x10000000>>12
	addi a1,zero,'D'
	addi a2,zero,'O'
	addi a3,zero,'N'
	addi a4,zero,'E'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a2,0(a0)
	sw a3,0(a0)
	sw a4,0(a0)
	sw a5,0(a0)

	li a0, 0x20000000
	li a1, 123456789
	sw a1,0(a0)

	/* trap */
	ebreak


/* Hard mul functions for multest.c
 **********************************/

hard_mul:
	mul a0, a0, a1
	ret

hard_mulh:
	mulh a0, a0, a1
	ret

hard_mulhsu:
	mulhsu a0, a0, a1
	ret

hard_mulhu:
	mulhu a0, a0, a1
	ret

hard_div:
	div a0, a0, a1
	ret

hard_divu:
	divu a0, a0, a1
	ret

hard_rem:
	rem a0, a0, a1
	ret

hard_remu:
	remu a0, a0, a1
	ret

