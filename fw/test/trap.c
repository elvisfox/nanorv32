// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"

// counters
static unsigned int ext_irq_4_count = 0;
static unsigned int ext_irq_5_count = 0;
static unsigned int timer_irq_count = 0;

// addresses of labels in misalign.S that will cause traps
extern uint8_t aligned_word[];
void misalign_sw_1(void);
void misalign_sw_2(void);
void misalign_sw_3(void);
void misalign_sh_1(void);
void misalign_sh_3(void);
void misalign_lw_1(void);
void misalign_lw_2(void);
void misalign_lw_3(void);
void misalign_lh_1(void);
void misalign_lh_3(void);
void misalign_j_1(void);
void misalign_j_1_dst(void);

void irq(uint32_t mip, uint32_t irqs)
{
	if ((irqs & (1<<4)) != 0) {
		ext_irq_4_count++;
		// print_str("[EXT-IRQ-4]");
		clear_bits_custom_irq_pend(1<<4);
	}

	if ((irqs & (1<<5)) != 0) {
		ext_irq_5_count++;
		// print_str("[EXT-IRQ-5]");
		clear_bits_custom_irq_pend(1<<5);
	}

	if ((mip & M_IRQ_TIMER) != 0) {
		timer_irq_count++;
		// print_str("[TIMER-IRQ]");

		// disable timer interrupt
		clear_bits_mie(M_IRQ_TIMER);
	}
}

bool trap(void (*mepc)(void), uint32_t mcause, void *mtval) {
	if(mepc == &misalign_sw_1 && mcause == 6 && mtval == &aligned_word[1])
		return true;
	else if(mepc == &misalign_sw_2 && mcause == 6 && mtval == &aligned_word[2])
		return true;
	else if(mepc == &misalign_sw_3 && mcause == 6 && mtval == &aligned_word[3])
		return true;
	else if(mepc == &misalign_sh_1 && mcause == 6 && mtval == &aligned_word[1])
		return true;
	else if(mepc == &misalign_sh_3 && mcause == 6 && mtval == &aligned_word[3])
		return true;
	else if(mepc == &misalign_lw_1 && mcause == 4 && mtval == &aligned_word[1])
		return true;
	else if(mepc == &misalign_lw_2 && mcause == 4 && mtval == &aligned_word[2])
		return true;
	else if(mepc == &misalign_lw_3 && mcause == 4 && mtval == &aligned_word[3])
		return true;
	else if(mepc == &misalign_lh_1 && mcause == 4 && mtval == &aligned_word[1])
		return true;
	else if(mepc == &misalign_lh_3 && mcause == 4 && mtval == &aligned_word[3])
		return true;
	else if(mepc == &misalign_j_1 && mcause == 0 && (uint32_t)mtval == (uint32_t)&misalign_j_1_dst+1)
		return true;

	// checking compressed isa q0 reg handling
	// if ((irqs & 6) != 0) {
	// 	uint32_t pc = (regs[0] & 1) ? regs[0] - 3 : regs[0] - 4;
	// 	uint32_t instr = *(uint16_t*)pc;

	// 	if ((instr & 3) == 3)
	// 		instr = instr | (*(uint16_t*)(pc + 2)) << 16;

	// 	if (((instr & 3) != 3) != (regs[0] & 1)) {
	// 		print_str("Mismatch between q0 LSB and decoded instruction word! q0=0x");
	// 		print_hex(regs[0], 8);
	// 		print_str(", instr=0x");
	// 		if ((instr & 3) == 3)
	// 			print_hex(instr, 8);
	// 		else
	// 			print_hex(instr, 4);
	// 		print_str("\n");
	// 		__asm__ volatile ("ebreak");
	// 	}

	// 	clear_bits_custom_irq_pend(6);
	// }

	uint32_t instr = *(uint16_t*)(uint32_t)mepc;

	switch(mcause) {
		case 0:
			print_str("Misaligned jump at 0x");
			print_hex((uint32_t)mepc, 8);
			print_str(", destination: 0x");
			print_hex((uint32_t)mtval, 8);
			print_str("\n");
			break;

		case 2:
			print_str("Illegal Instruction at 0x");
			print_hex((uint32_t)mepc, 8);
			print_str(": 0x");
			print_hex(instr, ((instr & 3) == 3) ? 8 : 4);
			print_str("\n");
			break;

		case 3:
			print_str("EBREAK instruction at 0x");
			print_hex((uint32_t)mepc, 8);
			print_str("\n");
			break;

		case 4:
			print_str("Load address misaligned at 0x");
			print_hex((uint32_t)mepc, 8);
			print_str(", memory address: 0x");
			print_hex((uint32_t)mtval, 8);
			print_str("\n");
			break;

		case 6:
			print_str("Store address misaligned at 0x");
			print_hex((uint32_t)mepc, 8);
			print_str(", memory address: 0x");
			print_hex((uint32_t)mtval, 8);
			print_str("\n");
			break;

		case 11:
			print_str("ECALL instruction at 0x");
			print_hex((uint32_t)mepc, 8);
			print_str("\n");
			break;
	}

	// for (int i = 0; i < 8; i++)
	// for (int k = 0; k < 4; k++)
	// {
	// 	int r = i + k*8;

	// 	if (r == 0) {
	// 		print_str("pc  ");
	// 	} else
	// 	if (r < 10) {
	// 		print_chr('x');
	// 		print_chr('0' + r);
	// 		print_chr(' ');
	// 		print_chr(' ');
	// 	} else
	// 	if (r < 20) {
	// 		print_chr('x');
	// 		print_chr('1');
	// 		print_chr('0' + r - 10);
	// 		print_chr(' ');
	// 	} else
	// 	if (r < 30) {
	// 		print_chr('x');
	// 		print_chr('2');
	// 		print_chr('0' + r - 20);
	// 		print_chr(' ');
	// 	} else {
	// 		print_chr('x');
	// 		print_chr('3');
	// 		print_chr('0' + r - 30);
	// 		print_chr(' ');
	// 	}

	// 	print_hex(regs[r], 8);
	// 	print_str(k == 3 ? "\n" : "    ");
	// }

	print_str("------------------------------------------------------------\n");

	print_str("Number of fast external IRQs counted: ");
	print_dec(ext_irq_4_count);
	print_str("\n");

	print_str("Number of slow external IRQs counted: ");
	print_dec(ext_irq_5_count);
	print_str("\n");

	print_str("Number of timer IRQs counted: ");
	print_dec(timer_irq_count);
	print_str("\n");

	return false;
}
