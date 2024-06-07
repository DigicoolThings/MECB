;*****************************************************************************
;	HelloWorld.6502.asm
;
;	A simple 'Hello World' character output test.
;	For 6502 based system.
;	For ROM target (See Vector Table).
;	eg. $F000 - $FFFF
;
;	Author: Greg
;	Date:	03/06/2024
;
;*****************************************************************************
        .target "6502"      ; RetroAssembler CPU definition
        .format "bin"       ; RetroAssembler output type definition
ACIA    .equ    $E008       ; MC6850 ACIA Address
ACIAtr  .equ    ACIA+1      ; ACIA Transmit / Receive Data Register
;
Start   .org    $F000       ; Entry point
; Initialise 6502
        sei                 ; Disable Interrupts
        cld                 ; Clear Decimal flag (Binary mode)
        ldx     $FF         ; Initialise Stack pointer ($01FF)
        txs
; Initialise ACIA
        lda     #$03        ; Reset ACIA
        sta     ACIA
        lda     #$51        ; Set ACIA Control
        sta     ACIA        ; 8 bits,2 stop bits,/16 clock,Interrupt disabled
; Output Hello string
        ldx     #$00        ; Initialise character offset pointer
PrintLp lda     #$02        ; Transmit Data Register Empty flag mask
        bit     ACIA        ; Is Transmit Data Register Empty?
        beq     PrintLp     ; Loop if not empty
;
        lda     Hello,x     ; Get next character to send
        beq     Done        ; If it's the zero string terminator, we're done!
        sta     ACIAtr      ; Send the character
        inx                 ; Increment character offset pointer
        jmp     PrintLp     ; Loop to process next character
;
Done    jmp     Done        ; Done, so just Loop Forever!
; Return from Interrupt - default Interrupt vector
VectRtn rti                 ; Just return from an Interrupt
; Zero Terminated string to output
Hello   .textz  "\r\nHello 6502 World!\r\n"
;
; Vector Table for 6502 located at $FFFA - $FFFF
        .org    $FFFA
        .word   VectRtn     ; BRK/IRQ Vector
        .word   Start       ; Reset Vector
        .word   VectRtn     ; NMI Vector
        .end