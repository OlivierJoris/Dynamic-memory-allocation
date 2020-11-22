.include beta.uasm

|; init stack and memory allocation 
CMOVE(stack__, SP)
MOVE(SP, BP)
BR(main) 

.include malloc.asm

main:
	|; initialize the malloc system
	beta_alloc_init()
	|; allocate an array of size 5 and then free it
	CMALLOC(5)
	.breakpoint
	|;
	CMOVE(1, R1)
	ST(R1, 0, R0)
	|;
	CMOVE(2, R1)
	ST(R1, 4, R0)
	|;
	CMOVE(3, R1)
	ST(R1, 8, R0)
	|;
	CMOVE(4, R1)
	ST(R1, 12, R0)
	|;
	CMOVE(5, R1)
	ST(R1, 16, R0)
	|;
	.breakpoint
	MOVE(R0,R5)
	.breakpoint

	CMALLOC(4)
	.breakpoint
	CMOVE(10, R1)
	ST(R1, 0, R0)
	|;
	CMOVE(11, R1)
	ST(R1, 4, R0)
	|;
	CMOVE(12, R1)
	ST(R1, 8, R0)
	|;
	CMOVE(13, R1)
	ST(R1, 12, R0)
	|;
	.breakpoint
	MOVE(R0,R6)
	.breakpoint

	FREE(R5)
	.breakpoint

	FREE(R6)
	.breakpoint
	HALT()

LONG(0xDEADCAFE)
stack__: 
	|; ...