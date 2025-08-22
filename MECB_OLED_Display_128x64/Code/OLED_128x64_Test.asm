;******************************************************************************
;	OLED_128x64_Test.asm
;
;	A simple MECB OLED Display 128x64 Card Test (for a 6809 CPU Card).
;
;	Set ENTRY EQU for your preferred code assembly location.
;	e.g. $0100 specified for running the code in the 2nd page of main RAM.
;	Set OLED EQU for your OLED's base address.
;	e.g. $C088 is for $C0 IORQ bank and $88 - $8F I/O block allocation. 
;
;	Author: Greg
;	Date:	Aug 2025
;
;******************************************************************************
ENTRY		EQU	$0100
OLED		EQU	$C088		; OLED Panel base address
OLED_CMD	EQU	OLED		; OLED Command address
OLED_DTA	EQU	OLED+1		; OLED Data address
STKTOP 		EQU 	$007F		; System Stack Top
VX		EQU	$0000		; X coord
VY		EQU	$0001		; Y coord
OLEDRES		EQU	$0002		; Oled Resolution 0=Off / 1=128x64 / 2=64x32
;
; Code Entry Point
; ----------------
		ORG	ENTRY
; Initialise Direct Page Register for Zero page
		CLRA
		TFR	A,DP	
; Tell asm6809 what page the DP register has been set to
		SETDP	#$00
; Set Stack to Stack Top
		LDS	#STKTOP
;
; Initialise our OLED Display Panel
; There are many settings for the SSD1327, but most are correctly initialised
; following a Reset.  Therefore, I only update the settings that I wish to
; change from their default Reset value (as per the SSD1327 datasheet). 
;
		LDX	#OledInitCmds	; Load X as pointer to Initialise Command table
		LDB	#16		; Number of Command bytes in table
LoadCmdLoop	LDA	,X+		; Load register data pointed to by X and increment X
		STA	OLED_CMD	; Store Command byte
		DECB			; Point to next register
		BNE	LoadCmdLoop	; Have we done all Command bytes?
; Clear the Display Buffer (VRAM)
		CLRA			; Zero byte to Clear Display buffer (VRAM)
		CLRB			; Full Display (Start row = 0)
		LBSR	OledFill	; Fill OLED Display
; Turn ON the Display		
		LDA	#$AF		; Turn Display ON (after clearing buffer)
		STA	OLED_CMD	;
; Set Default Full OLED resolution mode 128x64
		LDA	#$01		; Full OLED resolution mode 128x64
		STA	OLEDRES		;
; Fill the Display
;		LDA	#$FF		; Display Data
;		CLRB			; Full Display (Start row = 0)
;		LBSR	OledFill	; Fill OLED Display
;
; Draw some diagonal lines - First do two full resolution lines (128x64)
		LDA	#0		; Setup initial X coord
		STA	VX
		LDA	#0		; Setup initial Y coord
		STA	VY
		LDA	#64		; Line length (X count)
DrawLp1		LBSR	TglPxl		; Set the Pixel
		INC	VX		; Increment X coord
		INC	VY		; Increment Y coord
		CMPA	VX		; End of Line?
		BNE	DrawLp1		; Continue line if not
;
		LDA	#0		; Setup initial X coord
		STA	VX
		LDA	#63		; Setup initial Y coord
		STA	VY
		LDA	#64		; End X count
DrawLp2		LBSR	TglPxl		; Set the Pixel
		INC	VX		; Increment X coord
		DEC	VY		; Decrement Y coord
		CMPA	VX		; End of Line?
		BNE	DrawLp2		; Continue line if not
;		
; Draw some diagonal lines - Next do two half resolution lines (64x32)
		LDA	#$02		; Set Half OLED resolution mode 64x32
		STA	OLEDRES		;
;
		LDA	#32		; Setup initial X coord
		STA	VX
		LDA	#0		; Setup initial Y coord
		STA	VY
		LDA	#64		; End X count
DrawLp3		LBSR	TglPxl		; Set the Pixel
		INC	VX		; Increment X coord
		INC	VY		; Increment Y coord
		CMPA	VX		; End of Line?
		BNE	DrawLp3
;
		LDA	#32		; Setup initial X coord
		STA	VX
		LDA	#31		; Setup initial Y coord
		STA	VY
		LDA	#64		; End X count
DrawLp4		LBSR	TglPxl		; Set the Pixel
		INC	VX		; Increment X coord
		DEC	VY		; Decrement Y coord
		CMPA	VX		; End of Line?
		BNE	DrawLp4
;
		RTS			; Return
;
; Data Structures
; ---------------
OledInitCmds	FCB	$B3,$70		; Set Clk Divider / Osc Fequency
		FCB	$A0,$51		; Set appropriate Display re-map
		FCB	$D5,$62		; Enable second pre-charge
		FCB	$81,$7F		; Set contrast (0 - $FF)
		FCB	$B1,$74		; Set phase length - Phase 1 = 4 DCLK / Phase 2 = 7 DCLK
		FCB	$B6,$0F		; Set second pre-charge period
		FCB	$BC,$07		; Set pre-charge voltage - 0.613 x Vcc
		FCB	$BE,$07		; Set VCOMH - 0.86 x Vcc
;
; Subroutines
; -----------
SetPxl
; Function:	Set the Pixel at VX,VY (Res as per OLEDRES)
; Parameters:	VX - X coord (0 - 63 / 127)
;		VY - Y coord (0 - 31 / 63)
; Returns:	-
; Destroys:	-
		PSHS	A,B
		LDA	OLEDRES		; Get OLED resolution flag
		BEQ	SetPxlRts	; Nothing to do
		LSRA			; Test for Full res mode
		BEQ	SetPxl2		;
		LBSR	SetPxlH		; Assume Half Res Mode
		BRA	SetPxlRts	;
SetPxl2		LBSR	SetPxlF		; Full Res Mode
SetPxlRts	PULS	A,B
		RTS
;
ClrPxl
; Function:	Clear the Pixel at VX,VY (Res as per OLEDRES)
; Parameters:	VX - X coord (0 - 63 / 127)
;		VY - Y coord (0 - 31 / 63)
; Returns:	-
; Destroys:	-
		PSHS	A,B
		LDA	OLEDRES		; Get OLED resolution flag
		BEQ	ClrPxlRts	; Nothing to do
		LSRA			; Test for Full res mode
		BEQ	ClrPxl2		;
		LBSR	ClrPxlH		; Assume Half Res Mode
		BRA	ClrPxlRts	;
ClrPxl2		LBSR	ClrPxlF		; Full Res Mode
ClrPxlRts	PULS	A,B
		RTS
;
TglPxl
; Function:	Toggle (invert) the Pixel value at VX,VY (Res as per OLEDRES)
; Parameters:	VX - X coord (0 - 63 / 127)
;		VY - Y coord (0 - 31 / 63)
; Returns:	-
; Destroys:	-
		PSHS	A,B
		LDA	OLEDRES		; Get OLED resolution flag
		BEQ	TglPxlRts	; Nothing to do
		LSRA			; Test for Full res mode
		BEQ	TglPxl2		;
		LBSR	TglPxlH		; Assume Half Res Mode
		BRA	TglPxlRts	;
TglPxl2		LBSR	TglPxlF		; Full Res Mode
TglPxlRts	PULS	A,B
		RTS
;
OledFill
; Function:	Fill OLED display VRAM with byte, from a specified start row
; Parameters:	A - Byte to fill OLED buffer with
;		B - Start Row (i.e. 0 for full panel fill)
; Returns:	-
; Destroys:	B,Y
		TFR	D,Y		; Save Parameters
;
		CLRA			; Set Column Address range
		LDB	#127		; Start =0, End = 127
		LBSR	ColSetF		;
;
		TFR	Y,D		; Restore Parameters
		PSHS	A		; Save Byte to fill
		TFR	B,A		; Set Row Address range

		LDY	#0		; Establish Count of Bytes to Write
WrtDtaLp1	LEAY	128,Y		; Add 128 to Y
		INCB
		CMPB	#64
		BNE	WrtDtaLp1
;
		LDB	#63		; Start = A, End = 63
		LBSR	RowSetF		;
		PULS	A		; Restore Byte to fill
WrtDtaLp2	STA	OLED_DTA	; Write Byte to curent buffer location
		LEAY	-1,Y		; Dec Y
		BNE	WrtDtaLp2	; Done?
		RTS
;
; Support Subroutines
; -------------------
UpdPxlStpF
; Function:	Update Pixel - Setup for Set, Clr, Tgl subroutines (128x64 res)
;		Note: As SSD1327 stores 2 pixels in each byte, it's
;		necessary to get the VRAM byte first, to avoid overwriting
;		the neighbouring pixel (hence call to GetPxlBytF).
; Parameters:	VX - X coord (0 - 127)
;		VY - Y coord (0 - 63)
; Returns:	B - Pixel value at X,Y (appropriate nibble)
; Destroys:	A,B
		BSR	GetPxlBytF	; Get curent pixel byte values
		PSHS	B		; Save current pixel byte
		LDB	VY		; Retrieve Y coord
		TFR	B,A		; 
		LBSR	RowSetF		; Set Row of pixel
		LDA	VX		; Retrieve X coord
		TFR	A,B		; 
		LBSR	ColSetF		; Set Column of pixel
		PULS	B		; Retrieve current pixel
		RTS
;
UpdPxlStpH
; Function:	Update Pixel - Setup for SetH, ClrH, TglH subroutines (64x32 res)
;		Note: As SSD1327 stores 2 pixels in each byte, half Resolution
;		is easily achieved as we're updating 2 pixels for every "pixel"
; Parameters:	VX - X coord (0 - 63)
;		VY - Y coord (0 - 31)
; Returns:	B - Pixel value at A,B (dual even pixel byte)
; Destroys:	A,B
		BSR	GetPxlBytH	; Get curent pixel byte value
		PSHS	B		; Save current pixel byte
		LDB	VY		; Retrieve Y coord
		TFR	B,A		; 
		LBSR	RowSetH		; Set Row of pixel
		LDA	VX		; Retrieve X coord
		TFR	A,B		; 
		LBSR	ColSetH		; Set Column of pixel
		PULS	B		; Retrieve current pixel
		RTS
;
GetPxlBytF
; Function:	Get the Pixel Byte at VX,VY
; Parameters:	VX - X coord (0 - 127)
;		VY - Y coord (0 - 63)
; Returns:	B - Pixel value at A,B (appropriate nibble)
; Destroys:	A,B
		LDB	VY		; Retrieve Y coord
		TFR	B,A		; 
		LBSR	RowSetF		; Set Row of pixel
		LDA	VX		; Retrieve X coord
		TFR	A,B		; 
		LBSR	ColSetF		; Set Column of pixel
		LDB	OLED_DTA 	; Dummy Read
		LDB	OLED_DTA 	; Actual Read
		RTS
;
GetPxlBytH
; Function:	Get the Pixel Byte at VX,VY
; Parameters:	VX - X coord (0 - 63)
;		VY - Y coord (0 - 31)
; Returns:	B - Pixel value at A,B (dual even pixel byte)
; Destroys:	A,B
		LDB	VY		; Retrieve V coord
		TFR	B,A		; 
		LBSR	RowSetH		; Set Row of pixel
		LDA	VX		; Retrieve X coord
		TFR	A,B		; 
		LBSR	ColSetH		; Set Column of pixel
		LDB	OLED_DTA 	; Dummy Read
		LDB	OLED_DTA 	; Actual Read
		RTS
;
SetPxlF
; Function:	Set the Pixel at VX,VY (128x64 Res)
;		Note: As SSD1327 stores 2 pixels in each byte, it's
;		necessary to get the VRAM byte first, to avoid overwriting
;		the neighbouring pixel.
; Parameters:	VX - X coord (0 - 127)
;		VY - Y coord (0 - 63)
; Returns:	-
; Destroys:	A,B
		BSR	UpdPxlStpF	; Setup for updating the pixel
		LDA	VX
		BITA	#$01		; Test if we're updating odd column?
		BEQ	WasEvnSet	;
		ORB	#$0F		; Set for odd column pixel
		BRA	StrPxlSet	;
WasEvnSet	ORB	#$F0		; Set for even column pixel
StrPxlSet	STB	OLED_DTA	;
		RTS
;
SetPxlH
; Function:	Set the Pixel at VX,VY (64x32 Res)
;		Note: As SSD1327 stores 2 pixels in each byte, half resolution
;		is easily achieved as we're updating 2 pixels for every "pixel"
; Parameters:	VX - X coord (0 - 63)
;		VY - Y coord (0 - 31)
; Returns:	-
; Destroys:	A,B
		LBSR	UpdPxlStpH	; Setup for updating the pixel
		LDB	#$FF		; Set double pixel
		STB	OLED_DTA	;
		STB	OLED_DTA	;
		RTS
;
ClrPxlF
; Function:	Clear the Pixel at VX,VY (128x64 Res)
;		Note: As SSD1327 stores 2 pixels in each byte, it's
;		necessary to get the VRAM byte first, to avoid overwriting
;		the neighbouring pixel.
; Parameters:	VX - X coord (0 - 127)
;		VY - Y coord (0 - 63)
; Returns:	-
; Destroys:	A,B
		LBSR	UpdPxlStpF	; Setup for updating the pixel
		LDA	VX
		BITA	#$01		; Test if we're updating odd column?
		BEQ	WasEvnClr	;
		ANDB	#$F0		; Clear odd column pixel
		BRA	StrPxlClr	;
WasEvnClr	ANDB	#$0F		; Clear even column pixel
StrPxlClr	STB	OLED_DTA	;
		RTS
;
ClrPxlH
; Function:	Clear the Pixel at VX,VY (64x32 Res)
;		Note: As SSD1327 stores 2 pixels in each byte, half resolution
;		is easily achieved as we're updating 2 pixels for every "pixel"
; Parameters:	VX - X coord (0 - 63)
;		VY - Y coord (0 - 31)
; Returns:	-
; Destroys:	A,B
		LBSR	UpdPxlStpH	; Setup for updating the pixel
		CLRB			; Clear double pixel
		STB	OLED_DTA	;
		STB	OLED_DTA	;
		RTS
;
TglPxlF
; Function:	Toggle (invert) the Pixel value at VX,VY (128x64 res)
;		Note: As SSD1327 stores 2 pixels in each byte, it's
;		necessary to get the VRAM byte first, to avoid overwriting
;		the neighbouring pixel.
; Parameters:	VX - X coord (0 - 127)
;		VY - Y coord (0 - 63)
; Returns:	-
; Destroys:	A,B
		LBSR	UpdPxlStpF	; Setup for updating the pixel
		LDA	VX
		BITA	#$01		; Test if we're updating odd column?
		BEQ	WasEvnTgl	;
		EORB	#$0F		; Invert odd column pixel
		BRA	StrPxlTgl	;
WasEvnTgl	EORB	#$F0		; Invert even column pixel
StrPxlTgl	STB	OLED_DTA	;
		RTS
;
TglPxlH
; Function:	Toggle (invert) the Pixel value at VX,VY (64x32 res)
;		Note: As SSD1327 stores 2 pixels in each byte, half resolution
;		is easily achieved as we're updating 2 pixels for every "pixel"
; Parameters:	VX - X coord (0 - 63)
;		VY - Y coord (0 - 31)
; Returns:	-
; Destroys:	A,B
		LBSR	UpdPxlStpH	; Setup for updating the pixel
		EORB	#$FF		; Invert column dual pixel
		STB	OLED_DTA	;
		STB	OLED_DTA	;
		RTS
;
ColSetF
; Function:	Set the Display buffer Column Start and End addresses (128x64 res)
; Parameters:	A - Start column (0 - 127)
;		B - End column  (0 - 127)
; Returns:	-
; Destroys:	A,B
		PSHS	A		;
		LDA	#$15		; Set Column Address Command
		STA	OLED_CMD	;
		PULS	A		; Start column (left)
		LSRA			; Div A by 2 (2 pixels per byte)
		STA	OLED_CMD	;
		LSRB			; Div B by 2 (2 pixels per byte)
		STB	OLED_CMD	; End column address (right)
		RTS
;
ColSetH
; Function:	Set the Display buffer Column Start and End addresses (64x32 res)
; Parameters:	A - Start column (0 - 63)
;		B - End column  (0 - 63)
; Returns:	-
; Destroys:	-
		PSHS	A		;
		LDA	#$15		; Set Column Address Command
		STA	OLED_CMD	;
		PULS	A		; Start column (left)
		STA	OLED_CMD	;
		STB	OLED_CMD	; End column address (right)
		RTS
;
RowSetF
; Function:	Set the Display buffer Row Start and End addresses (128x64 res)
; Parameters:	A - Start row (0 - 63)
;		B - End row (0 - 63) 
; Returns:	-
; Destroys:	-
		PSHS	A		; Save A
		LDA	#$75		; Set Row Address Command
		STA	OLED_CMD	;
		PULS	A		; Start row (top)
		STA	OLED_CMD	;
		STB	OLED_CMD	; End row (bottom)
		RTS
;
RowSetH
; Function:	Set the Display buffer Row Start and End addresses (64x32 res)
; Parameters:	A - Start row (0 - 31)
;		B - End row (0 - 31) 
; Returns:	-
; Destroys:	A,B
		PSHS	A		; Save A
		LDA	#$75		; Set Row Address Command
		STA	OLED_CMD	;
		PULS	A		; Start row (top)
		LSLA			;
		STA	OLED_CMD	;
		LSLB			;
		ADDB	#$01		;
		STB	OLED_CMD	; End row (bottom)
		RTS
;
OledFillAll
; Function:	Fill OLED display VRAM with byte (note 1 byte = 2 pixels)
; Parameters:	A - Byte to fill OLED buffer with
; Returns:	-
; Destroys:	Y
		LDY	#4096		; 64 x 64 bytes (128 x 64 pixels)
		PSHS	A		; Save Byte we want to fill with
;
		CLRA			; Set Column Address range
		LDB	#127		; Start =0, End = 127
		BSR	ColSetF	;
;
		CLRA			; Set Row Address range
		LDB	#63		; Start = 0, End = 63
		BSR	RowSetF	;
;
		PULS	A		; Restore Byte we want to fill with
WrtDtaLp	STA	OLED_DTA	; Write Byte to current buffer location
		LEAX	-1,Y		; Dec Y
		BNE	WrtDtaLp	; Done?
		RTS
;
		END