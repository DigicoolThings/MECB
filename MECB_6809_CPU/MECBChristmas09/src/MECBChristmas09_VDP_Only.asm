;******************************************************************************
;	MECBChristmas09_VDP_Only.asm
;
;	A simple 6809 test for the MECB TMS9929A VDP Card.
;
;	This version is intended as RAM loadable code (eg. $0100 Entry).
;	Uses TMS9929A VDP Card with 6809 CPU Card.
;
;	Image based on the CreatiVison Christmas Demo (by Kurt Woloch),
;	which was written in 6502 code for the CreatiVision platform.
;
;	VDP defaults to base address $E080
;	e.g. If IORQ based VDP allocation, then CPU card IORQ is allocated to
;	page $E0xx and VDP address decode is based on IORQ range $80..$87
;
;	Author: Greg@DigicoolThings.com
;	Date:	Sep 2023
;
;******************************************************************************
Entry		EQU	$0100	; Code entry address (Zero page reserved for storage)
VDP 		EQU	$E080	; TMS9929A Video Display Processor address
VDP_VRAM	EQU	VDP+0	; VDP VRAM access address
VDP_REGISTER	EQU	VDP+1	; VDP Register access address
;
; Main Entry Point
		ORG	Entry
		CLRA		; Initialise Direct Page Register for Zero page
		TFR	A,DP	
; Tell asm6809 what page the DP register has been set to
		SETDP	#$00
; Setup VDP Initial Settings for Registers 0 - 7
		LDX	#GraphModeRegs
		BSR	tfrAllVDPRegs
; Clear and then Setup VDP VRAM
		JSR	vramClear
		JSR	vramSetup
; Now Enable Display
		LDA	#Reg1DspEn	; Update Register 1 to turn on Display Enable
		LDB	#1		; Write to VDP Register 1
		BSR	writeRegisterByteVDP
;
; Loop Forever
LoopForever	BRA	LoopForever
;
; *** End of Mainline. Subroutines follow ***
;
setVramReadAddress
; Function:	Setup VRAM Address for subsequent VRAM read
; Parameters:	D - VRAM address
; Returns:	-
; Destroys:	A
		ANDA	#$3F
		STB	VDP_REGISTER	; Store low byte of address
		STA	VDP_REGISTER	; Store masked high byte of address
		RTS

setVramWriteAddress
; Function:	Setup VRAM Address for subsequent VRAM write
; Parameters:	D - VRAM address
; Returns:	-
; Destroys:	A
		ANDA	#$3F
		ORA	#$40
		STB	VDP_REGISTER	; Store low byte of address
		STA	VDP_REGISTER	; Store masked high byte of address
		RTS

writeRegisterByteVDP
; Function:	Write a data byte into a specified VDP register
; Parameters:	A - Data Byte
;		B - Register number
; Returns:	-
; Destroys:	B
		ANDB	#$07
		ORB	#$80
		STA	VDP_REGISTER	; Store data byte
		STB	VDP_REGISTER	; Store masked register number
		RTS

readStatusByteVDP
; Function:	Read the VDP status byte
; Note:		Routine intended for functional documentaion only
;		i.e. Just directly inline implement: LDA VDP_REGISTER
; Parameters:	-
; Returns:	A = Status Byte
; Destroys:	A
		LDA	VDP_REGISTER
		RTS

readVramByteVDP
; Function:	Read byte from current VRAM read address
; Note:		Routine intended for functional documentaion only
;		i.e. Just directly inline implement: LDA VDP_VRAM
; Parameters:	-
; Returns:	A = VRAM Byte read
; Destroys:	A
		LDA	VDP_VRAM
		RTS

writeVramByteVDP
; Function:	Write byte to current VRAM write address
; Note:		Routine intended for functional documentaion only
;		i.e. Just directly inline implement: STA VDP_VRAM
; Parameters:	A - VRAM Byte to write
; Returns:	-
; Destroys:	-
		STA	VDP_VRAM
		RTS

tfrAllVDPRegs
; Function:	Write block of 8 bytes to the VDP registers
; Parameters:	X - Points to address of 8 byte register set
; Returns:	-
; Destroys:	A, B, X
		LDB	#$80		; Initialise to register zero
LoadRegLoop	LDA	,X+		; Load register data pointed to by X and increment X
		STA	VDP_REGISTER	; Store data byte
		STB	VDP_REGISTER	; Store register number
		INCB			; Point to next register
		CMPB	#$88		; Have we done all 8 registers?
		BNE	LoadRegLoop	; No, do next register
		RTS

setVramBlock
; Function:	Write a specified byte to a block of VRAM bytes
; Parameters:	A - Byte to write
;		Y - Count of bytes to write
; Returns:	-
; Destroys:	A, Y
SetVramLoop	STA	VDP_VRAM
		LEAY	-1,Y
		BNE	SetVramLoop
		RTS

tfrVramBlock
; Function:	Write block of bytes to VRAM
; Parameters:	X - Points to address of bytes to write to VRAM
;		Y - Count of bytes to write
; Returns:	-
; Destroys:	A, X, Y
TfrVramLoop	LDA	,X+		; Load VRAM data pointed to by X and increment X
		STA	VDP_VRAM
		LEAY	-1,Y
		BNE	TfrVramLoop
		RTS

vramClear
; Function:	Clear full 16KB of VDP VRAM memory
; Parameters:	-
; Returns:	-
; Destroys:	A, B, Y
		LDD	#$0000
		JSR	setVramWriteAddress
		CLRA	
		LDY	#16384
		BSR	setVramBlock
		RTS

vramSetup
; Function:	Setup VDP VRAM Tables
; Parameters:	-
; Returns:	-
; Destroys:	A, B, X, Y
;
; Transfer Pattern Table to VRAM
		LDD	#$0000
		JSR	setVramWriteAddress
		LDX	#PatternTable
		LDY	#$1800
		BSR	tfrVramBlock
;
; Setup Name Table to be three times 00 through FF (total 768 Screen locations)
		LDD	#$1800
		JSR	setVramWriteAddress
		CLRA	
		LDY	#768
vramNameLoop	STA	VDP_VRAM
		INCA
		LEAY	-1,Y
		BNE	vramNameLoop
;
; Transfer Color Table to VRAM
		LDD	#$2000
		JSR	setVramWriteAddress
		LDX	#ColorTable
		LDY	#$1800
		BSR	tfrVramBlock
;
		RTS
;
; *** End of Subroutines. Data follows ***
;
; VDP Register Values for bulk initialisation of VDP Registers 0 - 7
;
GraphModeRegs	FCB	$02		; Graphics II Mode
		FCB	$82		; Graphics I or II Mode, 16x16 Sprites, 16KB VRAM, Display Area & Interrupts Disabled
		FCB	$06		; Name table start address = 06 * $0400 = $1800
		FCB	$FF		; Color table start address = $2000 (Reg3 = $FF when in Graphics II Mode)
		FCB	$03		; Pattern table start address = $0000 (Reg4 = $03 when in Graphics II Mode)
		FCB	$36		; Sprite Attribute table start address = $36 * $80 = $1B00
		FCB	$07		; Sprite Pattern table start address = $07 * $0800 = $3800
		FCB	$01		; Transparent Text / Black Backdrop
;
Reg1IntDspEn	EQU	$E2		; Register 1 value above, but with both Display Area & Interrupts Enabled
Reg1DspEn	EQU	$C2		; Register 1 value above, but with both Display Area Enabled (Interrupts Disabled)
;
; VDP VRAM Table data includes
; 
		INCLUDE	"src\\PatternTable.asm"
;
		INCLUDE	"src\\ColorTable.asm"
;