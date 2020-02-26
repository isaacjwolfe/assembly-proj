//--------------------------------------------------------------------
// mywc.s                                                             
// Author: Isaac Wolfe.                                               
// netid: iwolfe                                                      
//--------------------------------------------------------------------

        .section .rodata
printfFormatStr:
        .string "%7ld %7ld %7ld\n",


        .section .data
lLineCount: .quad 0
lWordCount: .quad 0
lCharCount: .quad 0
iInWord: .word 0

//--------------------------------------------------------------------

        .section .bss
iChar:
        .skip 4

//--------------------------------------------------------------------

        .section .text

        //----------------------------------------------------------- 
        // Write to stdout counts of how many lines, words, and
        // characters are in stdin. A word is a sequence of
        // non-whitespace characters. Whitespace is defined by the
        // isspace() function. Return 0.
        //------------------------------------------------------------

        // Must be a multiple of 16
        .equ MAIN_STACK_BYTECOUNT, 16

        // variables for TRUE, FALSE, and EOF
        .equ FALSE, 0
        .equ TRUE, 1
        .equ EOF, -1
        
        .global main

main:
        // prolog
        sub sp, sp, MAIN_STACK_BYTECOUNT
        str x30, [sp]

loop1:	

        // if ((iChar = getchar()) == EOF) goto endloop1;
        bl getchar
        adr x1, iChar
        str w0, [x1]
        cmp w0, EOF
        beq endloop1

        // lCharCount++;
        adr x1, lCharCount
        ldr x0, [x1]
        add x0, x0, 1
        str x0, [x1]

        // if (!isspace(iChar)) goto else1; 
        adr x1, iChar
        ldr w0, [x1]
        bl isspace
        cmp w0, FALSE
        beq else1

        // if (!iInWord) go to endif2;
        adr x0, iInWord
        ldr w0, [x0]
        cmp w0, FALSE
        beq endif2

        // lWordCount++;
        adr x1, lWordCount
        ldr x0, [x1]
        add x0, x0, 1
        str x0, [x1]

        // iInWord = FALSE;
        mov w1, FALSE
        adr x0, iInWord
        str w1, [x0]

endif2:
        // goto endif1
        b endif1

else1:
        // if (iInWord) goto endif1;
        adr x0, iInWord
        ldr w0, [x0]
        cmp w0, TRUE
        beq endif1

        // iInWord = TRUE;
        mov w1, TRUE
        adr x0, iInWord
        str w1, [x0]

endif1:
        // if (iChar != '\n') goto endif3;
        adr x0, iChar
        ldr w0, [x0]
        cmp w0, '\n'
        bne endif3

        // lLineCount++;
        adr x1, lLineCount
        ldr x0, [x1]
        add x0, x0, 1
        str x0, [x1]

endif3:
        b loop1

endloop1:
        // if (!iInWord) goto endif4;
        adr x0, iInWord
        ldr w0, [x0]
        cmp w0, FALSE
        beq endif4

        // lWordCount++;
        adr x1, lWordCount
        ldr x0, [x1]
        add x0, x0, 1
        str x0, [x1]

endif4:

	// printf("%7ld %7ld %7ld\n", lLineCount, 
        // lWordCount, lCharCount);
        adr x0, printfFormatStr
        adr x1, lLineCount
        ldr x1, [x1]
        adr x2, lWordCount
        ldr x2, [x2]
        adr x3, lCharCount
        ldr x3, [x3]
        bl printf

	// Epilog and return 0;
        mov w0, 0
        ldr x30, [sp]
        add sp, sp, MAIN_STACK_BYTECOUNT
        ret

.size main, (. -main)
