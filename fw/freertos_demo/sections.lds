/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

MEM_OFFSET		= 0x00000000;
TOTAL_MEM_SIZE	= 0x00020000;
MIN_STACK_SIZE	= 0x200;

__freertos_irq_stack_top = MEM_OFFSET + TOTAL_MEM_SIZE;

MEMORY {
	mem : ORIGIN = MEM_OFFSET, LENGTH = TOTAL_MEM_SIZE
}

SECTIONS {
	.memory : {
		. = 0x000000;
		*(.text.reset_vec);
		. = 0x000010;
		*(.text.trap_vec);
		bin/freertos_demo/start.o(.text);
		*(.text.freertos_risc_v_trap_handler);
		bin/freertos_demo/FreeRTOS-Kernel/portable/GCC/RISC-V/portASM.o(*);
		*(.text);
		*(*);
		end = .;
		. = ALIGN(4);
	} > mem

	.stack :
	{
		. = ALIGN(16);
		/* __StackLimit = .; */
		. += MIN_STACK_SIZE;
		/* __StackTop = .; */
	} > mem
}
