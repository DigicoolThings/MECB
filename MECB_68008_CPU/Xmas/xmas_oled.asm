;******************************************************************************
;	xmas_oled.asm
;
;	A simple MECB 68008 CPU Card test utilising the MECB Motorola I/O Card,
;   and the MECB OLED Display 128x64 Card.
;
;	This version is currently intended as RAM loadable code (eg. $4000 Entry),
;   but could also be Assembled for ROM, simply by changing the ENTRY address.
;
;	Using the OLED Display Panel and the MC6821 PIA Port B interfaced SN76489
;   sound generator, this test displays a Christmas scene and plays a tune.
;
;   Written for 10MHz 68008 operation. Changes in clock speed will require
;   a new FreqTable, with appropriate note frequency divider values!
;
;   This version is based on Emil Lenc's conversion of the DigicoolThings
;   MECBChristmas09 6809 test, which utilised the MECB Motorola I/O Card,
;   and the MECB TMS VDP Card.
;
;	Originally based on the CreatiVison Christmas Demo (by Kurt Woloch),
;   which was written in 6502 assembly code for the CreatiVision platform.
;
;	Author (68008 code conversion): Emil Lenc
;	Author (this code compilation): Greg@DigicoolThings.com
;	Date:	Feb 2026
;
;******************************************************************************
ENTRY          equ     $4000        ; Code Entry point
;
RAM_END        equ     $07FFFF      ; Top of RAM (for determining Scratchpad / Stack location)
;
; I/O mapping for 6840 PTM
;
PTM1           equ     $300000
PTM1_CR13      equ     PTM1         ; Write: Timer Control Registers 1 & 3   Read: NOP
PTM1_SR        equ     PTM1+1
PTM1_CR2       equ     PTM1+1       ; Write: Control Register 2              Read: Status Register (least significant bit selects TCR as TCSR1 or TCSR3)
;
PTM1_T1MSB     equ     PTM1+2       ; Write: MSB Buffer Register             Read: Timer 1 Counter
PTM1_T2MSB     equ     PTM1+4       ; Write: MSB Buffer Register             Read: Timer 1 Counter
PTM1_T3MSB     equ     PTM1+6       ; Write: MSB Buffer Register             Read: Timer 1 Counter
;
; I/O mapping for 6821 PIA
;
PIA1BASE       equ     $300010        ; PIA Base address
PIA1REGB       equ     PIA1BASE+2     ; data reg B
PIA1DDRB       equ     PIA1BASE+2     ; data dir reg B
PIA1CTLB       equ     PIA1BASE+3     ; control reg B
;
; I/O mapping for OLED Panel
;
OLED           equ      $300088         ; OLED Panel base address
OLED_CMD       equ      OLED            ; OLED Command address
OLED_DTA       equ      OLED+1          ; OLED Data address
;
; Tutor Monitor TRAP 14 Function
;
TUTOR          equ      228
;
; Tutor Monitor IRQ1 (INT) Vector Address
;
VEC_IRQ1       equ      $19*4
;
; Local equates
;
TIMER_VAL      equ      $5000      ; timer 1 count setting
TIMER_SETH     equ      $01        ; Preset all timers a=$01, b=$42 CRX6=1 (interrupt); CRX1=1 (enable clock)
TIMER_SETL     equ      $42        ; Preset all timers a=$01, b=$42 CRX6=1 (interrupt); CRX1=1 (enable clock)
;
; Scratchpad allocations
;
; Important: Due to the way timer_isr is implemented, it is necessary for the psg_volume locations
;            to be exactly 3 bytes below the matching psg_note locations!
;
sound_ptr      equ      RAM_END-3
decay_count    equ      RAM_END-4
psg_note2      equ      RAM_END-5
psg_note1      equ      RAM_END-6
psg_note0      equ      RAM_END-7
psg_volume2    equ      RAM_END-8
psg_volume1    equ      RAM_END-9
psg_volume0    equ      RAM_END-10
;
STACK_TOP      equ      RAM_END-15
;
               org      ENTRY                      ; Code entry point!
;
               lea      STACK_TOP,A7               ; Initialise Stack
               jsr      oled_init
;
               move.b   #$00,d0                    ; d0 = fill value
               move.b   #$00,d1                    ; d1 = start row
               move.b   #$3f,d2                    ; d2 = end row
               jsr      oled_fill
               jsr      oled_on
               move.l   #xmas_image,a0
               jsr      oled_move
;
               move.b   #10,decay_count            ; Initialize decay count
               move.b   #0,psg_volume0             ; set all channels to off
               move.b   #0,psg_volume1
               move.b   #0,psg_volume2
               move.b   #0,psg_note0               ; reset note values
               move.b   #0,psg_note1
               move.b   #0,psg_note2
               move.l   #SoundByteTable,a6         ; point to sound table
               move.l   a6,sound_ptr

               jsr      psg_init                   ; initialize the PSG
;
               move.l   #timer_isr,a6              ; Point IRQ1 vector (mecb_int) to ISR
               move.l   a6,VEC_IRQ1
;
               bsr      ptm_init                   ; initialize the timer
;
               and.w    #$F8FF,sr                  ; enable interrupts
loop           cmp.b    #$FE,psg_note0             ; wait for last note
               bne      loop
               or.w     #$0700,sr                  ; disable interrupts
               jsr      psg_stop                   ; stop the audio
;
test_end       move.b   #TUTOR,d7                  ; return to monitor
               trap     #14
;
; Initialise the timer to provide the music beat
;
ptm_init:      move.w   #TIMER_VAL,d0
               move.w   d0,PTM1_T1MSB
               move.b   #TIMER_SETH,d0       ; Preset all timers : CRX6=1 (interrupt); CRX1=1 (enable clock)
               move.b   d0,PTM1_CR2          ; Write to CR2
               move.b   #TIMER_SETL,d0
               move.b   d0,PTM1_CR13 
               move.l   #0,d0
               move.b   d0,PTM1_CR2 
               move.b   PTM1_SR,d0           ; Read the interrupt flag from the status register
               move.b   #$40,d0
               move.b   d0,PTM1_CR13         ; enable interrupt and start timer
               rts 
;
; Function:	Play SoundByteTable notes for all 3 tone generators of the SN76489
; The function is called by the timer interrupt.
;
timer_isr      movem.l  d0-d2/a0-a2,-(a7) ; save registers
               move.b   PTM1_SR,d1        ; Read the interrupt flag from the status register
               move.w   PTM1_T1MSB,d1     ; clear timer interrupt flag
               move.b   PTM1_SR,d1        ; Read the interrupt flag from the status register
               move.w   PTM1_T2MSB,d1
               move.b   PTM1_SR,d1        ; Read the interrupt flag from the status register
               move.w   PTM1_T3MSB,d1
;
               move.l   #psg_volume0,a1   ; Initialise volume pointer for the 3 Tone Generators
               move.b   #0,d0             ; d0 = current tone generator
SoundGenLoop   move.b   (a1)+,d1          ; Check if the Tone Generator's volume is >0
               beq      NoNotePlayed      ; If Tone Generator's volume now 0 then note was silenced last time
               sub.b    #1,d1             ; Decrement the Tone Generator's volume to use
               move.b   d1,-1(a1)         ; Record the new volume
               jsr      psg_volume        ; Set the new volume in the PSG for channel d0, level d1
NoNotePlayed   add.b    #1,d0             ; next channel number
               cmp.b    #3,d0
               bne      SoundGenLoop      ; Loop back to process next channel if we're not done yet
HandleNewNotes sub.b    #1,decay_count    ; Decrement our Decay Count
               bne      isr_return        ; If volume still decaying then return from interrupt
;
; The following handles the reading of new notes to be played for each of the 3 sound channels
;
               move.b   #10,decay_count   ; Reset decay count
ReadNewNotes1  move.l   #psg_note0,a1     ; Initialise note pointer for the 3 channels
               move.b   #0,d0             ; d0 = current tone generator
               move.l   sound_ptr,a0      ; Point to current sound byte
ReadNewNotes   move.b   (a0)+,d1          ; Get the current note
               move.b   d1,(a1)           ; Store the note for the current channel
               cmp.b    #$fe,d1           ; #$FE marks the end of the SoundBytetable, so we loop back to the start
               beq      ReturnToStart
               cmp.b    #$ff,d1           ; #$FF marks no note to play (a pause), so no note gets played this time for this sound channel
               beq      PlayNoNote
               move.b   #$10,-3(a1)       ; Initialise full volume (+1) into channel variable for the sound channel's volume
               and.l    #$ff,d1
               lsl.l    #1,d1             ; Double the note byte value for an index into FreqTable 16 bit words
               add.l    #FreqTable,d1
               move.l   d1,a2             ; a contains pointer to note frequency
               move.w   (a2),d1           ; get the note frequency
               jsr      psg_tone          ; Set the frequency for the current channel
PlayNoNote     lea.l    1(a1),a1          ; point to next channel
               add.b    #1,d0             ; next channel number
               cmp.b    #3,d0             ; next tone generator
               bne      ReadNewNotes      ; Read more notes if we haven't processed all 3 Tone Generators yet
               move.l   a0,sound_ptr      ; Save the note pointer
;
isr_return     movem.l  (a7)+,d0-d2/a0-a2 ; restore registers
               rte
;
; Initilise Sound Byte Offset back to zero, if we want to start over again
;
ReturnToStart  move.l   #SoundByteTable,a6
               move.l   a6,sound_ptr
;              bra      ReadNewNotes1     ; Finally, re-start the sound channel loop as we're starting again
;              ; OR,
               bra      isr_return        ; Instead just return, if we just want to stop!
;
; Initialize PIA1 for use with PSG
;
psg_init       move.b   #$22,PIA1CTLB     ; Setup PIA Port B for Sound ouput, select DDR Register B
                                          ; CB2 goes low following data write, returned high by IRQB1 set by low to high transition on CB1
               move.b   #$ff,PIA1DDRB     ; Set Port B as all outputs, DDR B register write
               move.b   #$26,PIA1CTLB     ; Select Port B Data Register (rest as above) 
               bsr      psg_stop
               rts
;
; Function:	Silence all SN76489 Sound Channels
; Parameters:	-
; Returns:	-
; Destroys:	A
psg_stop       movem.l  d0-d1,-(a7) ; Save registers
               move.b   #$00,d0     ; Turn off channel 0
               move.b   #$00,d1
               bsr      psg_volume
               add.b    #1,d0       ; Turn off channel 1
               bsr      psg_volume
               add.b    #1,d0       ; Turn off channel 2
               bsr      psg_volume
               add.b    #1,d0       ; Turn off channel 3
               bsr      psg_volume
               movem.l  (a7)+,d0-d1 ; Restore registers
               rts
;
; Function : Set channel volume for PSG
; Parameters:  d0 - channel (0-3, 3=noise)
;              d1 - level (0-15, 0=off)
psg_volume     movem.l  d0/d1,-(a7)    ; save registers
               lsl.b    #5,d0          ; move channel number to bits 5 and 6
               and.b    #$60,d0
               and.b    #$0f,d1
               eor.b    #$9f,d1        ; set bits for attenuator control
               add.b    d1,d0          ; add the attenuation level
               bsr      psg_write      ; write to the PSG
               movem.l  (a7)+,d0/d1    ; restore registers
               rts                     ; return
;
; Function : Set channel tone for PSG
; Parameters:  d0 - channel (0-2)
;              d1 - tone (0-1023)
psg_tone       movem.l  d0/d2,-(a7)    ; save registers
               lsl.b    #5,d0          ; move channel number to bits 5 and 6
               or.b     #$80,d0        ; set bits for frequency control
               move.w   d1,d2
               and.b    #$0F,d2        ; Mask off lowest four bits
               add.b    d2,d0          ; Add to the control byte
               bsr      psg_write      ; write to the PSG
               move.w   d1,d0
               lsr.w    #4,d0          ; Move most significant six bits 
               and.b    #$3f,d0        ; get the frequency MSbits
               bsr      psg_write      ; write to the PSG
               movem.l  (a7)+,d0/d2    ; restore registers
               rts                     ; return
;
; Function:	Write Sound Byte (d0) to SN76489 and wait for not busy
; Parameters:  d0 - Sound Byte to write
; Returns:     -
; Destroys:    -
psg_write      move.b   d0,PIA1REGB
psg_write1     btst.b   #7,PIA1CTLB    ; Read control Register
               beq      psg_write1     ; Wait for CB1 transition (IRQB1 flag)
               tst.b    PIA1REGB       ; Reset the IRQ flag by reading the data register
               rts
;
; Initialize OLED
;
oled_init      movem.l  d0-d1/a0,-(a7)       ; save registers
               lea.l    OledInitCmds(pc),a0  ; point to initialisation command table
oled_init1     move.b   (a0)+,d0             ; get a command
               beq      oled_init2
               move.b   d0,OLED_CMD          ; Send to OLED
               move.b   (a0)+,d0             ; get a parameter
               move.b   d0,OLED_CMD          ; Send to OLED
               bra      oled_init1           ; loop if more commands to send
;
oled_init2     movem.l  (a7)+,d0-d1/a0       ; restore registers
               rts
;
oled_on        move.b   #$AF,OLED_CMD        ; Turn on the display
               rts
;
oled_off       move.b   #$AE,OLED_CMD        ; Turn on the display
               rts
;
; OLED Support Subroutines
; -------------------
;
; Function:	Set the Display buffer Column Start and End addresses (128x64 res)
; Parameters:  d0 - Start column (0 - 127)
;              d1 - End column  (0 - 127)
; Returns:     -
; Destroys:    -
oled_set_col   move.l   d0,-(a7)          ; Save d0
               move.b   #$15,OLED_CMD     ; Set column address command
               lsr.b    #1,d0             ; column/2 (2 pixels per byte)
               move.b   d0,OLED_CMD       ; write start column
               move.b   d1,d0
               lsr.b    #1,d0             ; column/2 (2 pixels per byte)
               move.b   d0,OLED_CMD       ; write end column
               move.l   (a7)+,d0          ; Restore d0
               rts
;
; Function:	Set the Display buffer Row Start and End addresses (128x64 res)
; Parameters:  d0 - Start row (0 - 63)
;              d1 - End row (0 - 63) 
; Returns:     -
; Destroys:    -
oled_set_row   move.b   #$75,OLED_CMD     ; Set row address command
               move.b   d0,OLED_CMD       ; row start
               move.b   d1,OLED_CMD       ; row end
               rts
;
; Function:    Set the Pixel at X,Y colour C
; Parameters:  d0 - X coord (0 - 127)
;              d1 - Y coord (0 - 63)
;              d2 - colour = 0 - 15
; Returns:     -
; Destroys:    -
oled_spixel    movem.l  d0-d3,-(a7)
               move.b   #$75,OLED_CMD        ; Set Row Address Command
               move.b   d1,OLED_CMD          ; Start row (top)
               move.b   d1,OLED_CMD          ; End row (bottom) = Start row
;
               move.b   #$15,OLED_CMD        ; Set Column Address Command
               move.b   d0,d3                ; D3=x
               lsr.b    #1,d0                ; Div A by 2 (2 pixels per byte)
               move.b   d0,OLED_CMD          ; Start column (left)
               move.b   d0,OLED_CMD          ; End column address (right) = Start column
;
               move.b   OLED_DTA,d0          ; Dummy Read
               move.b   OLED_DTA,d0          ; Read pixel data
               btst     #0,d3                ; Test if we're updating odd column?
               beq      oled_spixel1         ;
               and.b    #$F0,d0              ; Mask out odd column
               or.b     d2,d0                ; Set for odd column pixel
               bra      oled_spixel2            ;
oled_spixel1   and.b    #$0F,d0              ; Mask out even column
               lsl.b    #4,d2                ; Move colour to upper nybble
               or.b     d2,d0                ; Set for even column pixel
oled_spixel2   move.b   d0,OLED_DTA
               movem.l  (a7)+,d0-d3
               rts
;
; Function:    Set the Pixel at x,y with given logical function and colour
; Parameters:  a0 - points to structure containing:
;              OLED_X(a0) - x coord (0 - 127)
;              OLED_Y(a0) - y coord (0 - 63)
;              OLED_C(a0) - colour (0 - 15)
;              OLED_L(a0) - logical function (OLED_PSET, OLED_POR, OLED_PEOR, OLED_PAND)
; Returns:     -
; Destroys:    -
;
; Logical functions for oled_pixel
;
OLED_PSET      equ      $0                   ; Set pixel
OLED_POR       equ      $1                   ; Or pixel
OLED_PEOR      equ      $2                   ; Exclusive-or pixel
OLED_PAND      equ      $3                   ; And pixel
;
; Structure used for oled_pixel
;
OLED_X         equ      $0                   ; X
OLED_Y         equ      $1                   ; Y
OLED_C         equ      $2                   ; Colour
OLED_L         equ      $3                   ; Logical function
;
oled_pixel     movem.l  d0-d2,-(a7)
               move.b   #$75,OLED_CMD        ; Set Row Address Command
               move.b   OLED_Y(a0),OLED_CMD  ; Start row (top)
               move.b   OLED_Y(a0),OLED_CMD  ; End row (bottom) = Start row

               move.b   #$15,OLED_CMD        ; Set Column Address Command
               move.b   OLED_X(a0),d0
               lsr.b    #1,d0                ; Div A by 2 (2 pixels per byte)
               move.b   d0,OLED_CMD          ; Start column (left)
               move.b   d0,OLED_CMD          ; End column address (right) = Start column

               move.b   OLED_DTA,d0          ; Dummy Read
               move.b   OLED_DTA,d0          ; Read pixel data
               move.b   d0,d1                ; keep copy of [even|odd] pixel in d1
               btst.b   #0,OLED_X(a0)        ; Test if we're updating odd column?
               beq      oled_pixel1          ;
               and.b    #$0f,d0              ; Get the current pixel value
               and.b    #$f0,d1              ; Keep "other" pixel in d2 (needs to remain intact within the byte)
               bra      oled_pixel2          ;
oled_pixel1    lsr.b    #4,d0                ; Current pixel value in lower nybble of d0
               and.b    #$0f,d1              ; Keep "other" pixel in d2
oled_pixel2    cmp.b    #OLED_PSET,OLED_L(a0) 
               bne      oled_pixel3
               move.b   OLED_C(a0),d0        ; For PSET, pixel = colour
               bra      oled_pixel6
oled_pixel3    cmp.b    #OLED_POR,OLED_L(a0) 
               bne      oled_pixel4
               or.b     OLED_C(a0),d0        ; For POR, pixel = pixel | colour
               bra      oled_pixel6
oled_pixel4    cmp.b    #OLED_PEOR,OLED_L(a0) 
               bne      oled_pixel5
               move.b   OLED_C(a0),d2
               eor.b    d2,d0                ; For PEOR, pixel = pixel ^ colour
               bra      oled_pixel6
oled_pixel5    and.b    OLED_C(a0),d0
oled_pixel6    btst     #0,OLED_X(a0)        ; For PAND, pixel = pixel & colour
               bne      oled_pixel7
               lsl.b    #4,d0                ; If it was even, shift it back in place
oled_pixel7    add.b    d1,d0                ; combine with "other" pixel
               move.b   d0,OLED_DTA
               movem.l  (a7)+,d0-d2
               rts
;
; Function:    Fill OLED display VRAM with byte, from a specified start row
; Parameters:  d0 - Byte to fill OLED buffer with
;              d1 - Start row
;              d2 - End row
; Returns:     -
; Destroys:    -
oled_fill      movem.l  d0-d3,-(a7)    ; Save registers
               move.b   d0,d3          ; d3 = fill
;
               move.b   d1,d0          ; start row
               move.b   d2,d1          ; end row
               bsr      oled_set_row   ; set the row range
               sub.b    d0,d1          ; number of rows to fill
               add.b    #1,d1
               and.l    #$ff,d1        ; mask off high order bits
               lsl.l    #6,d1          ; Multiple by 64 bytes per row
               move.l   d1,d2          ; Count of bytes to fill in d2
;
               move.b   #0,d0          ; start column = 0
               move.b   #$7f,d1        ; end column = 127
               bsr      oled_set_col   ; set the column range
;
oled_fill1     move.b   d3,OLED_DTA    ; Write fill byte to curent buffer location
               sub.w    #1,d2          ; Dec byte counter
               bne      oled_fill1     ; Done?
               movem.l  (a7)+,d0-d3    ; Restore registers
               rts
;
; Function:    Fill OLED display VRAM data pointed to by a0
; Parameters:  -
; Returns:     -
; Destroys:    -
oled_move      movem.l  d0-d1/a0,-(a7)    ; Save registers
               move.b   #0,d0             ; start row
               move.b   #$3f,d1           ; end row
               bsr      oled_set_row      ; set the row range
               move.b   #0,d0             ; start column = 0
               move.b   #$7f,d1           ; end column = 127
               bsr      oled_set_col      ; set the column range
               move.w   #64*64,d0         ; number of bytes to transfer 128 x 64 / 2 (pixels per byte)
;
oled_move1     move.b   (a0)+,OLED_DTA    ; Move byte to current VRAM location
               sub.w    #1,d0             ; Dec byte counter
               bne      oled_move1        ; Done?
               movem.l  (a7)+,d0-d1/a0    ; Restore registers
               rts
;
; Data Structures
; ---------------
;
OledInitCmds   dc.b  $B3,$70              ; Set Clk Divider / Osc Frequency
               dc.b  $A0,$51              ; Set appropriate Display re-map
               dc.b  $D5,$62              ; Enable second pre-charge
               dc.b  $81,$FF              ; Set contrast (0 - $FF)
               dc.b  $B1,$74              ; Set phase length - Phase 1 = 4 DCLK / Phase 2 = 7 DCLK
               dc.b  $B6,$0F              ; Set second pre-charge period
               dc.b  $BC,$07              ; Set pre-charge voltage - 0.613 x Vcc
               dc.b  $BE,$07              ; Set VCOMH - 0.86 x Vcc
               dc.b  $00,$00              ; End of table
               dc.b  $00,$00              ; Long word align
;
; The SN76489 sound generator is clocked at 1MHz (E or mecb_clk for a 68008 @ 10MHz)
; These are the SN76489 Frequency byte pairs to generate the given Note / Frequency
; The actual (desired) Note frequency is in brackets.
; The actually achieved Note frequency is shown first, being the closest frequency
; to the desired Note Frequency, that the SN76489 Tone Generator divider can achieve.
; 
FreqTable      dc.w    $01DD   ; C2  = 65.51Hz (65.41Hz)
               dc.w    $01C2   ; C#2 = 69.44Hz (69.30Hz)
               dc.w    $01A9   ; D2  = 73.53hZ (73.42Hz)
               dc.w    $0191   ; D#2 = 77.93hZ (77.78Hz)
               dc.w    $017B   ; E2  = 82.45Hz (82.41Hz)
               dc.w    $0165   ; F2  = 87.54Hz (87.31Hz)
               dc.w    $0151   ; F#2 = 92.73Hz (92.50Hz)
               dc.w    $013E   ; G2  = 98.27Hz (98.00Hz)
               dc.w    $012C   ; G#2 = 104.17Hz (103.83Hz)
               dc.w    $011C   ; A2  = 110.04Hz (110.00Hz)
               dc.w    $010C   ; A#2 = 116.60Hz (116.54Hz)
               dc.w    $00FD   ; B2  = 123.52Hz (123.47Hz)
               dc.w    $00EE   ; C3  = 131.30Hz (130.81Hz)
               dc.w    $00E1   ; C#3 = 138.89Hz (138.59Hz)
               dc.w    $00D4   ; D3  = 147.41Hz (146.83Hz)
               dc.w    $00C8   ; D#3 = 156.25Hz (155.56Hz)
               dc.w    $00BD   ; E3  = 165.34Hz (164.81Hz)
               dc.w    $00B2   ; F3  = 175.56Hz (174.61Hz)
               dc.w    $00A8   ; F#3 = 186.01Hz (185.00Hz)
               dc.w    $009F   ; G3  = 196.54Hz (196.00Hz)
               dc.w    $0096   ; G#3 = 208.33Hz (207.65Hz)
               dc.w    $008E   ; A3  = 220.07Hz (220.00Hz)
               dc.w    $0086   ; A#3 = 233.21Hz (233.08Hz)
               dc.w    $007E   ; B3  = 248.02Hz (246.94Hz)
               dc.w    $0077   ; C4  = 262.61Hz (261.63Hz)
               dc.w    $0070   ; C#4 = 279.02Hz (277.18Hz)
               dc.w    $006A   ; D4  = 294.81Hz (293.66Hz)
               dc.w    $0064   ; D#4 = 312.50Hz (311.13Hz)
               dc.w    $005E   ; E4  = 332.45Hz (329.63Hz)
               dc.w    $0059   ; F4  = 351.12Hz (349.23Hz)
               dc.w    $0054   ; F#4 = 372.02Hz (369.99Hz)
               dc.w    $004F   ; G4  = 395.57Hz (392.00Hz)
               dc.w    $004B   ; G#4 = 416.67Hz (415.31Hz)
               dc.w    $0047   ; A4  = 440.14Hz (440.00Hz)
               dc.w    $0043   ; A#4 = 466.42Hz (466.16Hz)
               dc.w    $003F   ; B4  = 496.03Hz (493.88Hz)
;
; What follow is Kurt Woloch's original notes:
; Here we store the melody data; 255 means pause, 254 means back to start; all other are indexes into the frequency table
; This means that a byte value of 0 plays about the lowest possible "C" note (actually, 18 cents below that, which is 64,73 Hz).
; A value of 12 plays the "C" one octave above it and so on... the highest possible note is a A#2 (described as H2 in the table above)      
; since I've encoded 36 note steps. I've often given the notes as "5+12+x" or something like that to somehow simulate the octaves and notes in that.
; Yes, I know, I could also have defined constants like "C#1" for the note values, but I didn't feel like that.
; I've added 5 at the start because the lowest note played is a G (relative to the main key of the melody, which in this case is actually F major,
; so that that note is acually a "C". Yes, I know it's confusing, but this is how I perceive and memorize music).
; Each line holds the an 1/8 note played on all three sound generators, each group of 8 lines thus is a measure. 
; The spaces of two lines denote the boundaries of different "parts" of the melody.
; Table of Sound Byte Indexes into the Frequency Table for each of the 3 SN76489 Tone Generators
;
SoundByteTable dc.b     0, 12+7, 12+4     ;Ru-
               dc.b     255, 12+9, 12+4   ;dolph,
               dc.b     7, 255, 255
               dc.b     255, 12+7, 12+4   ;the
               dc.b     4, 12+4, 12       ;red-
               dc.b     255, 255, 255
               dc.b     7, 12+12, 12+4    ;nosed
               dc.b     255, 255, 255

               dc.b     0, 12+9, 12+4     ;rain-
               dc.b     255, 255, 255
               dc.b     7, 12+7, 12+4     ;deer
               dc.b     255, 255, 255
               dc.b     4, 255, 255
               dc.b     255, 255, 255
               dc.b     7, 255, 255
               dc.b     255, 255, 255

               dc.b     0, 12+7, 12+4     ;had
               dc.b     255, 12+9, 12+5   ;a
               dc.b     7, 12+7, 12+4     ;ve-
               dc.b     255, 12+9, 12+5   ;ry
               dc.b     4, 12+7, 12+4     ;shi-
               dc.b     255, 255, 255
               dc.b     3, 12+12, 12+9    ;ny
               dc.b     255, 255, 255

               dc.b     2, 12+7, 12+11    ;nose
               dc.b     255, 255, 255
               dc.b     7, 255, 255
               dc.b     255, 255, 255
               dc.b     5, 255, 255
               dc.b     255, 255, 255
               dc.b     2, 255, 255
               dc.b     255, 255, 255

               dc.b     7, 12+5, 12+2     ;and 
               dc.b     255, 12+7, 12+2   ;if
               dc.b     11, 255, 255
               dc.b     255, 12+5, 12+2   ;you
               dc.b     2, 12+2, 12-1     ;e-
               dc.b     255, 255, 255
               dc.b     5, 12+11, 12+7    ;ver
               dc.b     255, 255, 255

               dc.b     7, 12+9, 12+2     ;saw
               dc.b     255, 255, 255
               dc.b     11, 12+7, 12+2    ;it,
               dc.b     255, 255, 255
               dc.b     2, 255, 255
               dc.b     255, 255, 255
               dc.b     5, 255, 255
               dc.b     255, 255, 255

               dc.b     7, 12+7, 12+5     ;you
               dc.b     255, 12+9, 12+5   ;would
               dc.b     5, 12+7, 12+5     ;e-
               dc.b     255, 12+9, 12+5   ;ven
               dc.b     4, 12+7, 12+5     ;say
               dc.b     255, 255, 255
               dc.b     2, 12+9, 12+5     ;it
               dc.b     255, 255, 255

               dc.b     0, 12+4, 12       ;glo-
               dc.b     255, 255, 255
               dc.b     11, 12+7, 12+4    ;ws.
               dc.b     11, 255, 255
               dc.b     9, 255, 255
               dc.b     9, 255, 255
               dc.b     7, 255, 255
               dc.b     7, 255, 255


               dc.b     0, 12+7, 12+4     ;All
               dc.b     255, 12+9, 12+4   ;of
               dc.b     7, 255, 255
               dc.b     255, 12+7, 12+4   ;the
               dc.b     4, 12+4, 12       ;ot-
               dc.b     255, 255, 255
               dc.b     7, 12+12, 12+4    ;her
               dc.b     255, 255, 255

               dc.b     0, 12+9, 12+4     ;rain-
               dc.b     255, 255, 255
               dc.b     7, 12+7, 12+4     ;deer
               dc.b     255, 255, 255
               dc.b     4, 12+12+9, 12+12+4
               dc.b     255, 255, 255
               dc.b     7, 12+12+7, 12+12+4
               dc.b     255, 255, 255

               dc.b     0, 12+7, 12+4     ;used
               dc.b     255, 12+9, 12+5   ;to
               dc.b     7, 12+7, 12+4     ;laugh
               dc.b     255, 12+9, 12+5   ;and
               dc.b     4, 12+7, 12+4     ;call
               dc.b     255, 255, 255 
               dc.b     3, 12+12, 12+9    ;him
               dc.b     255, 255, 255

               dc.b     2, 12+11, 12+2    ;names
               dc.b     255, 255, 255
               dc.b     7, 255, 12+2
               dc.b     255, 255, 12+4
               dc.b     5, 255, 12+5
               dc.b     255, 255, 255
               dc.b     2, 255, 255
               dc.b     255, 255, 255

               dc.b     7, 12+5, 12+2     ;they
               dc.b     255, 12+7, 12+2   ;ne-
               dc.b     11, 255, 255
               dc.b     255, 12+5, 12+2   ;ver
               dc.b     2, 12+2, 12-1     ;let
               dc.b     255, 255, 255
               dc.b     5, 12+11, 12+7    ;poor
               dc.b     255, 255, 255

               dc.b     7, 12+9, 12+4     ;Ru-
               dc.b     255, 255, 255
               dc.b     11, 12+7, 12+2    ;dolph
               dc.b     255, 255, 255
               dc.b     2, 12+12+9, 12+12+5
               dc.b     255, 255, 255
               dc.b     5, 12+12+7, 12+12+2
               dc.b     255, 255, 255

               dc.b     7, 12+7, 12+5     ;join
               dc.b     255, 12+9, 12+5   ;in
               dc.b     5, 12+7, 12+5     ;a-
               dc.b     255, 12+9, 12+5   ;ny
               dc.b     4, 12+7, 12+5     ;rain
               dc.b     255, 255, 255
               dc.b     2, 12+12+2, 12+7  ;deer
               dc.b     255, 255, 255

               dc.b     0, 12+12, 12+4    ;games
               dc.b     12, 255, 12+4
               dc.b     10, 255, 12+2
               dc.b     255, 255, 255
               dc.b     9, 255, 12
               dc.b     255, 255, 255
               dc.b     7, 255, 10
               dc.b     255, 255, 255


               dc.b     5, 12+9, 12+5     ;Then
               dc.b     255, 255, 255
               dc.b     9, 12+9, 12+5     ;one
               dc.b     255, 255, 255
               dc.b     0, 12+12, 12+9    ;fog-
               dc.b     255, 255, 255
               dc.b     9, 12+12, 12+9    ;gy
               dc.b     255, 255, 255

               dc.b     0, 12+7, 12+4     ;Christ-
               dc.b     255, 255, 255
               dc.b     7, 12+4, 12+0     ;mas
               dc.b     255, 255, 255
               dc.b     4, 12+7, 12+4     ;eve,
               dc.b     255, 255, 255
               dc.b     3, 255, 255
               dc.b     255, 255, 255

               dc.b     2, 12+5, 12+2     ;San-
               dc.b     255, 255, 255
               dc.b     7, 12+9, 12+5     ;ta
               dc.b     255, 255, 255
               dc.b     5, 12+7, 12+4     ;came
               dc.b     255, 255, 255
               dc.b     7, 12+5, 12+2     ;to
               dc.b     255, 255, 255

               dc.b     0, 12+4, 12       ;say
               dc.b     255, 255, 255
               dc.b     12, 255, 12+4
               dc.b     12, 255, 12+4
               dc.b     11, 255, 12+2
               dc.b     11, 255, 12+2
               dc.b     9, 255, 12
               dc.b     9, 255, 12

               dc.b     2, 12+2, 11       ;Ru-
               dc.b     255, 255, 255
               dc.b     11, 12+2, 11      ;dolph
               dc.b     255, 255, 255
               dc.b     2, 12+7, 12+2     ;with
               dc.b     255, 255, 255
               dc.b     6, 12+9, 12+6     ;your
               dc.b     255, 255, 255

               dc.b     7, 12+11, 12+7    ;nose
               dc.b     255, 255, 255
               dc.b     2, 12+11, 12+7    ;so 
               dc.b     255, 255, 255
               dc.b     7, 12+11, 12+7    ;bright,
               dc.b     255, 255, 255
               dc.b     8, 255, 255
               dc.b     255, 255, 255

               dc.b     9, 12+12, 12+9    ;won't
               dc.b     255, 255, 255
               dc.b     9, 12+12, 12+9    ;you
               dc.b     255, 255, 255
               dc.b     2, 12+11, 12+6    ;guide
               dc.b     255, 255, 255
               dc.b     2, 12+9, 12+6     ;my
               dc.b     255, 255, 255

               dc.b     7, 12+7, 12+2     ;sleigh
               dc.b     7, 255, 255
               dc.b     5, 12+5, 12+2     ;to-
               dc.b     255, 255, 255
               dc.b     4, 12+2, 11       ;night?
               dc.b     255, 255, 255
               dc.b     2, 255, 255
               dc.b     255, 255, 255

               dc.b     0, 12+7, 12+4     ;Then
               dc.b     255, 12+9, 12+4   ;how
               dc.b     7, 255, 255
               dc.b     255, 12+7, 12+4   ;the
               dc.b     4, 12+4, 12       ;child-
               dc.b     255, 255, 255
               dc.b     7, 12+12, 12+4    ;ren
               dc.b     255, 255, 255

               dc.b     0, 12+9, 12+4     ;loved
               dc.b     255, 255, 255
               dc.b     7, 12+7, 12+4     ;him
               dc.b     255, 255, 255
               dc.b     4, 12+12+9, 12+12+4
               dc.b     255, 255, 255
               dc.b     7, 12+12+7, 12+12+4
               dc.b     255, 255, 255

               dc.b     0, 12+7, 12+4     ;as
               dc.b     255, 12+9, 12+5   ;they
               dc.b     7, 12+7, 12+4     ;shou-
               dc.b     255, 12+9, 12+5   ;ted
               dc.b     4, 12+7, 12+4     ;out
               dc.b     255, 255, 255
               dc.b     3, 12+12, 12+9    ;with
               dc.b     255, 255, 255

               dc.b     2, 12+11, 12+2    ;glee
               dc.b     255, 255, 255
               dc.b     7, 12+11, 12+2
               dc.b     255, 12+12, 12+4
               dc.b     5, 12+14, 12+5
               dc.b     255, 255, 255
               dc.b     2, 255, 255
               dc.b     255, 255, 255

               dc.b     7, 12+5, 12+2     ;Ru-
               dc.b     255, 12+7, 12+2   ;dolph,
               dc.b     11, 255, 255
               dc.b     255, 12+5, 12+2   ;the
               dc.b     2, 12+2, 12-1     ;red-
               dc.b     255, 255, 255
               dc.b     5, 12+11, 12+7    ;nosed
               dc.b     255, 255, 255

               dc.b     7, 12+9, 12+4     ;rain-
               dc.b     255, 255, 255
               dc.b     11, 12+7, 12+2    ;deer,
               dc.b     255, 255, 255
               dc.b     2, 12+12+9, 12+12+5
               dc.b     255, 255, 255
               dc.b     5, 12+12+7, 12+12+2
               dc.b     255, 255, 255

               dc.b     7, 12+7, 12+5     ;you'll
               dc.b     255, 12+9, 12+5   ;go
               dc.b     5, 12+7, 12+5     ;down
               dc.b     255, 12+9, 12+5   ;in
               dc.b     4, 12+7, 12+5     ;his-
               dc.b     255, 255, 255
               dc.b     2, 12+12+2, 12+7  ;to-
               dc.b     255, 255, 255

               dc.b     0, 12+12, 12+4    ;ry.
               dc.b     12, 255, 12+4
               dc.b     7, 12+12+7, 12+12+2
               dc.b     255, 255, 255
               dc.b     12, 12+12+7, 12+12+4
               dc.b     7, 255, 255
               dc.b     4, 255, 255
               dc.b     2, 255, 255

               dc.b     254               ; The End
;
xmas_image     dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$EF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$EE,$EE,$DD,$DF
               dc.b     $FF,$FF,$FF,$DE,$CE,$DD,$EF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$BC,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$ED,$CC,$CC,$CC,$CC,$CC,$CD
               dc.b     $FF,$FF,$FF,$FF,$EF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$AC,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EF,$FF,$FF,$FE,$DE,$EE
               dc.b     $EE,$DD,$DC,$DC,$BB,$BC,$CE,$DD
               dc.b     $FF,$FF,$FF,$FF,$EF,$FF,$FF,$C9
               dc.b     $EF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$EC,$EF,$EC
               dc.b     $CA,$6A,$CC,$BA,$CB,$CC,$CE,$FE
               dc.b     $FF,$FF,$EF,$ED,$BF,$FE,$EF,$DC
               dc.b     $EF,$FF,$EF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FE,$DE,$EE,$DD
               dc.b     $DE,$FF,$EE,$ED,$BB,$FB,$9E,$EF
               dc.b     $FF,$FF,$AD,$FD,$CE,$FF,$DF,$EF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$ED,$EE,$FF,$E9
               dc.b     $8F,$FF,$FF,$FE,$CD,$DD,$DC,$CD
               dc.b     $FF,$FF,$FF,$DD,$CC,$EC,$BE,$EF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$EF,$EF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EF,$FF,$FF,$FF,$FF,$FE
               dc.b     $FF,$FF,$FF,$FE,$DD,$DE,$FD,$75
               dc.b     $AA,$DD,$ED,$DC,$9B,$CC,$CC,$BC
               dc.b     $FF,$FF,$FC,$AC,$BD,$DF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$F9,$DF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FB,$BF,$FF,$FF,$FF,$FF,$FE
               dc.b     $EF,$FF,$EB,$BD,$FF,$FF,$FD,$A4
               dc.b     $8B,$EE,$DD,$CC,$99,$AB,$BC,$CC
               dc.b     $FF,$FF,$EB,$BC,$DF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$C7,$BD,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$D5,$7D,$FF,$DD,$FF,$FF,$FF
               dc.b     $FF,$FF,$EC,$DE,$FF,$FC,$96,$57
               dc.b     $77,$CB,$DE,$DD,$B9,$BB,$BB,$CE
               dc.b     $FF,$FD,$AD,$EF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FE,$97,$89,$BF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
               dc.b     $CA,$65,$49,$BB,$6B,$FF,$FF,$FF
               dc.b     $FF,$FF,$BC,$EF,$FF,$C5,$77,$56
               dc.b     $BA,$7A,$EE,$FD,$CB,$BB,$CC,$DF
               dc.b     $FF,$DC,$CF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$DC,$D9,$B9,$77,$77,$79
               dc.b     $CE,$EF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$EC,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $F7,$55,$89,$AE,$FF,$FF,$FF,$FF
               dc.b     $FF,$FE,$DE,$FF,$D7,$54,$54,$56
               dc.b     $AD,$D5,$CC,$FF,$DC,$BB,$CC,$CD
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EE,$BA,$99,$87,$78,$87
               dc.b     $9B,$CE,$FF,$FF,$FF,$CF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$C7,$EF,$FF,$FF
               dc.b     $DE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $C6,$BB,$87,$AF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EF,$FE,$B2,$33,$25,$89
               dc.b     $BD,$D4,$87,$EE,$FE,$CD,$CD,$DD
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$D9,$66,$79,$CE
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$D8,$9E,$FD,$A7
               dc.b     $9F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $CE,$FF,$FC,$8F,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EF,$FF,$FB,$29,$43,$CA
               dc.b     $8A,$86,$3D,$FC,$EE,$EE,$DD,$ED
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FD,$97,$8B,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$85,$67,$A9,$8B
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FD,$2B,$94,$BA
               dc.b     $AC,$85,$9F,$FF,$DD,$DD,$DE,$DD
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$D6,$68,$64,$CE
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$D9,$56,$67,$99,$BF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$F9,$3F,$C6,$BB
               dc.b     $AC,$64,$CF,$FF,$FF,$FF,$FF,$FE
               dc.b     $FF,$FF,$FF,$EC,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FB,$EF,$B2,$5B,$41,$5C
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FE,$98,$68,$76,$76,$99,$9F
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$ED,$7D,$FA,$DB
               dc.b     $ED,$B7,$CE,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$EE,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$A5,$32,$22,$6E
               dc.b     $FF,$FF,$F8,$DF,$FF,$FF,$FF,$FF
               dc.b     $FF,$E9,$98,$BC,$66,$77,$78,$89
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$EE
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FE,$67,$A8,$EA
               dc.b     $E6,$CA,$CF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$EE,$FF
               dc.b     $FF,$FF,$FE,$F9,$76,$42,$23,$57
               dc.b     $9F,$FF,$EA,$EF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$75,$9D,$BC,$B8
               dc.b     $DF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$D2,$11,$6E
               dc.b     $DA,$CE,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FD,$7C,$FF
               dc.b     $FF,$FF,$C4,$58,$53,$33,$43,$59
               dc.b     $8E,$FF,$F7,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$EF,$FF,$FE,$8A,$EF,$FF,$EC
               dc.b     $AE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FC,$42,$5C
               dc.b     $CF,$FF,$FF,$FE,$8E,$FF,$FF,$FF
               dc.b     $FF,$FF,$FE,$AE,$FF,$FF,$8C,$FF
               dc.b     $FF,$FC,$51,$12,$64,$76,$44,$38
               dc.b     $54,$BF,$C6,$FF,$FF,$FF,$FF,$FF
               dc.b     $FE,$DF,$FF,$FD,$BF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$61,$38
               dc.b     $FF,$FF,$FF,$FE,$BF,$FF,$FF,$FF
               dc.b     $FD,$ED,$EE,$FF,$FF,$FF,$6B,$FF
               dc.b     $FF,$C2,$12,$01,$21,$31,$11,$11
               dc.b     $11,$16,$75,$DF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$EE,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FE,$81,$58
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$EE,$DF,$FF,$FF,$FE,$67,$FD
               dc.b     $DF,$FB,$99,$41,$11,$13,$76,$51
               dc.b     $11,$11,$28,$FF,$EB,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$EF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$B5,$79
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FE,$DD,$EF,$FF,$FD,$AA,$47,$85
               dc.b     $87,$9C,$75,$31,$12,$12,$45,$42
               dc.b     $23,$42,$6A,$94,$26,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$BE,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$F7,$9F
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$EE,$FF,$FF,$E6,$23,$33,$45
               dc.b     $44,$64,$34,$20,$13,$12,$22,$22
               dc.b     $23,$45,$33,$15,$4A,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FA,$7F
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
               dc.b     $FF,$DE,$FF,$FF,$A2,$22,$22,$33
               dc.b     $46,$56,$53,$33,$66,$51,$33,$34
               dc.b     $43,$45,$52,$37,$8B,$FF,$DC,$EF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $EF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$DC,$CD,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$C8,$9F
               dc.b     $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FE
               dc.b     $FF,$FF,$FF,$FC,$22,$12,$12,$12
               dc.b     $25,$45,$A5,$7A,$B5,$57,$87,$43
               dc.b     $36,$85,$45,$66,$87,$B9,$37,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
               dc.b     $DE,$FF,$FF,$FF,$FF,$FF,$FE,$B9
               dc.b     $64,$23,$22,$22,$6A,$EF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$CB,$BF
               dc.b     $FE,$FF,$FF,$FF,$FF,$FF,$FF,$EE
               dc.b     $FF,$FF,$FF,$FE,$C6,$25,$98,$84
               dc.b     $35,$66,$65,$76,$53,$34,$66,$23
               dc.b     $55,$56,$65,$66,$99,$A7,$25,$BF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$DD,$CC
               dc.b     $EF,$FF,$FF,$FF,$FF,$BD,$61,$00
               dc.b     $00,$11,$12,$22,$22,$3A,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$CB,$AF
               dc.b     $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FE
               dc.b     $FF,$FF,$FF,$FF,$FE,$AE,$FF,$C2
               dc.b     $44,$66,$65,$43,$45,$67,$52,$33
               dc.b     $44,$22,$69,$BD,$9A,$A5,$46,$7F
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$CC,$DE
               dc.b     $EF,$FF,$FF,$FF,$FA,$EF,$B2,$01
               dc.b     $11,$12,$22,$22,$22,$12,$9F,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$EC,$9F
               dc.b     $FF,$FE,$FF,$FC,$DD,$FF,$FF,$FF
               dc.b     $FF,$DF,$FF,$FF,$FF,$FF,$FF,$DB
               dc.b     $DA,$32,$54,$35,$33,$44,$23,$33
               dc.b     $46,$31,$8C,$56,$67,$D7,$46,$AD
               dc.b     $FF,$FF,$FF,$FF,$FF,$ED,$CE,$FE
               dc.b     $EF,$FF,$FF,$EE,$B5,$8D,$FC,$41
               dc.b     $12,$22,$22,$22,$21,$11,$38,$FE
               dc.b     $DF,$FF,$FF,$FF,$FF,$FF,$9B,$BF
               dc.b     $FF,$FE,$FF,$FB,$FF,$FF,$FF,$FF
               dc.b     $FF,$DF,$FF,$FF,$FF,$FF,$F8,$7A
               dc.b     $8A,$21,$22,$24,$52,$11,$12,$14
               dc.b     $86,$84,$21,$11,$03,$31,$12,$58
               dc.b     $6F,$FF,$EF,$FF,$FF,$DD,$DF,$FF
               dc.b     $FF,$FF,$C9,$53,$56,$63,$8F,$F8
               dc.b     $22,$33,$32,$22,$23,$44,$35,$56
               dc.b     $DF,$FF,$FF,$FF,$FF,$FF,$EE,$CF
               dc.b     $FF,$EE,$EE,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$F7,$DF,$FF,$51,$11
               dc.b     $01,$23,$21,$11,$21,$13,$32,$12
               dc.b     $66,$76,$41,$11,$10,$00,$22,$11
               dc.b     $6E,$FF,$DD,$FF,$FF,$FF,$EF,$FE
               dc.b     $FE,$FC,$CF,$D6,$23,$59,$4F,$FF
               dc.b     $53,$33,$33,$21,$5E,$FF,$B4,$27
               dc.b     $DF,$FF,$FF,$FF,$FF,$FF,$AC,$AF
               dc.b     $FF,$ED,$DE,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$F7,$EF,$FF,$52,$11
               dc.b     $4A,$CF,$B6,$31,$23,$23,$43,$23
               dc.b     $33,$11,$12,$21,$11,$00,$11,$27
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $EF,$EE,$FF,$FE,$53,$45,$8C,$FF
               dc.b     $FA,$53,$32,$26,$FF,$FF,$63,$BF
               dc.b     $FF,$FF,$FD,$FF,$FF,$FF,$6B,$9F
               dc.b     $FE,$EE,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$F3,$BE,$FA,$66,$46
               dc.b     $48,$CD,$FD,$32,$46,$11,$33,$24
               dc.b     $68,$62,$11,$11,$5D,$A4,$2B,$EF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $CF,$AE,$FF,$FF,$75,$55,$66,$AF
               dc.b     $FE,$D8,$11,$AF,$FE,$DF,$95,$5E
               dc.b     $FF,$FF,$DF,$FF,$FF,$FF,$AD,$9F
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FE,$94,$55,$75,$45,$68
               dc.b     $CA,$BD,$CE,$DC,$78,$46,$A9,$AB
               dc.b     $AA,$88,$88,$55,$8D,$CE,$DF,$FF
               dc.b     $FF,$FB,$FF,$FF,$FF,$FF,$EF,$FF
               dc.b     $D9,$36,$FF,$FF,$55,$54,$66,$68
               dc.b     $CF,$F7,$57,$FF,$ED,$DF,$FA,$8C
               dc.b     $DF,$FF,$FF,$FF,$FF,$FF,$AD,$BF
               dc.b     $FE,$EF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FD,$77,$55,$56,$57,$9A
               dc.b     $CA,$A6,$23,$CC,$67,$86,$AA,$BC
               dc.b     $C9,$A8,$CB,$CB,$BC,$8A,$FF,$FF
               dc.b     $FE,$8A,$FF,$FF,$FF,$FE,$EF,$FF
               dc.b     $CD,$BD,$FF,$FC,$79,$AA,$46,$56
               dc.b     $7E,$F8,$9A,$FF,$ED,$EF,$FF,$EE
               dc.b     $BD,$FF,$FF,$FF,$FF,$FF,$9D,$FF
               dc.b     $FE,$EF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FA,$46,$66,$64,$89,$97
               dc.b     $79,$60,$23,$45,$49,$A7,$6B,$DD
               dc.b     $D9,$9C,$98,$88,$AA,$AA,$B8,$6F
               dc.b     $FF,$8D,$FF,$FF,$FF,$FF,$DE,$FF
               dc.b     $DF,$DF,$FF,$F6,$56,$55,$44,$65
               dc.b     $5B,$FE,$FF,$FF,$ED,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FE,$CB,$FF
               dc.b     $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$DA,$AD,$A4,$67,$76
               dc.b     $89,$61,$12,$11,$24,$42,$13,$95
               dc.b     $A4,$6A,$AA,$BD,$95,$64,$75,$6A
               dc.b     $DB,$6D,$FF,$FF,$FF,$FF,$ED,$DF
               dc.b     $DE,$CC,$FE,$82,$55,$45,$55,$65
               dc.b     $46,$DF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FE,$BB,$DF
               dc.b     $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FA,$78,$87
               dc.b     $67,$62,$22,$22,$46,$43,$53,$53
               dc.b     $32,$43,$23,$33,$34,$23,$55,$43
               dc.b     $67,$3F,$FF,$FF,$FF,$DE,$FE,$CC
               dc.b     $FD,$D8,$64,$24,$44,$55,$54,$43
               dc.b     $3A,$FF,$FF,$FF,$FF,$FF,$FF,$DC
               dc.b     $EF,$FF,$FF,$FF,$FF,$FE,$AC,$AE
               dc.b     $FF,$FF,$FF,$FF,$FF,$ED,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FC,$67,$59,$58
               dc.b     $78,$84,$44,$35,$33,$46,$B5,$11
               dc.b     $11,$11,$22,$22,$33,$43,$34,$55
               dc.b     $89,$4C,$FF,$BD,$FF,$EC,$DE,$DD
               dc.b     $EE,$FC,$64,$34,$43,$55,$54,$57
               dc.b     $DF,$FF,$FD,$99,$9D,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$BD,$AF
               dc.b     $FF,$FF,$FF,$FF,$FF,$BE,$FF,$EA
               dc.b     $FF,$FF,$FF,$FF,$FC,$44,$43,$44
               dc.b     $66,$42,$54,$43,$23,$34,$51,$22
               dc.b     $02,$21,$12,$22,$33,$23,$65,$66
               dc.b     $7A,$CF,$FF,$BC,$FF,$ED,$DE,$EE
               dc.b     $EE,$EE,$DA,$44,$45,$55,$69,$EF
               dc.b     $FF,$DA,$53,$13,$65,$49,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FE,$8C,$AE
               dc.b     $FF,$FF,$FD,$FF,$FF,$FF,$FF,$FE
               dc.b     $6C,$FF,$F9,$FF,$E6,$34,$44,$44
               dc.b     $74,$55,$74,$33,$33,$46,$43,$11
               dc.b     $15,$22,$23,$33,$33,$32,$36,$86
               dc.b     $65,$6A,$FD,$AD,$FF,$FE,$CD,$DD
               dc.b     $EE,$FF,$FF,$55,$66,$66,$CF,$FF
               dc.b     $FC,$41,$58,$8B,$CB,$54,$7F,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FD,$6A,$8F
               dc.b     $FB,$EF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $73,$69,$B5,$67,$23,$12,$23,$65
               dc.b     $99,$78,$76,$54,$33,$34,$53,$23
               dc.b     $30,$22,$27,$78,$63,$33,$48,$86
               dc.b     $55,$69,$B8,$59,$FF,$FF,$CC,$DD
               dc.b     $EE,$DD,$FF,$54,$66,$AF,$FF,$FF
               dc.b     $C3,$24,$AC,$BC,$AA,$A5,$29,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FE,$BC,$6E
               dc.b     $BF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $B1,$38,$78,$77,$21,$10,$11,$35
               dc.b     $88,$36,$46,$98,$31,$24,$74,$36
               dc.b     $74,$52,$23,$55,$43,$43,$34,$35
               dc.b     $57,$68,$65,$39,$FF,$FF,$FD,$DE
               dc.b     $EF,$FF,$FB,$55,$79,$EF,$FF,$FB
               dc.b     $52,$3A,$BA,$AA,$BB,$B7,$47,$AF
               dc.b     $FF,$FF,$FF,$FF,$FE,$DF,$CB,$5D
               dc.b     $DF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $E6,$11,$17,$35,$30,$00,$11,$36
               dc.b     $54,$09,$83,$66,$23,$45,$7A,$7A
               dc.b     $A6,$52,$22,$22,$36,$66,$54,$55
               dc.b     $64,$46,$47,$8A,$FF,$FF,$FD,$DE
               dc.b     $DD,$FF,$F9,$47,$8F,$FF,$FF,$C3
               dc.b     $23,$6A,$BC,$CC,$BC,$C6,$55,$67
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$EB,$3E
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $F9,$30,$11,$10,$01,$01,$11,$22
               dc.b     $01,$26,$33,$57,$7B,$A9,$88,$75
               dc.b     $44,$43,$11,$21,$41,$12,$11,$12
               dc.b     $11,$12,$21,$25,$BA,$8F,$FC,$DF
               dc.b     $ED,$FF,$F9,$88,$CF,$FF,$FE,$32
               dc.b     $23,$22,$44,$44,$54,$55,$44,$44
               dc.b     $7F,$FF,$FF,$FF,$FF,$FF,$FD,$8B
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FB,$84,$11,$00,$11,$33,$45
               dc.b     $62,$48,$56,$DB,$DE,$DC,$44,$44
               dc.b     $44,$55,$77,$11,$00,$00,$13,$10
               dc.b     $11,$12,$22,$42,$5A,$AE,$EC,$DE
               dc.b     $EF,$EE,$B6,$7B,$FF,$FF,$D3,$22
               dc.b     $33,$22,$22,$22,$33,$23,$33,$34
               dc.b     $47,$FF,$FF,$FF,$FF,$FE,$9B,$89
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$E9,$21,$11,$11,$10,$55,$55
               dc.b     $C7,$9C,$BA,$EC,$94,$58,$57,$43
               dc.b     $25,$55,$64,$10,$00,$00,$11,$12
               dc.b     $43,$32,$22,$21,$37,$9E,$ED,$DE
               dc.b     $EF,$FF,$54,$4D,$FF,$FA,$32,$24
               dc.b     $89,$86,$33,$33,$33,$89,$A8,$45
               dc.b     $53,$6C,$FF,$FF,$FF,$FE,$79,$8A
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FA,$20,$01,$11,$10,$12,$12,$61
               dc.b     $23,$43,$35,$43,$22,$21,$36,$41
               dc.b     $01,$25,$31,$01,$41,$11,$11,$11
               dc.b     $31,$21,$32,$21,$69,$9E,$ED,$CE
               dc.b     $EE,$FA,$44,$6F,$FD,$61,$14,$88
               dc.b     $77,$9A,$54,$35,$99,$7A,$BB,$84
               dc.b     $43,$13,$BF,$FF,$FF,$FB,$DE,$58
               dc.b     $EF,$FF,$FF,$FF,$FF,$FF,$EF,$FF
               dc.b     $FF,$C8,$21,$11,$10,$12,$22,$11
               dc.b     $22,$21,$12,$12,$33,$32,$11,$21
               dc.b     $21,$00,$00,$01,$31,$11,$12,$11
               dc.b     $12,$31,$22,$21,$4B,$AE,$FF,$ED
               dc.b     $FF,$F9,$35,$79,$73,$11,$27,$89
               dc.b     $87,$99,$44,$34,$44,$34,$47,$74
               dc.b     $46,$53,$37,$DF,$FF,$F9,$CF,$59
               dc.b     $AF,$FF,$FF,$FF,$FF,$FF,$BF,$FF
               dc.b     $FF,$E9,$74,$63,$22,$22,$11,$21
               dc.b     $11,$12,$23,$12,$11,$11,$02,$33
               dc.b     $32,$10,$00,$11,$22,$11,$02,$22
               dc.b     $22,$11,$11,$11,$14,$79,$AE,$FE
               dc.b     $FF,$F6,$36,$B8,$12,$24,$67,$77
               dc.b     $88,$98,$63,$34,$44,$44,$56,$79
               dc.b     $75,$57,$76,$8C,$FE,$75,$9E,$CA
               dc.b     $8F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FB,$73,$25,$64,$20,$11,$22
               dc.b     $12,$11,$00,$00,$00,$00,$23,$33
               dc.b     $32,$11,$01,$21,$02,$21,$12,$22
               dc.b     $12,$21,$21,$12,$33,$32,$37,$FF
               dc.b     $FF,$FA,$23,$84,$22,$69,$88,$99
               dc.b     $89,$8A,$74,$26,$55,$78,$BC,$AC
               dc.b     $A6,$79,$B7,$8A,$9B,$DF,$FF,$FD
               dc.b     $9D,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$DA,$6D,$D9,$54,$46,$31
               dc.b     $11,$01,$10,$00,$44,$42,$42,$12
               dc.b     $45,$21,$00,$10,$10,$11,$11,$10
               dc.b     $01,$01,$00,$11,$48,$42,$8C,$FF
               dc.b     $FF,$FF,$94,$12,$36,$9A,$C9,$99
               dc.b     $89,$BD,$84,$58,$AB,$CC,$DC,$DF
               dc.b     $ED,$97,$68,$BD,$DD,$AD,$FF,$FF
               dc.b     $CA,$DF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$F6,$23,$33,$33,$45,$33,$10
               dc.b     $11,$11,$21,$10,$45,$31,$11,$21
               dc.b     $13,$32,$11,$23,$31,$11,$00,$02
               dc.b     $76,$10,$11,$11,$11,$12,$29,$FF
               dc.b     $FF,$FF,$D2,$23,$45,$43,$43,$33
               dc.b     $65,$66,$45,$45,$79,$B9,$CD,$CA
               dc.b     $ED,$DA,$AB,$9B,$EF,$FE,$FF,$FE
               dc.b     $7E,$CD,$EF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$F5,$11,$11,$12,$14,$31,$11
               dc.b     $11,$17,$61,$11,$00,$01,$12,$22
               dc.b     $20,$32,$12,$23,$32,$33,$11,$01
               dc.b     $21,$10,$00,$11,$65,$56,$5A,$FF
               dc.b     $FF,$FF,$B2,$13,$43,$24,$57,$77
               dc.b     $78,$89,$99,$88,$9A,$A9,$AA,$BB
               dc.b     $DD,$DB,$A4,$6F,$FF,$EC,$AD,$DB
               dc.b     $7A,$99,$89,$EF,$FF,$FF,$FF,$FF
               dc.b     $FF,$F4,$12,$22,$22,$22,$11,$10
               dc.b     $11,$06,$90,$00,$00,$01,$21,$00
               dc.b     $01,$21,$10,$00,$10,$00,$00,$00
               dc.b     $00,$00,$01,$12,$77,$88,$67,$BE
               dc.b     $CF,$FF,$FC,$76,$59,$A6,$44,$66
               dc.b     $AC,$CA,$98,$9A,$BB,$BD,$BD,$DC
               dc.b     $DB,$F9,$9A,$DF,$EE,$9B,$EF,$EE
               dc.b     $FF,$FF,$C6,$9E,$FF,$FF,$FF,$FF
               dc.b     $FF,$FA,$32,$22,$22,$12,$23,$32
               dc.b     $24,$8A,$84,$89,$AB,$BB,$97,$37
               dc.b     $82,$21,$12,$00,$14,$44,$34,$32
               dc.b     $11,$23,$35,$47,$DC,$AA,$76,$47
               dc.b     $4B,$CC,$FA,$AA,$BD,$EC,$BE,$FE
               dc.b     $FF,$FF,$ED,$CC,$DD,$FF,$FE,$AD
               dc.b     $ED,$BA,$EF,$FF,$EF,$FE,$FF,$FE
               dc.b     $EF,$FF,$FE,$DF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EE,$EE,$ED,$DC,$DD,$DA
               dc.b     $DF,$FE,$DF,$FF,$AB,$CA,$BD,$EE
               dc.b     $FE,$EC,$BD,$CA,$DF,$FF,$FF,$EE
               dc.b     $EE,$EF,$FF,$FF,$FF,$FF,$FD,$DE
               dc.b     $DE,$DE,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FD,$FF,$FF,$FF,$FE
               dc.b     $B8,$79,$DF,$FD,$EF,$FF,$FF,$FF
               dc.b     $FF,$FD,$DF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FE,$FF,$FF,$FF,$FB,$D9
               dc.b     $BF,$FD,$CF,$CF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EC,$DF,$FF,$FF,$FF,$D7
               dc.b     $8D,$FF,$FB,$BF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$CE,$EE,$BE,$CF,$EB,$9C
               dc.b     $AC,$FF,$DA,$BD,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$CD,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EE,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$EE,$FF,$FF,$FF,$FF,$DE
               dc.b     $FF,$EF,$DD,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FD,$DC,$DF
               dc.b     $FF,$EE,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$EF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
               dc.b     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
;
               end