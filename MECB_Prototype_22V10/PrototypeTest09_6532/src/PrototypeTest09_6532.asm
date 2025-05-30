;******************************************************************************
;	PrototypeTest09_6532.asm
;
;	A simple Prototype Card Test (for a 6809 CPU Card).
;
;	Assumes that a 6832 RIOT has been connected to the Prototype Card.
;	Uses PORTA to output an incrementing count.
;	
;	Set Entry EQU for your preferred code assembly location.
;	e.g. $A400 specified for running the code in the 6532's on-chip RAM.
;	Set RIOT EQU for your 6532's base address.
;	e.g. $A400 is for the AIM-65 example of $A400 - $A7FF MREQ allocation. 
;	
;	Author: Greg
;	Date:	May 2025
;
;******************************************************************************
Entry		EQU	$A400
RIOT		EQU	$A400		; 6532 RIOT base address
RIOT_PRTA	EQU	RIOT+$80	; 6532 RIOT Port A address
RIOT_DDRA	EQU	RIOT+$81	; 6532 RIOT DDR A address
RIOT_EDC	EQU	RIOT+$84	; 6532 RIOT Write Edge Detect Control
;
; Code Entry Point
		ORG	Entry
; Initialise RIOT
		CLRA
		STA	RIOT_EDC	; Disable Interrupt from PA7
		LDA	#$FF		
		STA	RIOT_DDRA	; PORTA as outputs (DDR = 1)
;
		CLRA			; Initialize Accumulator A to zero
CNTLOOP		STA	RIOT_PRTA	; Output Accumulator A to PORTA
		LDX	#$FFFF		; Ultra simple delay loop!
DELAY		LEAX	-1,X		; Decrement X
		BNE	DELAY		; If not yet zero, then loop
		INCA			; Increment Accumulator A counter
		BRA	CNTLOOP		; Branch forever in our counter loop!
;
		END

