;*****************************************************************************
;	HelloWorld6802.asm
;
;	A simple 'Hello World' character output test,
;   with a simple RAM Write / Read check.
;
;	For 6800 / 6802 / 6808 based system.
;	For ROM target (See Vector Table).
;	eg. $F000 - $FFFF
;
;   For asl Assembler.
;
;	Author: Greg
;	Date:	05/2026
;
;*****************************************************************************
        CPU     6800        ; Specify MC6800 processor code (asl Assembler)
;
ACIA    EQU     $E008       ; MC6850 ACIA Address
ACIAtr  EQU     ACIA+1      ; ACIA Transmit / Receive Data Register
;
        ORG     $F000       ; Entry point
; Initialise 6802
Start   SEI                 ; Disable Interrupts
        LDS     #$01FF      ; Initialise Stack pointer ($01FF)
; Initialise ACIA
        LDAA    #$03        ; Reset ACIA
        STAA    ACIA
        LDAA    #$51        ; Set ACIA Control
        STAA    ACIA        ; 8 bits,2 stop bits,/16 clock,Interrupt disabled
; Output Hello string
        LDX     #Hello      ; Initialise character offset pointer
        BSR     PRNTMSG     ; Print the message
; Now Check RAM Write / Read
CHKRAM1 LDAA    #$55        ; Check we can store a $55 pattern
        STAA    $00         ; Store the byte in RAM
        LDAA    $00         ; Read the byte back from RAM
        CMPA    #$55        ; Did we read back the $55 pattern?
        BEQ     RAM1OKM     ; Pattern matched, Okay!
        LDX     #RAM1NOK    ; Pattern didn't matched, Fail!
        BSR     PRNTMSG
        BRA     CHKRAM2
RAM1OKM LDX     #RAM1OK
        BSR     PRNTMSG
CHKRAM2 LDAA    #$AA        ; Check we can store a $AA pattern
        STAA    $00         ; Store the byte in RAM
        LDAA    $00         ; Read the byte back from RAM
        CMPA    #$AA        ; Did we read back the $AA pattern?
        BEQ     RAM2OKM     ; Pattern matched, Okay!
        LDX     #RAM2NOK    ; Pattern didn't matched, Fail!
        BSR     PRNTMSG
        BRA     THEEND 
RAM2OKM LDX     #RAM2OK
        BSR     PRNTMSG
;
THEEND  JMP     THEEND      ; Done, so just Loop Forever!
;
; PRNTMSG Subroutine
PRNTMSG LDAA    #$02        ; Transmit Data Register Empty flag mask
        BITA    ACIA        ; Is Transmit Data Register Empty?
        BEQ     PRNTMSG     ; Loop if not empty
;
        LDAA    0,X         ; Get next character to send
        BEQ     PRNTRTN     ; If it's the zero string terminator, we're done!
        STAA    ACIAtr      ; Send the character
        INX                 ; Increment character offset pointer
        BRA     PRNTMSG     ; Loop to process next character
PRNTRTN RTS                 ; Return to caller
;
; Return from Interrupt - default Interrupt vector
VectRtn RTI                 ; Just return from an Interrupt
;
; Zero Terminated string to output
Hello   FCC     'Hello 6802 World.'
        FCB     $0D,$0A,$00
RAM1OK  FCC     'RAM Check ($55) Ok!'
        FCB     $0D,$0A,$00
RAM1NOK FCC     'RAM Check ($55) Fail!'
        FCB     $0D,$0A,$00
RAM2OK  FCC     'RAM Check ($AA) Ok!'
        FCB     $0D,$0A,$00
RAM2NOK FCC     'RAM Check ($AA) Fail!'
        FCB     $0D,$0A,$00
;
; Vector Table for 6802 located at $FFF8 - $FFFF
    	ORG	    $FFF8
	    FDB	    VectRtn     ; IRQ Vector
	    FDB	    VectRtn     ; Software Interupt Vector
	    FDB	    VectRtn     ; NMI Vector
	    FDB 	Start       ; Reset Vector
;
        END