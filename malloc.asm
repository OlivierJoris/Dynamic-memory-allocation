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
|; from header of memory block at Mem[Reg[Ra]]
.macro block_next_get(Ra, Ro) LD(Ra, 4, Ro)
|; stores in Reg[Ro] the size of memory block at Mem[Reg[Ra]]
.macro block_size_get(Ra, Ro) LD(Ra, 0, Ro)
|; stores in Reg[Ro] the address of the first word of the
|; chunk of memory of memory block at Mem[Reg[Ra]]
.macro block_start(Ra, Ro) ADDC(Ra, 8, Ro)

|; stores content of Reg[Rb] as next block address of
|; block at Mem[Reg[Ra]]
.macro block_next_set(Ra, Rb) ST(Rb, 4, Ra)
|; stores content of Reg[Rb] as block size of block at Mem[Reg[Ra]]
.macro block_size_set(Ra, Rb) ST(Rb, 0, Ra)

|; Try to merge two given blocks if they are adjacents to increase the size
|; of the free blocks
|; Args:
|;  - block Pointer to the first block to merge
|;  - next Pointer to the second block to merge
|; Returns:
|;  - 0 if block and next are not adjacents
|;  - Else, 1
try_merge_next:
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)

	|; Push registers that will be used to avoid overwritten their previous 
	|; values.
	PUSH(R1) |; block
	PUSH(R2) |; next
	PUSH(R3) |; curr_size

	|; Gets arguments from the stack.
	LD(BP, -12, R1)          |; block
	LD(BP, -16, R2)          |; next

	|; Gets the current size of the block and check if it is adjacent to next.
	block_size_get(R1, R3)   |; R3 <- block_size(block)
	ADDC(R3, 8, R0)          |; R0 <- curr_size + 2
	ADD(R1, R0, R0)          |; R0 <- block + curr_size + 2 
	CMPEQ(R0, R2, R0)        |; R0 =? next
	BF(R0, try_merge_next_error) |; Branch to handle error if not adjacents.

	|; block and next are adjacent -> merges them.
	ADDC(R3, 2, R0)          |; R0 <- curr_size + 2
	block_size_get(R2, R3)   |; R3 <- block_size(next)
	ADD(R0, R3, R0)          |; R0 <- curr_size + 2 + block_size(next)
	block_size_set(R1, R0)   |; block_size(block) <- curr_size + 2  
							 |; + block_size(next)

	block_next_get(R2, R0)   |; R0 <- block_next(next)
	block_next_set(R1, R0)   |; block_next(block) <- block_next(next)
	CMOVE(1, R0)             |; Updates the return value.
	BR(try_merge_next_end)

try_merge_next_error:
	CMOVE(0, R0)             |; Updates the return value.
 
try_merge_next_end:
	|; Retrieves values for the modified register and returns.
	POP(R3) POP(R2) POP(R1)
	POP(BP) POP(LP)
	RTN()


|; Checks if a given block can hold a given space.
|; Updates the free list if the block if valid.
|; Split if necessary the given block if its size exceeds the
|;   given size.
|; Args:
|;  - n Requested size
|;  - curr Pointer to header of current block
|;  - prev Pointer to header of previous block (may be NULL)
|; Returns:
|;  - 1 if the block was used
|;  - Else, 0
try_use_block:
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)

	|; stores registers that will be used to load args
	PUSH(R1) PUSH(R2) PUSH(R3)
	|; stores registers that will be modified
	PUSH(R4) PUSH(R5) PUSH(R6) PUSH(R7)

	|; gets arguments from stack
	LD(BP, -12, R1) |; n
	LD(BP, -16, R2) |; curr
	LD(BP, -20, R3) |; prev

	|; sets registers
	block_next_get(R2, R4) 			|; R4 <- next
	block_size_get(R2, R5) 			|; R5 <- block_size(curr)
	ADDC(R1, 2, R6)					|; R6 <- n+2

	|; checks if block_size(curr) is larger than n
	CMPLE(R6, R5, R0) 				|; R5 >= R6 <=> R6 <= R5
	BF(R0, try_use_block_same_size)
	MULC(R6, 4, R0)					|; memory word = 4 bytes
	ADD(R2, R0, R7) 				|; R7 <- new_block
	block_next_set(R7, R4)			|; set block next of new block
	SUB(R5, R6, R0)
	block_size_set(R7, R0)			|; set block size of new block
	MOVE(R7, R4)					|; next <- new_block
	BR(try_use_block_updates)

try_use_block_same_size:
	|; block_size(curr) ?= n
	CMPEQ(R5, R1, R0)
	BF(R0, try_use_block_smaller)

try_use_block_updates:
	|; removes block from free list & updates header
	block_size_set(R2, R1) 			|; size curr = n
	CMOVE(NULL, R0)
	block_next_set(R2, R0) 			|; next curr = NULL
	CMPEQC(R3, NULL, R0)
	BT(R0, try_use_block_set_fp)
	block_next_set(R3, R4)
	CMOVE(1, R0)
	BR(try_use_block_end)

try_use_block_set_fp:
	MOVE(R4, FP)
	CMOVE(1, R0)
	BR(try_use_block_end)

try_use_block_smaller:
	|; block_size(curr) < n
	CMOVE(0, R0)

try_use_block_end:
	POP(R7) POP(R6) POP(R5) POP(R4)
	POP(R3) POP(R2) POP(R1)
	POP(BP) POP(LP)
	RTN()


|; Dynamically allocates an array of size n.
|; Args:
|;  - n (>0): size of the array to allocate 
|; Returns:
|;  - the address of the allocated array
malloc: 
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)
	|; Insert your malloc implementation here ....

	|; stores registers that will be modified
	PUSH(R1) |; n
	PUSH(R2) |; prev
	PUSH(R3) |; curr
	PUSH(R4) |; n_items
	PUSH(R5) |; new_bbp
	PUSH(R6) |; first condition
	PUSH(R7) |; second condition

	|; gets argument n from stack
	LD(BP, -12, R1)
	CMPLEC(R1, 0, R0)
	BT(R0, malloc_error) |; n <= 0

	|; sets pointers prev and curr
	CMOVE(NULL, R2)
	MOVE(FP, R3)

malloc_loop:
	CMPEQC(R3, NULL, R0)
	BT(R0, malloc_no_valid_block)
	|; push arguments before calling try_use_block
	PUSH(R2)
	PUSH(R3)
	PUSH(R1)
	CALL(try_use_block, 3)
	CMPEQC(R0, 1, R0)
	BF(R0, malloc_loop_next_iteration)
	block_start(R3, R0)
	BR(malloc_end)

malloc_loop_next_iteration:
	|; modifies registers for next iteration
	MOVE(R3, R2)			|; pev = curr
	block_next_get(R3, R3)	|; curr = block_next(curr)
	BR(malloc_loop)

malloc_no_valid_block:
	|; need to create a new block
	ADDC(R1, 2, R4)
	MULC(R4, 4, R4)			|; memory word = 4 bytes
	SUB(BBP, R4, R5)
	CMPLT(R5, SP, R6)
	CMPLE(BBP, R5, R7)
	OR(R6, R7, R0)
	BT(R0, malloc_error)
	SUB(BBP, R4, BBP)
	CMOVE(NULL, R0)
	block_next_set(BBP, R0)
	block_size_set(BBP, R1)
	block_start(BBP, R0)
	BR(malloc_end)

malloc_error:
	CMOVE(NULL, R0)

malloc_end:
	POP(R7) POP(R6) POP(R5) POP(R4)
	POP(R3) POP(R2) POP(R1)
	POP(BP) POP(LP)
	RTN()


|; Free a dynamically allocated array starting at address p.
|; Args:
|;  - p: address of the dynamically allocated array
free: 
	PUSH(LP) PUSH(BP)
	MOVE(SP, BP)
	|; Insert your free implementation here ....

	|; Push registers that will be used to avoid overwritten their previous 
	|; values.
	PUSH(R1) |; p
	PUSH(R2) |; prev
	PUSH(R3) |; curr
	PUSH(R4) |; freed
	PUSH(R5) |; first part of the loop guardian
	PUSH(R6) |; second part of the loop guardian

	LD(BP, -12, R1)    |; Gets p from the stack.
	CMPLT(R1, BBP, R0) |; Checks for invalid memory location.
	BT(R0, free_end)   |; If invalid -> returns

	|; Initializes pointers.
	CMOVE(NULL, R2)    |; R2 <- NULL
	MOVE(FP, R3)       |; R3 <- FP

free_find_insertion_point:
	|; Stores the stop condition (negation of the guardian) of the loop in R0.
	CMPEQC(R3, NULL, R5)     |; R5 <- curr ?= null
	CMPLE(R1, R3, R6)        |; R6 <- p <=? curr
	OR(R5, R6, R0)           |; R0 <- (curr == null or p <= curr)
							 
	|; Exits the loop if an insertion point has been found, else skips blocks 
	|; until finding it
	BT(R0, free_update_list) 
	MOVE(R3, R2)                  |; R2 <- curr
	block_next_get(R3, R3)        |; R3 <- block_next(curr)
	BR(free_find_insertion_point) |; Branch to loop until finding the insertion 
					              |; point.

free_update_list:
    |; Inserts freed block in the right place in the free list.
	SUBC(R1, 8, R4)          |; freed <- p - 2
	block_next_set(R4, R3)   |; block_next(freed) <- curr

	PUSH(R3) PUSH(R4)        |; Push the arguments of try_merge_next on the 
							 |; stack (curr and freed in this order).
	CALL(try_merge_next, 2)  |; Call the function with the arguments previously 
	                         |; pushed on the stack.
	CMPEQC(R2, NULL, R0)     |; R0 <- prev ?= null 
	BT(R0, free_prev_null)            

	block_next_set(R2, R4)   |; block_next(prev) <- freed
	PUSH(R4) PUSH(R2)        |; Push the arguments of try_merge_next on the 
							 |; stack (freed and prev in this order).
	CALL(try_merge_next, 2)  |; Call the function with the arguments previously 
	                         |; pushed on the stack.
	BR(free_end)

free_prev_null:
	MOVE(R4, FP) |; FP <- freed

free_end:
	|; Retrieves values for the modified register and returns.
	POP(R6) POP(R5) POP(R4)
	POP(R3) POP(R2) POP(R1)
	POP(BP)
	POP(LP)
	RTN()
