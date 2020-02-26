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
        .equ LLARGER, 8

        // Parameter offsets
        .equ LLENGTH2, 16
        .equ LLENGTH1, 24

BigInt_larger:

// Prolog
sub sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
str x30, [sp]
str x0, [sp, LLENGTH1]
str x1, [sp, LLENGTH2]

// long lLarger;
// if (lLength1 <= lLength2) goto else1;
ldr x0, [sp, LLENGTH1]
ldr x1, [sp, LLENGTH2]
cmp x0, x1
ble else1

// lLarger = lLength1;
// goto endif1;
ldr x0, [sp, LLENGTH1]
str x0, [sp, LLARGER] 
b endif1

else1:
// lLarger = lLength2;
ldr x0, [sp, LLENGTH2]
str x0, [sp, LLARGER]

endif1:

// Epilog and retuen lLarger
ldr x0, [sp, LLARGER]
ldr x30, [sp]
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
        .equ LSUMLENGTH, 8
        .equ LINDEX, 16
        .equ ULSUM, 24
        .equ ULCARRY, 32

        // Parameter offsets
        .equ OSUM, 40
        .equ OADDEND2, 48
        .equ OADDEND1, 56

        // Structure field offset
        .equ LLENGTH, 0
        .equ AULDIGITS, 8


        .global BigInt_add

BigInt_add:

// Prolog
sub sp, sp, BIGINT_ADD_STACK_BYTECOUNT
str x30, [sp]
str x0, [sp, OADDEND1]
str x1, [sp, OADDEND2]
str x2, [sp, OSUM]

// unsigned long ulCarry;
// unsigned long ulSum;
// long lIndex;
// long lSumLength;

// Determine the larger length.
// lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
ldr x0, [sp, OADDEND1]
add x0, x0, LLENGTH
ldr x0, [x0]
ldr x1, [sp, OADDEND2]
add x1, x1, LLENGTH
ldr x1, [x1]
bl BigInt_larger
str x0, [sp, LSUMLENGTH]

// Clear oSum's array if necessary.
// if (oSum->lLength <= lSumLength) goto endif2;
ldr x0, [sp, OSUM]
add x0, x0, LLENGTH
ldr x0, [x0]
ldr x1, [sp, LSUMLENGTH]
cmp x0, x1
ble endif2

// memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
ldr x0, [sp, OSUM]
add x0, x0, AULDIGITS
mov x1, 0
mov x2, MAX_DIGITS
lsl x2, x2, 3 // multiply by 8, the size of an unsigned long
bl memset

endif2:

// Perform the addition.
// ulCarry = 0;
mov x0, 0
str x0, [sp, ULCARRY]

// lIndex = 0;
mov x0, 0
str x0, [sp, LINDEX]
        
loop1:

// if (lIndex >= lSumLength) goto endloop1;
ldr x0, [sp, LINDEX]
ldr x1, [sp, LSUMLENGTH]
cmp x0, x1
bge endloop1

//ulSum = ulCarry;
ldr x0, [sp, ULCARRY]
str x0, [sp, ULSUM]

//ulCarry = 0;
mov x0, 0
str x0, [sp, ULCARRY]

// ulSum += oAddend1->aulDigits[lIndex];
ldr x0, [sp, OADDEND1]
add x0, x0, AULDIGITS
ldr x1, [sp, LINDEX]
ldr x0, [x0, x1, lsl 3] // multiply index by bits
ldr x1, [sp, ULSUM]
add x1, x1, x0
str x1, [sp, ULSUM]

// if (ulSum >= oAddend1->aulDigits[lIndex]) goto endif3;
ldr x0, [sp, OADDEND1]
add x0, x0, AULDIGITS
ldr x1, [sp, LINDEX]
ldr x0, [x0, x1, lsl 3] // multiply index by bits
ldr x1, [sp, ULSUM]
cmp x1, x0
bhs endif3

// ulCarry = 1;
mov x0, 1
str x0, [sp, ULCARRY]
endif3:

// ulSum += oAddend2->aulDigits[lIndex];
ldr x0, [sp, OADDEND2]
add x0, x0, AULDIGITS
ldr x1, [sp, LINDEX]
ldr x0, [x0, x1, lsl 3]
ldr x1, [sp, ULSUM]
add x1, x1, x0
str x1, [sp, ULSUM]

// if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4;
ldr x0, [sp, OADDEND2]
add x0, x0, AULDIGITS
ldr x1, [sp, LINDEX]
ldr x0, [x0, x1, lsl 3] // multiply index by bits
ldr x1, [sp, ULSUM]
cmp x1, x0
bhs endif4


// ulCarry = 1;
mov x0, 1
str x0, [sp, ULCARRY]
endif4:

// oSum->aulDigits[lIndex] = ulSum;
ldr x0, [sp, LINDEX]
lsl x0, x0, 3           // multiply index by bits
ldr x1, [sp, OSUM]
add x1, x1, AULDIGITS
add x1, x1, x0
ldr x2, [sp, ULSUM]
str x2, [x1]

// lIndex++;
ldr x0, [sp, LINDEX]
add x0, x0, 1
str x0, [sp, LINDEX]

// goto loop1;
b loop1
endloop1:

// Check for a carry out of the last "column" of the addition.
// if (ulCarry != 1) goto endif5;
ldr x0, [sp, ULCARRY]
cmp x0, 1
bne endif5

// if (lSumLength != MAX_DIGITS) goto endif6;
ldr x0, [sp, LSUMLENGTH]
cmp x0, MAX_DIGITS
bne endif6

// return FALSE;
mov w0, FALSE
ldr x30, [sp]
add sp, sp, BIGINT_ADD_STACK_BYTECOUNT
ret
endif6:

// oSum->aulDigits[lSumLength] = 1;
ldr x0, [sp, OSUM]
add x0, x0, AULDIGITS
ldr x1, [sp, LSUMLENGTH]
lsl x1, x1, 3           // multiply index by bits
add x0, x0, x1
mov x2, 1
str x2, [x0]

// lSumLength++;
ldr x0, [sp, LSUMLENGTH]
add x0, x0, 1
str x0, [sp, LSUMLENGTH]
endif5:

// Set the length of the sum.
// oSum->lLength = lSumLength;
ldr x0, [sp, OSUM]
add x0, x0, LLENGTH
ldr x1, [sp, LSUMLENGTH]
str x1, [x0]

// return TRUE;
mov w0, TRUE
ldr x30, [sp]
add sp, sp, BIGINT_ADD_STACK_BYTECOUNT
ret

.size BigInt_add, (. - BigInt_add)
