/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

HEAP_SIZE	= 0x1000;
STACK_SIZE	= 0x1000;

MEMORY {
	/* the memory in the testbench is 128k in size;
	 * set LENGTH=96k and leave at least 32k for stack */
	mem : ORIGIN = 0x00000000, LENGTH = 0x00020000
}

SECTIONS {
	.memory : {
		. = 0x000000;
		*(.text.reset_vec);
		. = 0x000010;
		*(.text.freertos_risc_v_trap_handler);
		bin/freertos_demo/FreeRTOS-Kernel/portable/GCC/RISC-V/portASM.o(*);
		bin/freertos_demo/start.o(.text);
		*(.text);
		*(*);
		end = .;
		. = ALIGN(4);
	} > mem

	.heap :
	{
		. = ALIGN(8);
		/* __heap_start = .; */
		. += HEAP_SIZE;
		/* __heap_end = .; */
		/* _heap_end = __heap_end; */
	} > mem

	.stack :
	{
		. = ALIGN(16);
		/* __StackLimit = .; */
		. += STACK_SIZE;
		/* __StackTop = .; */
		__freertos_irq_stack_top = .;
	} > mem
}
