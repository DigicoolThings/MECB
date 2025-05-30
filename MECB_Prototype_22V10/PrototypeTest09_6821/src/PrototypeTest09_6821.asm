;******************************************************************************
;	PrototypeTest09_6821.asm
;
;	A simple Prototype Card Test (for a 6809 CPU Card).
;
;	Assumes that a 6821 PIA has been connected to the Prototype Card.
;	Uses PORTA to output an incrementing count.
;	
;	Set Entry EQU for your preferred code assembly location.
;	e.g. $0100 specified for running the code in the 2nd page of main RAM.
;	Set PIA EQU for your PIA's base address.
;	e.g. $C0E0 is for $C0 IORQ bank and $E0 I/O allocation. 
;
;	Author: Greg
;	Date:	May 2025
;
;******************************************************************************
Entry		EQU	$0100
PIA		EQU	$C0E0		; MC6821 PIA base address
PIA_PRTA	EQU	PIA		; MC6821 PIA Port A & DDR A address
PIA_CTLA	EQU	PIA+1		; MC6821 PIA Control Register A address
;
; Code Entry Point
		ORG	Entry
; Initialise PIA
		CLRA
		STA	PIA_CTLA	; Initilise PIA Control, Select DDRA
		LDA	#$FF		
		STA	PIA_PRTA	; PORTA as outputs (DDR = 1)
		LDA	#$04		
		STA	PIA_CTLA	; Now select PORTA Data Register
;
		CLRA			; Initialize Accumulator A to zero
CNTLOOP		STA	PIA_PRTA	; Output Accumulator A to PORTA
		LDX	#$FFFF		; Ultra simple delay loop!
DELAY		LEAX	-1,X		; Decrement X
		BNE	DELAY		; If not yet zero, then loop
		INCA			; Increment Accumulator A counter
		BRA	CNTLOOP		; Branch forever in our counter loop!
;
		END

