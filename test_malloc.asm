|; !! SHOULD NOT BE SUBMITTED !!
|; test file

.include beta.uasm

|; init stack and memory allocation 
CMOVE(stack__, SP)
MOVE(SP, BP)
BR(main) 

.include malloc.asm

main:
	|; initialize the malloc system
	beta_alloc_init()

	|; put trash value in RO to see if return value of
	|; malloc is modified or not. Useless because CMALLOC()
	|; modifies R0
	CMOVE(1234, R0)

	|; tries with size 0
	|; CMALLOC(0) => returns NULL. OK
	|; HALT()

	|; allocate an array of size 5 (basic case) => OK
	CMALLOC(5)
	HALT()

	|; trying with max (16 bits constants) => returns NULL. OK
	|; CMALLOC(65535)
	|; HALT()

LONG(0xDEADCAFE)
stack__: 
	|; ...