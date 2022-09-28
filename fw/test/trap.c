// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"

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
	else if(mepc == &misalign_j_1 && mcause == 0 && mtval == &misalign_j_1_dst+1)
		return true;

	return false;
}
