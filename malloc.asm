|; Dynamic allocation registers:
|; - Base block pointer (BBP): points to the first block
|; - Free pointer (FP): points the first free block of the free list
|; - NULL: value of the null pointer (0)
BBP = R26
FP = R25 
NULL = 0

bbp_init_val:
	LONG(0x3FFF8)

|; reset the global memory registers
.macro beta_alloc_init() LDR(bbp_init_val, BBP) MOVE(BBP, FP)
|; call malloc to get an array of size Reg[Ra]
.macro MALLOC(Ra)        PUSH(Ra) CALL(malloc, 1)
|; call malloc to get an array of size CC
.macro CMALLOC(CC)	     CMOVE(CC, R0) PUSH(R0) CALL(malloc, 1)
|; call free on the array at address Reg[Ra]
.macro FREE(Ra)          PUSH(Ra) CALL(free, 1)


|; Dynamically allocates an array of size n.
|; Args:
|;  - n (>0): size of the array to allocate 
|; Returns:
|;  - the address of the allocated array
malloc: 
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)
	|; Insert your malloc implementation here ....


|; Free a dynamically allocated array starting at address p.
|; Args:
|;  - p: address of the dynamically allocated array
free: 
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)
	|; Insert your free implementation here ....