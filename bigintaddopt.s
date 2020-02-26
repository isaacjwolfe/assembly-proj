//--------------------------------------------------------------------
// bigintadd.s                                                             
// Author: Isaac Wolfe.                                               
// netid: iwolfe                                                      
//--------------------------------------------------------------------

        .section .rodata

//--------------------------------------------------------------------

        .section .data

//--------------------------------------------------------------------

        .section .bss

//--------------------------------------------------------------------

        .section .text

        //----------------------------------------------------------- 
        // Return the larger of lLength1 and lLength2.
        //------------------------------------------------------------

        // Must be a multiple of 16
        .equ BIGINT_LARGER_STACK_BYTECOUNT, 32

        // Local variable offset
        LLARGER .req x21

        // Parameter offsets
        LLENGTH2 .req x20
        LLENGTH1 .req x19

BigInt_larger:

// Prolog and store callee saved registers
sub sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
str x30, [sp]
str x19, [sp, 8]
str x20, [sp, 16]
str x21, [sp, 24]

// Store parameters in registers
mov LLENGTH1, x0
mov LLENGTH2, x1

// long lLarger;
// if (lLength1 <= lLength2) goto else1;
cmp LLENGTH1, LLENGTH2
ble else1

// lLarger = lLength1;
// goto endif1;
mov LLARGER, LLENGTH1
b endif1

else1:
// lLarger = lLength2;
mov LLARGER, LLENGTH2

endif1:

// Epilog and return lLarger
// Restore callee-saved registers
mov x0, LLARGER
ldr x30, [sp]
ldr x19, [sp, 8]
ldr x20, [sp, 16]
ldr x21, [sp, 24]
add sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
ret

.size BigInt_larger, (. - BigInt_larger)

        //----------------------------------------------------------- 
        // Assign the sum of oAddend1 and oAddend2 to oSum.  oSum 
        // should be distinct from oAddend1 and oAddend2.  
        // Return 0 (FALSE) if an overflow occurred, 
        // and 1 (TRUE) otherwise.
        //------------------------------------------------------------
        
        // Max digits that a BigInt object can contain
        .equ MAX_DIGITS, 32768

        // Values for TRUE and FALSE
        .equ FALSE, 0
        .equ TRUE, 1

        // Must be a multiple of 16
        .equ BIGINT_ADD_STACK_BYTECOUNT, 64

        // Local variable offset
        LSUMLENGTH .req x25
        LINDEX .req x24
        ULSUM .req x23
        ULCARRY .req x22

        // Parameter offsets
        OSUM .req x21
        OADDEND2 .req x20
        OADDEND1 .req x19

        // Structure field offset
        .equ LLENGTH, 0
        .equ AULDIGITS, 8

        .global BigInt_add

BigInt_add:

// Prolog with calee saved register storing
sub sp, sp, BIGINT_ADD_STACK_BYTECOUNT
str x30, [sp]
str x19, [sp, 8]
str x20, [sp, 16]
str x21, [sp, 24]
str x22, [sp, 32]
str x23, [sp, 40]
str x24, [sp, 48]
str x25, [sp, 56]

// Store parameters in registers
mov OADDEND1, x0
mov OADDEND2, x1
mov OSUM, x2

// unsigned long ulCarry;
// unsigned long ulSum;
// long lIndex;
// long lSumLength;

// Determine the larger length.
// lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
mov x0, OADDEND1
add x0, x0, LLENGTH
ldr x0, [x0]
mov x1, OADDEND2
add x1, x1, LLENGTH
ldr x1, [x1]
bl BigInt_larger
mov LSUMLENGTH, x0 

// Clear oSum's array if necessary.
// if (oSum->lLength <= lSumLength) goto endif2;
mov x0, OSUM
add x0, x0, LLENGTH
ldr x0, [x0]
mov x1, LSUMLENGTH
cmp x0, x1
ble endif2

// memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
mov x0, OSUM
add x0, x0, AULDIGITS
mov x1, 0
mov x2, MAX_DIGITS
lsl x2, x2, 3 // multiply by 8, the size of an unsigned long
bl memset

endif2:

// Perform the addition.
// ulCarry = 0;
mov ULCARRY, 0

// lIndex = 0;
mov LINDEX, 0
        
loop1:

// if (lIndex >= lSumLength) goto endloop1;
mov x0, LINDEX
mov x1, LSUMLENGTH
cmp x0, x1
bge endloop1

//ulSum = ulCarry;
mov ULSUM, ULCARRY

//ulCarry = 0;
mov ULCARRY, 0

// ulSum += oAddend1->aulDigits[lIndex];
mov x0, OADDEND1
add x0, x0, AULDIGITS
mov x1, LINDEX
ldr x0, [x0, x1, lsl 3] // multiply index by bits
add ULSUM, ULSUM, x0


// if (ulSum >= oAddend1->aulDigits[lIndex]) goto endif3;
mov x0, OADDEND1
add x0, x0, AULDIGITS
mov x1, LINDEX
ldr x0, [x0, x1, lsl 3] // multiply index by bits
cmp ULSUM, x0
bhs endif3

// ulCarry = 1;
mov ULCARRY, 1
endif3:

// ulSum += oAddend2->aulDigits[lIndex];
mov x0, OADDEND2
add x0, x0, AULDIGITS
mov x1, LINDEX
ldr x0, [x0, x1, lsl 3]
add ULSUM, ULSUM, x0

// if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4;
mov x0, OADDEND2
add x0, x0, AULDIGITS
mov x1, LINDEX
ldr x0, [x0, x1, lsl 3] // multiply index by bits
cmp ULSUM, x0
bhs endif4

// ulCarry = 1;
mov ULCARRY, 1
endif4:

// oSum->aulDigits[lIndex] = ulSum;
mov x0, LINDEX
lsl x0, x0, 3           // multiply index by bits
mov x1, OSUM
add x1, x1, AULDIGITS
add x1, x1, x0
str ULSUM, [x1]

// lIndex++;
add LINDEX, LINDEX, 1

// goto loop1;
b loop1
endloop1:

// Check for a carry out of the last "column" of the addition.
// if (ulCarry != 1) goto endif5;
cmp ULCARRY, 1
bne endif5

// if (lSumLength != MAX_DIGITS) goto endif6;
cmp LSUMLENGTH, MAX_DIGITS
bne endif6

// return FALSE;
// restore callee saved registers
mov w0, FALSE
ldr x30, [sp]
ldr x19, [sp, 8]
ldr x20, [sp, 16]
ldr x21, [sp, 24]
ldr x22, [sp, 32]
ldr x23, [sp, 40]
ldr x24, [sp, 48]
ldr x25, [sp, 56]
add sp, sp, BIGINT_ADD_STACK_BYTECOUNT
ret
endif6:

// oSum->aulDigits[lSumLength] = 1;
mov x0, OSUM
add x0, x0, AULDIGITS
mov x1, LSUMLENGTH
lsl x1, x1, 3           // multiply index by bits
add x0, x0, x1
mov x2, 1
str x2, [x0]

// lSumLength++;
add LSUMLENGTH, LSUMLENGTH, 1
endif5:

// Set the length of the sum.
// oSum->lLength = lSumLength;
mov x0, OSUM
add x0, x0, LLENGTH
str LSUMLENGTH, [x0]

// return TRUE;
// restore callee saved registers
mov w0, TRUE
ldr x30, [sp]
ldr x19, [sp, 8]
ldr x20, [sp, 16]
ldr x21, [sp, 24]
ldr x22, [sp, 32]
ldr x23, [sp, 40]
ldr x24, [sp, 48]
ldr x25, [sp, 56]
add sp, sp, BIGINT_ADD_STACK_BYTECOUNT
ret

.size BigInt_add, (. - BigInt_add)
