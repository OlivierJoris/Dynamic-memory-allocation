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

|; Following macros are based on the ones of malloc.c

|; stores in Reg[Ro] the address of another memory block
|; from memory block at Mem[pointer]
.macro block_next(pointer, Ro) ADDC(pointer, 4, Ro) LD(Ro, 0, Ro)
|; stores in Reg[Ro] the size of memory block at Mem[pointer]
.macro block_size(pointer, Ro) LD(pointer, 0, Ro)
|; stores in Reg[Ro] the address of the first word of the
|; chunk of memory of memory block at Mem[pointer]
.macro block_start(pointer, Ro) ADDC(pointer, 8, Ro)



|; Dynamically allocates an array of size n.
|; Args:
|;  - n (>0): size of the array to allocate 
|; Returns:
|;  - the address of the allocated array
malloc: 
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)
	|; Insert your malloc implementation here ....

	|; Stores registers that will be modified
	PUSH (R1) |; n

	|; Gets argument n from stack
	LD(BP, -12, R1)
	CMPLEC(R1, 0, R0)
	BT(RO, malloc_error) |; n <= 0



malloc_end:
	POP(R1)
	RTN()

|; Error in malloc
malloc_error:
	CMOVE(NULL, R0)
	RTN()



|; Free a dynamically allocated array starting at address p.
|; Args:
|;  - p: address of the dynamically allocated array
free: 
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)
	|; Insert your free implementation here ....