;******************************************************************************
;	MECBInitialTest09_RAM.asm
;
;	A simple 6809 CPU Card test utilising just the TMS9929A VDP Card.
;
;	This version is intended as RAM loadable code (eg. $0100 Entry).
;	Fundamentaly identical to ROM version, with removal of Vector table.
;
;	VDP defaults to base address $E080
;	e.g. If IORQ based VDP allocation, then CPU card IORQ is allocated to
;	page $E0xx and VDP address decode is based on IORQ range $80..$87
;
;	Author: Greg@DigicoolThings.com
;	Date:	Sep 2023
;
;******************************************************************************
Entry		EQU	$0100		; Code entry address
VDP		EQU	$E080		; TMS9929A Video Display Processor address
VDP_VRAM	EQU	VDP+0		; VDP VRAM access address
VDP_REGISTER	EQU	VDP+1		; VDP Register access address
;
; Main Entry Point
		ORG	Entry
; Initialise Direct Page Register for Zero page
		CLRA
		TFR	A,DP	
; Tell asm6809 what page the DP register has been set to
		SETDP	#$00
; Setup VDP Initial Settings for Registers 0 - 7
		LDX	#GraphModeRegs
		BSR	tfrAllVDPRegs
; Clear and then Setup VDP VRAM
		JSR	vramClear
		JSR	vramSetup
; Loop forever through Backdrop colors 2..15
		LDA	#1		; Initalise Backdrop color
LoopBackdrop	INCA			; Increment Backdrop color
		CMPA	#15		; Rotate through the 14 different Backdrop colors (2..15)
		BLE	SkipRst		; It's not time to reset Backdrop color
		LDA	#2		; Reset Backdrop color back to color 2
SkipRst		LDB	#7		; Write to VDP Register 7
		BSR	writeRegisterByteVDP
		LDX	#1992		; Delay approximately 2 seconds (assuming 1Mhz clock)
		JSR	delayMS		; 1992 * 1.004 + 0.003 = 1999.97ms :)
		BRA	LoopBackdrop
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
; Setup Test Pattern 0 in Pattern Table
		LDD	#$0800
		JSR	setVramWriteAddress
		LDX	#TestPattern
		LDY	#8
		BSR	tfrVramBlock
;
; Set Pattern 0 to be in all 768 Screen locations
		LDD	#$1400
		JSR	setVramWriteAddress
		CLRA	
		LDY	#768
		BSR	setVramBlock
;
; Set Color (for Patterns 0 - 7)
		LDD	#$2000
		JSR	setVramWriteAddress
		LDA	#$F4	; White (color 15) on bits, Dark Blue (color 4) off bits
		STA	VDP_VRAM
;
		RTS

delay1MS
; Function:	Delay 1ms (Approximately. Actually 1.004ms at 1Mhz clock)
; Parameters:	-
; Returns:	-
; Destroys:	X, Y
		LDX	#1		; 3 Cycles
DelayMSLoop	LDY	#123		; 4 Cycles - Assumes 1Mhz Clock
Delay1MSLoop	LEAY	-1,Y		; 5 cycles
		BNE	Delay1MSLoop	; 3 cycles
		LEAX	-1,X		; 5 cycles
		BNE	DelayMSLoop	; 3 cycles
		RTS			; 5 cycles

delayMS
; Function:	Delay X ms (Actually X * 1.004ms + 0.003ms at 1Mhz clock)
; Parameters:	X - Specifies desired delay in millseconds (note above)
; Returns:	-
; Destroys:	X, Y
		BRA	DelayMSLoop	; 3 cycles

;
; *** End of Subroutines. Data follows ***
;
; VDP Register Values for bulk initialisation of VDP Registers 0 - 7
;
GraphModeRegs	FCB	$00		; Graphics I Mode
		FCB	$C0		; Graphics I or II Mode, 8x8 Sprites, 16KB VRAM, Display Area Enabled
		FCB	$05		; Name table start address = $1400
		FCB	$80		; Color table start address = $2000
		FCB	$01		; Pattern table start address = $0800
		FCB	$20		; Sprite Attribute table start address = $1000
		FCB	$00		; Sprite Pattern table start address = $0000
		FCB	$01		; Transparent Text / Black Backdrop

TestPattern	FCB	%00000000	; Test Pattern (Letter 'A')
		FCB	%00011000
		FCB	%00100100
		FCB	%01000010
		FCB	%01111110
		FCB	%01000010
		FCB	%01000010
		FCB	%00000000
