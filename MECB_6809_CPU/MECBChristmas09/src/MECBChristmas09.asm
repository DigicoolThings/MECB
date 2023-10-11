;******************************************************************************
;	MECBChristmas09.asm
;
;	A simple 6809 test for the MECB Motorola I/O + Sound Card,
;	utilised with the MECB TMS9929A VDP Card.
;
;	This version is intended as RAM loadable code (eg. $0100 Entry).
;	Uses TMS9929A and MC6821 PIA Port B interfaced SN76489 Sound.
;
;	Based on the CreatiVison Christmas Demo (by Kurt Woloch), which was
;	written in 6502 assembly code for the CreatiVision platform.
;
;	VDP defaults to base address $E080
;	PIA defaults to base address $E010
;	e.g. If IORQ based VDP allocation, then CPU card IORQ is allocated to
;	page $E0xx and VDP address decode is based on IORQ range $80..$87
;	and PIA address decode is based on IORQ range $10..$17
;
;	Author: Greg@DigicoolThings.com
;	Date:	Sep 2023
;
;******************************************************************************
Entry		EQU	$0100	; Code entry address (Zero page reserved for storage)
VDP 		EQU	$E080	; TMS9929A Video Display Processor address
VDP_VRAM	EQU	VDP+0	; VDP VRAM access address
VDP_REGISTER	EQU	VDP+1	; VDP Register access address
PIA		EQU	$E010	; MC6821 PIA base address
PIA_PRTB	EQU	PIA+2	; MC6821 PIA Port B & DDR B address
PIA_CTLB	EQU	PIA+3	; MC6821 PIA Control Register B address 
MONITR		EQU	8	; ASSIST09 Entry Service
VCTRSWP		EQU	9	; ASSIST09 Vector Swap Service
IRQ_CODE	EQU	12	; IRQ Appendage Swap Function Code
;
; Zero page Storage Location Equates
;
Temp		EQU	$80	; This location for temporary byte storage.
DecayCount 	EQU	$81	; This location holds Frame Count until next Note plays.
PSGVolume 	EQU	$82 	; $82 for Tone 1, $83 for Tone 2 and $84 for Tone 3
				; - These locations hold the current volume for each Tone
				;   Generator and gets decremented by 1 per frame.
PSGNote		EQU	$85	; $85 for Tone 1, $86 for Tone 2 and $87 for Tone 3
				; - These locations hold the current note byte for each Tone
				;   Generator.
SoundByteOfs	EQU	$88	; $88 through $89 - 16 bit Offset into the SouundByteTable melody data.
;
; Main Entry Point
		ORG	Entry
		CLRA		; Initialise Direct Page Register for Zero page
		TFR	A,DP	
; Tell asm6809 what page the DP register has been set to
		SETDP	#$00
; Setup VDP Initial Settings for Registers 0 - 7
		LDX	#GraphModeRegs
		LBSR	tfrAllVDPRegs
; Clear and then Setup VDP VRAM
		JSR	vramClear
		JSR	vramSetup
; Now Enable Display
		LDA	#Reg1DspEn	; Update Register 1 to turn on Display Enable
		LDB	#1		; Write to VDP Register 1
		BSR	writeRegisterByteVDP
; Setup PIA Port B for Sound ouput
		LDA 	#$22		; Select DDR Register B
		STA 	PIA_CTLB	; CB2 goes low following data write, returned high by IRQB1 set by low to high transition on CB1
		LDA 	#$FF		; Set Port B as all outputs
		STA 	PIA_PRTB	; DDR B register write
		LDA 	#$26		; Select Port B Data Register (rest as above) 
		STA 	PIA_CTLB
; Initialize DecayCount
		LDA	#10		; Wait a bit before starting the music
		STA	DecayCount
; Initialize PSGVolume, PSGNote & SoundByteOfs storage to Zero
		CLR	PSGVolume
		CLR	PSGVolume+1
		CLR	PSGVolume+2
		CLR	PSGNote
		CLR	PSGNote+1
		CLR	PSGNote+2
		CLR	SoundByteOfs
		CLR	SoundByteOfs+1
		LBSR	silenceSound
; Setup IRQ Handler
		LEAX	irqHandler,PCR
		LDA	#IRQ_CODE
		SWI
		FCB	VCTRSWP
; Clear CC IRQ Flag - Enable IRQ Interrupts
		ANDCC	#$EF		
; Now Enable VDP Interrupts (as well as Display Enabled)
		LDA	#Reg1IntDspEn	; Update Register 1 to turn on Display & Interrupt Enable
		LDB	#1		; Write to VDP Register 1
		BSR	writeRegisterByteVDP
;
; Loop Forever
;LoopForever	BRA	LoopForever	; Loop Forever
					; OR,
LoopUntilEnd	LDA	PSGNote+2	; Return to ASSIST09 when Song Ends
		CMPA	#$FE		; Current Tone Generator 3 note 254 indicates song has ended
		BNE	LoopUntilEnd
		ORCC	#$10		; Mask further interrupts
		LBSR	silenceSound	; Silence the SN76489
		CLRA			; Re-enter ASSIST09 Monitor
		SWI
		FCB	MONITR
		BRA	LoopUntilEnd
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
;		NOP			; NOP - add for required delay when running at 4Mhz
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
;		NOP			; NOP - add for required delay when running at 4Mhz
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
;		NOP			; NOP - add for required delay when running at 4Mhz
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
;		NOP			; NOP - add for required delay when running at 4Mhz
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
;		NOP			; NOP x2 - add for required delay when running at 4Mhz
;		NOP
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
;		NOP			; NOP x2 - add for required delay when running at 4Mhz
;		NOP
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
writeSoundByte
; Function:	Write Sound Byte (A) to SN76489 and wait for not busy
; Parameters:	A - Sound Byte to write
; Returns:	-
; Destroys:	A
		STA PIA_PRTB
busyCheck	LDA PIA_CTLB		; Read control Register
		BPL busyCheck		; Wait for CB1 transition (IRQB1 flag)	
		LDA PIA_PRTB		; Reset the IRQ flag by reading the data register
		RTS
;
silenceSound	
; Function:	Silence all SN76489 Sound Channels
; Parameters:	-
; Returns:	-
; Destroys:	A
		LDA	#$9F		; Turn Off Channel 0
		BSR	writeSoundByte
		LDA	#$BF		; Turn Off Channel 1
		BSR	writeSoundByte
		LDA	#$CF		; Turn Off Channel 2
		BSR	writeSoundByte
		LDA	#$FF		; Turn Off Noise Channel
		BSR	writeSoundByte
		RTS
;
; *** End of Subroutines. Interrupt Handler follows ***
;
irqHandler	
; Function:	Play SoundByteTable notes for all 3 Tone Generators of the SN76489
		LDX	#3		; Initialise Loop count for our 3 Tone Generators
SoundGenLoop	
		LDA	PSGVolume-1,X	; Check if the Tone Generator's volume is now >0
		BEQ	NoNotePlayed	; If Tone Generator's volume now 0 then note was silenced last time
		DECA		 	; Decrement the Tone Generator's volume to use
		STA 	PSGVolume-1,X	; And save new volume
		EORA	#$9F		; Convert desired volume into SN76489 Attenuation Control Byte - So this turns 0000xxxx into 1001yyyy, where y = 15-x (and x is the desired volume).
		STA	Temp		; Temp save the value while we organise the selected Tone Generator bits.
		TFR	X,D		; Copy X Tone Generator loop count into D for transfer to A (for writeSoundByte) 
		TFR	B,A		; Now we have 000000xx in A, where x is the Tone Generator number +1 (1 through 3)
		DECA			; Adjust A for 0 through 2 (instead of our 1 through 3 loop count)
		LSLA			; Move Tone Generator number into bits 5 and 6 of A
		LSLA
		LSLA
		LSLA
		LSLA			; This makes it 0xx00000
		ADDA	Temp		; Now we add to that the byte we previously saved, so we get 1xx1yyyy... the required format for Attenuation Control Byte.
		BSR	writeSoundByte	; Write the Attenuation Control Byte to the SN76489
NoNotePlayed	LEAX	-1,X		; Decrement our Tone Generator loop count
		BNE 	SoundGenLoop	; Loop back to process next Tone Generator if we're not done yet
HandleNewNotes	DEC	DecayCount	; Decrement our Decay Count
		BNE	irqReturn	; If volume still decaying then return from interrupt
;
; The following handles the reading of new notes to be played for each of the 3 sound channels
;
		LDA	#$0A		; For new notes, we reset the decay value (which determines the overall tempo).
		STA	DecayCount	; Note: The decay value doesn't necessarily drop each note volume to zero, as we use it to also set an appropriate tempo.
ReadNewNotes1	LDX	#3		; Initialise Loop count for our 3 Tone Generators
ReadNewNotes	LDY	SoundByteOfs
		LDB	SoundByteTable,Y
		STB	PSGNote-1,X	; Store the current Note for each Tone Generator
		CMPB	#$FE		; #$FE marks the end of the SoundBytetable, so we loop back to the start
		BEQ	ReturnToStart
		CMPB	#$FF		; #$FF marks no note to play (a pause), so no note gets played this time for this sound channel
		BEQ	PlayNoNote
		LDA	#$10		; Initialise full volume (+1) into channel variable for the sound channel's volume
		STA	PSGVolume-1,X
		LSLB			; Double the note byte value for an index into FrequencyTable 16 bit words
		CLRA
		TFR	D,Y		; Y now holds our FrequencyTable index
		TFR	X,D		; Copy X Tone Generator loop count into D for transfer to A (for writeSoundByte) 
		TFR	B,A		; Now we have 000000xx in A, where x is the Tone Generator number +1 (1 through 3)
		DECA			; Adjust for 0 through 2 (instead of our 1 through 3 loop count)
		LSLA			; Shift Left the Tone Generator number into bits 5 and 6 of A
		LSLA
		LSLA
		LSLA
		LSLA			; This makes it 0xx00000
		ORA	#$80		; And finally 1xx00000
		ADDA	FrequencyTable+1,Y	
		LBSR	writeSoundByte	; Write low byte of desired note frequency (1xx0ffff format for the first byte)
		LDA	FrequencyTable,Y
		LBSR	writeSoundByte	; Write high byte of desired note frequency
PlayNoNote	LDY	SoundByteOfs	; Now Increment the Sound Byte 16 bit Offset
		LEAY	1,Y
		STY	SoundByteOfs
		LEAX	-1,X		; And Decrement the Tone Generator loop count
		BNE	ReadNewNotes	; Read more notes if we haven't processed all 3 Tone Generators yet
;
irqReturn	LDA	VDP_REGISTER	; Dummy Read of VDP Status Register to reset the VDP Frame Interrupt
		RTI
;
ReturnToStart	CLR	SoundByteOfs	; Initilise Sound Byte Offset back to zero, if we want to start over again
		CLR	SoundByteOfs+1
;		JMP	ReadNewNotes1	; Finally, re-start the sound channel loop as we're starting again
;					; OR,
		BRA	irqReturn	; Instead just return, if we just want to stop!
;		
;
; *** End of Interrupt Handler. Data follows ***
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
		INCLUDE	"src\\SoundByteTable.asm"
;
		INCLUDE	"src\\FrequencyTable.asm"
;