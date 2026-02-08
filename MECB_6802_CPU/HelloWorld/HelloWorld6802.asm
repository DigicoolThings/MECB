******************************************************************************
*	HelloWorld6802.asm
*
*	A simple 'Hello World' character output test.
*	For 6800 / 6802 / 6808 based system.
*	For ROM target (See Vector Table).
*	eg. $F000 - $FFFF
*
*   	For as0 Assembler.
*
*	Author: Greg
*	Date:	02/2026
*
******************************************************************************
*       OPT     l           ; Enable Listing Assembler Output
ACIA    EQU     $8008       ; MC6850 ACIA Address
ACIAtr  EQU     ACIA+1      ; ACIA Transmit / Receive Data Register
*
        ORG     $F000       ; Entry point
* Initialise 6802
Start   SEI                 ; Disable Interrupts
        LDS     #$01FF      ; Initialise Stack pointer ($01FF)
* Initialise ACIA
        LDAA    #$03        ; Reset ACIA
        STAA    ACIA
        LDAA    #$51        ; Set ACIA Control
        STAA    ACIA        ; 8 bits,2 stop bits,/16 clock,Interrupt disabled
* Output Hello string
        LDX     #Hello      ; Initialise character offset pointer
PrintLp LDAA    #$02        ; Transmit Data Register Empty flag mask
        BITA    ACIA        ; Is Transmit Data Register Empty?
        BEQ     PrintLp     ; Loop if not empty
*
        LDAA    0,X         ; Get next character to send
        BEQ     Done        ; If it's the zero string terminator, we're done!
        STAA    ACIAtr      ; Send the character
        INX                 ; Increment character offset pointer
        JMP     PrintLp     ; Loop to process next character
*
Done    JMP     Done        ; Done, so just Loop Forever!
* Return from Interrupt - default Interrupt vector
VectRtn RTI                 ; Just return from an Interrupt
* Zero Terminated string to output
Hello   FCC     'Hello 6802 World!'
        FCB     $0D,$0A,$00
*
* Vector Table for 6802 located at $FFF8 - $FFFF
    	ORG	$FFF8
	FDB	VectRtn     ; IRQ Vector
	FDB	VectRtn     ; Software Interupt Vector
	FDB	VectRtn     ; NMI Vector
	FDB	Start       ; Reset Vector
*
        END