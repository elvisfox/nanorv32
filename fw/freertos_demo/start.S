// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

// CSRs
#define csr_custom_irq_mask		0x7C0
#define csr_custom_irq_pend		0x7C1
#define csr_custom_trap			0x7C2

//#define MTIME_BASE_ADDR			0xfffffff0

.global main
.global clear_bits_mip
.global clear_bits_mie
.global clear_bits_custom_irq_pend

.global freertos_risc_v_trap_handler

.section .text.reset_vec
reset_vec:
	// no more than 16 bytes here !
	j start

.section .text.trap_vec
trap_vec:
	j freertos_risc_v_trap_handler

.section .text

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


/* Main program
 **********************************/

start:
	/* Disable global interrupt. */
	csrci mstatus, 8

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

	/* Initialize stack pointer. */
	la sp, __freertos_irq_stack_top

	/* Initialize global pointer */
	# la gp, __global_pointer

	# call __libc_init_array

	/* Enable global interrupt. */
	csrsi mstatus, 8

	jal main
	ebreak
