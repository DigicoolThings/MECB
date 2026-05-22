;   DigiBug - for MECB 6802 CPU Card
;   ================================
;
;   Based on Ed Smith's SmithBug code and Mike Lee's updates / corrections.
;
;   Amended for assembly with the ASL Assembler, including various updates.
;   Also, significant addition of comments (as I work through the code) and
;   updated for various bug fixes and adding other corrections & improvements.
;
;   Renamed to DigiBug as the Routine Call Addresses differ from MIKBUG / SmithBug.
;   i.e. Retaining the SmithBug name would imply that SmithBug compatible
;    pre-assembled code would work (which it won't, as call address have changed).
;   To resolve this, DigiBug instead implements a new fixed location Jump Table.
;
;   SmithBug / DigiBug prompt is '> '
;
;   Summary of available Commands:
;       A	Change A pseudoregister and display pseudoregisters 
;       B	Change B pseudoregister and display pseudoregisters 
;       C	Change condition codes pseudoregister and display 
;       	pseudoregisters 
;       D	Disassemble code in memory 
;       E	Examine (or examine and change) a memory location 
;       F	Find a specified byte in a memory block 
;       G	Go to location in PC pseudoregister and execute 
;       H   Help (display Command list)
;       I	Insert a specified value in all locations of a memory 
;       	block  
;       J	Jump to address to be specified 
;       K	Continue with trace at pseudoregister program
;       	counter location 
;       L   Load (S1/S9 format)
;       M	Move a block of memory 
;       N	Inhibit echo to system terminal 
;       O	Allow echo to system terminal 
;       R	Display pseudoregisters (user's stack) 
;       S	Change pseudoregister stack address and display resulting 
;       	pseudoregisters 
;       T	Trace (execute) a program one instruction at a time 
;       V	View a 128-byte block of memory 
;       X	Change X pseudoregister and display pseudoregisters 
;       @	Insert ASCII characters from keyboard 
;       *   Jump to Start (Reset vector)
;
;   Commands that are currently non-operation (to be investigated)
;       1	Set one breakpoint in program and execute beginning at 
;       	pseudoregister program counter location 
;       2	Set two breakpoints and execute as above 
;
;
        CPU     6800        ; Specify MC6800 processor code (asl Assembler)
;
        ORG     $DF00       ; Start of RAM workspace
;
IOV     RMB     2           ; IRQ Interrupt vector
BEGA    RMB     2           ; Entered Begin Address (Start)
ENDA    RMB     2           ; Entered End Address (Thru)
NIO     RMB     2           ; NMI Interrupt vector (initially set to SWI vector)
SP      RMB 2
ACIAT   RMB     1           ; ACIA control register setting
ECHO    RMB     1           ; Echo On = non-zero Flag
ADDRHI  RMB     1           ; Temporary Address (Hi)
ADDRLO  RMB     1           ; Temporary Address (Lo)
TEMP    RMB 1
TW      RMB 2
TFLAG   RMB 1
XTEMP   RMB     2           ; Temporary X register (for 16 bit addition)
BKFLG   RMB 1
SWIPTR  RMB     45          ; SWI Interrupt vector
STACK   RMB     8           ; STACK allocated 8 bytes for SP+7 initial R values
PRINTR  RMB 3
BFLAG   RMB 1
MFLAG   RMB 1
XFLAG   RMB 1
BITE2   RMB 1
BITE3   RMB 15
TSTACK  RMB 2
OPSAVE  RMB 1
PB1     RMB 1
PB2     RMB 1
PB3     RMB 1
BYTECT  RMB 1
PC1     RMB 1
PC2     RMB 1
BPOINT  RMB 3
BKFLG2  RMB 1
MCONT   RMB 1
RECTYP  RMB     1           ; S1/S9 Record Type
BYTECNT RMB     1           ; S1/S9 Line byte count
CHKSUM  RMB     1           ; S1/S9 calculated checksum
;
; ACIA address for MECB 6802 CPU (56K/8K/E0 Memory Map)
; 
ACIACS  EQU     $E008       ; ACIA control/status (Motorola IO Card)
ACIADA  EQU     ACIACS+1    ; ACIA data
;
EOT     EQU     $04         ; EOT control character
BS      EQU     $08         ; BS (Backspace) control character
SPC     EQU     $20         ; Space character   
;
; ROM Start / IO Page for MECB 6802 CPU (56K/8K/E0 Memory Map)
; 
        ORG     $E000
;
; Build an 8K ROMable image with first 256 bytes unused (overwritten by IO page)
;
; Fill the space up to the start of usable ROM space with $FF
;
        dc.b    [(*+($E100-*))&$E100-*]$FF
;
        ORG     $E100           ; Start of usable ROM space
;
; Fixed Jump Table to standard routines (standardise routine call addresses)
;
_START  JMP     START       ; Cold start / reset - monitor entry point
_CONTRL JMP     CONTRL      ; Warm start - monitor entry point
_OQSTNE	JMP     OQSTNE      ; Output Question Mark "?" and Exit to CONTRL
_INADDR JMP     INADDR      ; Input 4 digit Hex Address (to X & ADDRHI/LO)
_INBYTE	JMP     INBYTE      ; Input 2 digit Hex Byte (to A)
_OUTCH	JMP     OUTEEE      ; Output character (redirect to OUTEEE)
_INCH   JMP     INEEE       ; Input character (Redirect to INEEE)
_OUTSTR	JMP     OUTSTR      ; Output EOT terminated string at X
_OUT2H	JMP     OUT2H       ; Output 2 Hex digits of byte at X (X = X+1)
_OUT4HS	JMP     OUT4HS      ; Output 4 Hex digits and space of 2 bytes at X (X = X+2)
_OUT2HS	JMP     OUT2HS      ; Output 2 Hex digits and space of byte at X (X = X+2)
_OCRLF  JMP     OCRLF       ; Output Carriage Return / Line Feed
;
; Monitor Cold Start (Reset) entry point
;
START   LDS     #STACK      ; Initialise Stack Pointer
        STS     SP
        LDAA    #1          ; Set ECHP flag (non-zero)
        STAA    ECHO        ; ECHO On
        LDX     #SFE        ; Initialise SWI & NMI vectors
        STX     SWIPTR
        STX     NIO
;
; ACIA Initialise
;
        LDAA    #$03        ; Reset ACIA
        STAA    ACIACS
        NOP
        NOP
        NOP
        LDAA    #$15        ; /16, 8N1, RTS Low, Interrupt Disabled
        STAA    ACIACS
        STAA    ACIAT       ; Save ACIA Command Register settings
;
; Cold Start Prompt
;
        LDX     #CSPRMPT    ; Display the full Cold Start title
        BSR     OUTSTR
;
; Monitor Warm Start (Command Control)
;
CONTRL  LDAA    ACIAT       ; Restore ACIA to DigiBug setting
        STAA    ACIACS
        LDS     #STACK      ; Reset CONTRL Stack Pointer
        CLR     TFLAG
        CLR     BKFLG
        CLR     BKFLG2
        LDX     #PROMPT     ; Display the prompt
        BSR     OUTSTR
        BSR     INCH        ; Await a command character
        TAB
        JSR     OUTS
;
; Check if Command is Valid and Jump to routine
;
        LDX     #FUTABL     ; Point X at command table
NXTCHR  CMPB    0,X         ; Does entry = B (command)
        BEQ     GOODCH      ; Yes, jump to routine
        INX                 ; No, skip to next command
        INX                 ;
        INX                 ;
        CPX     #TBLEND     ; Are we at the end of the table?
        BNE     NXTCHR      ; No, check next command
        JMP     CKCBA ;
;
GOODCH  LDX     1,X
        JMP     0,X         ; Jump to command routine
;
; IRQ Interrupt Vector Redirect
;
IO      LDX     IOV
        JMP     0,X
;
; NMI Interrupt Vector Redirect
;
POWDWN  LDX     NIO
        JMP     0,X
;
; SWI Interrupt Vector Redirect
;
SWI     LDX     SWIPTR
        JMP     0,X
;
; OQSTNE routine
;
; Function:	Output Question Mark "?" and Exit to CONTRL
; Parameters: -
; Returns:	-
; Destroys:	A
OQSTNE  LDAA    #$3F        ; Print question mark "?"
        BSR     OUTCH
C1      BRA     CONTRL      ; Exit to CONTRL
;
; Build Address routine
;
; Function:
; Parameters: -
; Returns:	- X / ADDRHI = Entered address
; Destroys:	- A,B
INADDR  BSR     INBYTE
        STAA    ADDRHI
        BSR     INBYTE
        STAA    ADDRLO
        LDX     ADDRHI
        RTS
;
; Input One Byte routine
;
; Function: Input Byte. Return A = $00..$FF, else Exit to CONTRL
; Parameters: -
; Returns:	- A = $00..$FF
; Destroys:	- A, B
INBYTE  BSR     INHEX
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR     INHEX
        ABA
        RTS
;
;  OUTPUT LEFT HEX NUMBER
;
OUTHL   LSRA
        LSRA
        LSRA
        LSRA
;
;  OUTPUT RIGHT HEX NUMBER
;
OUTHR   ANDA    #$F
        ADDA    #$30
        CMPA    #$39
        BLS     OUTCH
        ADDA    #$7
OUTCH   JMP     OUTEEE      ; Redirect to OUTEEE
;
INCH    JMP     INEEE       ; Redirect to INEEE
;
OUTST2  JSR     OUTEEE      ; Ouput Character
        INX                 ; Point at next character
OUTSTR  LDAA    0,X         ; Read next character
        CMPA    #EOT        ; Is it EOT?
        BNE     OUTST2      ; No, do next character
        RTS                 ; Exit if EOT
;
; Edit (Change) Memory
;
CHANGE  BSR     INADDR
CHA51   LDX     #PROMPT
        BSR     OUTSTR
        BSR     OUTAHI
        BSR     OUT2HS
        STX     ADDRHI
        BSR     INCH
        CMPA    #SPC        ; Space to go forward an address
        BEQ     CHA51
        CMPA    #BS         ; Backspace to go back an address
        BNE     CHM1
        DEX
        DEX
        STX     ADDRHI
        BRA     CHA51
CHM1    BSR     INHEX+2
        BSR     INBYTE+2
        DEX
        STAA    0,X
        CMPA    0,X         ; Check Byte stored OK (ie. was RAM)
        BEQ     CHA51
;
XBK     BRA     OQSTNE      ; Print question mark "?" and exit to CONTRL
;
; INHEX - Input Hex character. Return A = $00..$0F, else Exit to CONTRL
;
INHEX   BSR     INCH
        SUBA    #$30        ; Do we have 0..9 ?
        BMI     C1          ; <"0". Exit to CONTRL
        CMPA    #$9
        BLE     IN1HG       ; Yes. We have 0..9
        CMPA    #$11        ; Do we have A..F ?
        BMI     C1          ; No. Exit to CONTRL
        CMPA    #$16
        BGT     C1          ; No. Exit to CONTRL
        SUBA    #$7         ; Yes. We have A..F. Return A = $00..$0F
IN1HG   RTS
;
;
OUT2H   LDAA    0,X
        BSR     OUTHL
        LDAA    0,X
        INX
        BRA     OUTHR
;
OUT4HS  BSR     OUT2H
OUT2HS  BSR     OUT2H
OUTS    LDAA    #SPC        ; Ouput a space character and return
        BRA     OUTCH
;
; SET BREAK POINTS
;
BKPNT2  JSR ADDR
        STX PC1
        LDAA 0,X
        STAA BKFLG2
        BEQ XBK
        LDAA #$3F
        STAA 0,X
BKPNT   JSR ADDR
        STX PB2
        LDAA 0,X
        STAA BKFLG
        BEQ XBK
        LDAA #$3F
        STAA 0,X
        JSR OCRLF
;
; FALL INTO GO COMMAND
;
CONTG   LDS SP
        RTI
;
; PRINT ADDRHI ADDRESS SUB
;
OUTAHI  LDX #ADDRHI
        BSR OUT4HS
        LDX ADDRHI
        RTS
;
; VECTORED SWI ROUTINE
;
SFE     STS SP
        TSX
        TST 6,X
        BNE *+4
        DEC 5,X
        DEC 6,X
        LDS #TSTACK
        TST TFLAG
        BEQ PRINT
        LDX PC1
        LDAA OPSAVE
        STAA 0,X
        TST BFLAG
        BEQ DISPLY
        LDX BPOINT
        LDAA BPOINT+2
        STAA 0,X
DISPLY  JMP RETURN
;
; Print Registers
;
PRINT   LDX     SP          ; Initialise X with saved Stack Pointer
        LDAA    #6
        STAA    MCONT
        LDAB    1,X         ; Load A with CC register
        ASLB
        ASLB
        LDX     #CSET
;
DSOOP   LDAA    #$2D        ; Load A with "-"
        ASLB
        BCC     DSOOP1
        LDAA    0,X         ; If CC bit set, load A with bit character
DSOOP1  JSR     OUTEEE      ; Output character (or "-" if bit wasn't set)
        INX                 ; Next CC bit
        DEC     MCONT       ; Have we done all 6 CC bits?
        BNE     DSOOP       ; If not, do next one
        LDX     #BREG
        BSR     PDAT
        LDX     SP          ; Initialise X with saved Stack Pointer
        INX                 ; Point X at B register content
        INX
        JSR     OUT2HS      ; Output 2 Hex Digits (at X location)
        STX     TEMP        ; Save X
        LDX     #AREG       ; Ouput "A="
        BSR     PDAT
        LDX     TEMP        ; Restore X
        JSR     OUT2HS
        STX     TEMP
        LDX     #XREG
        BSR     PDAT
        LDX     TEMP
        BSR     PRTS
        STX     TEMP
        TST     TFLAG
        BNE     PNTS
        LDX     #PCTR
        BSR     PDAT
        LDX     TEMP
        BSR     PRTS
PNTS    LDX     #SREG
        BSR     PDAT
        LDX     #SP
        TST     TFLAG
        BNE     PRINTS
        BSR     PRTS
;
; CHECK IF ANY BREAK POINTS ARE SET
;
        LDAA BKFLG
        BNE C2
        LDX PB2
        STAA 0,X
        LDAA BKFLG2
        BEQ C2
        LDX PC1
        STAA 0,X
C2      JMP     CONTRL

;
PDAT    JMP     OUTSTR      ; Redirct to OUTSTR routine
;
; Set ECHO state
;
ECHON   LDAB    #1          ; Echo On = Non-zero Flag
        BRA     C3
ECHOFF  CLRB                ; Echo Off = Zero Flag
C3      STAB    ECHO
        JMP     CONTRL
;
; Print Stack Pointer
;
PRINTS  LDAB    0,X
        LDAA    1,X
        ADDA    #7
        ADCB    #0
        STAB    TEMP
        STAA    TEMP+1
        LDX     #TEMP
PRTS    JMP     OUT4HS
;
; INEEE- Input one character into A register (no parity)
;
INEEE   LDAA    ACIACS      ; Check if byte received
        ASRA                ; Rotate RDR bit into Carry
        BCC     INEEE       ; Receive not ready
        LDAA    ACIADA      ; Input received character
        ANDA    #$7F        ; Remove 8th bit / Parity bit
        BEQ     INEEE       ; Ignore NUL character
        CMPA    #$7F        ; Check not a zero byte
        BEQ     INEEE       ; Ignore DEL (Rubout) character
        TST     ECHO        ; If ECHO On (non-zero) send Character back 
        BNE     OUTEEE
        RTS
;
; OUTEEE- Output one character from A register
;
OUTEEE  PSHA                ; Save A
OUTEEE1 LDAA    ACIACS      ; Check if transmit register empty
        ASRA
        ASRA
        BCC     OUTEEE1     ; Transmit register not empty
        PULA                ; Restore A
        STAA    ACIADA      ; Output A character
        RTS
;
;  HERE ON JUMP COMMAND
;
JUMP    JSR     OCRLF       ; Output new line
        LDX #TOADD
        BSR ENDADD+3
        LDS #STACK
        JMP 0,X
;
;  ASCII IN "@" COMMAND
;
ASCII   BSR     BAD2
        LDX     #VALASC
        JSR     OUTSTR
        LDX     ADDRHI
        INX                 ; Initially negate the address move back
ASC01   DEX                 ; Move back an address
ASC02   BSR     INEEE       ; Input character
        CMPA    #BS         ; Test for Backspace character
        BEQ     ASC01
        STAA    0,X         ; Store input character
        CMPA    #EOT        ; If Ctrl-D was entered (EOT) exit to CONTRL
        BEQ     CR9
        INX                 ; Point to next address
        BRA     ASC02       ; Get next input character
;
; "I" Insert Byte in Memory Address range
;
IFILL   BSR     LIMITS      ; Input Address From (BEGA) / Thru (ENDA)       
        BSR     VALUE       ; Input the Byte value to insert
        LDX     BEGA        ; Load From Address
        DEX                 ; Initial Address decrement (to negate INX) 
IFILL2  INX                 ; Go to next Address
        STAA    0,X         ; STore Byte value at the address
        CPX     ENDA        ; Have we stored at the End Address?
        BNE     IFILL2      ; No, so continue inserting Bytes
        JMP     CONTRL      ; Yes, we've finished so exit to CONTRL
;
; Input Address / Address range subroutines
;
BAD2    LDX #FROMAD
        BRA *+5
ENDADD  LDX #THRUAD
        JSR OUTSTR
        JMP INADDR
LIMITS  BSR BAD2
        STX BEGA
        BSR ENDADD
        STX ENDA
        JMP OCRLF
ADDR    LDX #ADASC
        BRA ENDADD+3
VALUE   LDX #VALASC
        JSR OUTSTR
        JMP INBYTE
;
; BLOCK MOVE "M" COMMAND
;
MOVE    BSR LIMITS
        LDX #TOADD
        BSR ENDADD+3
        BSR MOVE2
CR9     JMP CONTRL
;
MOVE2	LDX BEGA
        DEX
BMC1    INX
        LDAA 0,X
        STX BEGA
        LDX ADDRHI
        STAA 0,X
        INX
        STX ADDRHI
        LDX BEGA
        CPX ENDA
        BNE BMC1
        RTS
;
; "F" Command - Search (Find) Byte
;
FIND    BSR LIMITS
        BSR VALUE
        TAB
        LDX BEGA
        DEX
SMC1    INX
        LDAA 0,X
        CBA
        BNE SMC2
        STX ADDRHI
        BSR OCRLF
        JSR OUTAHI
SMC2    CPX ENDA
        BNE SMC1
        JMP     CONTRL
;
;  SUB ROUTINE TO ADD SPACE
;
SKIP    LDAA #SPC           ; Output B number of space characters
        JSR OUTEEE          ; Output A character
        DECB 
        BNE SKIP
        RTS
;
;  PRINT BYTE IN A REGISTER
;
PNTBYT  STAA BYTECT
        LDX #BYTECT
        JMP OUT2H
;
; Output a CR/LF
;
OCRLF   LDX     #CRLFAS
        JMP     OUTSTR
;
;  DISASSEMBLE "D" COMMAND
;
DISSA   JSR BAD2
        BRA DISS
;
;  TRACE COMMAND "T"
;
TRACE   JSR     BAD2        ; Build Address (From Addr)
        BSR     OCRLF       ; Output new line
        LDX     SP          ; Load X with saved Stack Pointer address
        LDAB    ADDRHI      ; Store the Address in the PC stack location
        STAB    6,X
        LDAA    ADDRLO
        STAA    7,X
KONTIN  INC     TFLAG
RETURN  JSR     PRINT
        LDX     SP
        LDX     6,X
DISS    STX     PC1         ; Save the Trace Address at PC1
DISIN   BSR     OCRLF
        LDX     #PC1
        JSR     OUT4HS      ; Output the 4 digit Trace address
        LDX     #BFLAG      ; CLear BFLAG/MFLAG/XFLAG/BITE2/BITE3
        LDAA    #5
CLEAR   CLR     0,X
        INX
        DECA
        BNE     CLEAR
        LDX     PC1         ; Restore X with the Trace address
        LDAB    0,X
        JSR     OUT2HS      ; Output 2 Digit byte at Trace Address
        STX     PC1
        LDAA    0,X
        STAA    PB2
        LDAA    1,X
        STAA    PB3
        STAB    PB1
        TBA
        JSR     TBLKUP
        LDAA    TEMP
        CMPA    #$2A
        BNE     OKOP
        JMP     NOTBB
OKOP    LDAA    PB1
        CMPA    #$8D
        BNE     NEXT
        INC     BFLAG
        BRA     PUT1
NEXT    ANDA    #$F0
        CMPA    #$60
        BEQ     ISX
        CMPA    #$A0
        BEQ     ISX
        CMPA    #$E0
        BEQ     ISX
        CMPA    #$80
        BEQ     IMM
        CMPA    #$C0
        BNE     PUT1
IMM     INC     MFLAG
        LDX     #SPLBD0
        BRA     PUT
ISX     INC     XFLAG
        LDAA    PB2
        JSR     PNTBYT
        LDX     #COMMX
PUT     JSR     OUTSTR
PUT1    LDX     PC1
        LDAA    PB1
        CMPA    #$8C
        BEQ     BYT3
        CMPA    #$8E
        BEQ     BYT3
        CMPA    #$CE  
        BEQ     BYT3
        ANDA    #$F0
        CMPA    #$20
        BNE     NOTB
        INC     BFLAG
        BRA     BYT2
NOTB    CMPA    #$60
        BCS     BYT1
        ANDA    #$30
        CMPA    #$30
        BNE     BYT2
BYT3    INC     BITE3
        TST     MFLAG
        BNE     BYT31
        LDAA    #$24        ; Output "$" character
        JSR     OUTEEE
BYT31   LDAA    0,X
        INX
        STX     PC1
        JSR     PNTBYT
        LDX     PC1
        BRA     BYT21
BYT2    INC     BITE2
BYT21   LDAA    0,X
        INX
        STX     PC1
        TST     XFLAG
        BNE     BYT1
        TST     BITE3
        BNE     BYT22
        TST     MFLAG
        BNE     BYT22
        TAB
        LDAA    #$24        ; Output "$" character
        JSR     OUTEEE
        TBA
BYT22   JSR     PNTBYT
BYT1    TST     BFLAG
        BEQ     NOTBB
        LDAB    #3
        JSR     SKIP        ; Output 3 spaces
        CLRA
        LDAB    PB2
        BGE     DPOS
        LDAA    #$FF
DPOS    ADDB    PC2
        ADCA    PC1
        STAA    BPOINT
        STAB    BPOINT+1
        LDX     #BPOINT
        JSR     OUT4HS
;
; PRINT ASCII VALUE OF INST
;
NOTBB   LDAB #$D
        LDAA #1
        TST BITE2
        BEQ PAVOI3
        LDAB #1
        TST BFLAG
        BNE PAVOI2
        LDAB #8
        TST MFLAG
        BNE PAVOI2
        TST MFLAG
        BNE PAVOI2
        LDAB #9
PAVOI2  LDAA #2
        BRA PAVOI8
;
PAVOI3  TST BITE3
        BEQ PAVOI8
        LDAA #3
        LDAB #6
        TST MFLAG
        BEQ PAVOI8
        LDAB #5
PAVOI8  PSHA
        JSR SKIP            ; Output 5 spaces
        PULB
        LDX #PB1
PAVOI4  LDAA 0,X
        CMPA #$20           ; Printable character
        BLE PAVOI5
        CMPA #$60
        BLE PAVOI9
PAVOI5  LDAA #$2E           ; "."
PAVOI9  INX
        JSR OUTEEE
        DECB
        BNE PAVOI4
NOT1    JSR INEEE
        TAB
        JSR OUTS
        CMPB #$20
        BEQ DOT
;
;  CHECK INPUT COMMAND
;  A, B, C, X, OR S
;
CKCBA   LDX SP
        INX
        CMPB #$43
        BEQ RDC
        INX
        CMPB #$42
        BEQ RDC
        INX
        CMPB #$41
        BEQ RDC
        INX
        CMPB #$58
        BEQ RDX
        LDX #SP
        CMPB #$53
        BNE RETNOT
RDX     JSR INBYTE
        STAA 0,X
        INX
RDC     JSR INBYTE
        STAA 0,X
        JSR OCRLF
        JSR PRINT
;
;  WILL RETURN HERE IN TRACE
;
        BRA NOT1
RETNOT  JMP CONTRL
DOT     TST TFLAG
        BNE DOT1
        JMP DISIN
;
DOT1    LDAB #$3F
        LDAA PB1
        CMPA #$8D
        BNE TSTB
        LDX BPOINT
        STX PC1
        CLR BFLAG
TSTB    TST BFLAG
        BEQ TSTJ
        LDX BPOINT
        LDAA 0,X
        STAA BPOINT+2
        STAB 0,X
        BRA EXEC
;
TSTJ    CMPA #$6E
        BEQ ISXD
        CMPA #$AD
        BEQ ISXD
        CMPA #$7E
        BEQ ISJ
        CMPA #$BD
        BNE NOTJ
ISJ     LDX PB2
        STX PC1
        BRA EXEC
ISXD    LDX SP
        LDAA 5,X
        ADDA PB2
        STAA PC2
        LDAA 4,X
        ADCA #0
        STAA PC1
        BRA EXEC
;
NOTJ    LDX SP
        CMPA #$39
        BNE NOTRTS
NOTJ1   LDX 8,X
        BRA EXR
;
NOTRTS  CMPA #$3B
        BNE NOTRTI
        LDX 13,X
EXR     STX PC1
NOTRTI  CMPA #$3F
        BEQ NONO
        CMPA #$3E
        BEQ NONO
;
EXEC    LDX PC1
        LDAA 0,X
        STAA OPSAVE
        STAB 0,X
        CMPB 0,X
        BNE CKROM
        JMP CONTG
;
NONO    JMP     OQSTNE      ; Print question mark "?" and exit to CONTRL
;
CKROM   LDAA PC1
        CMPA #$E0
        BCS NONO
;
;  GET JSR OR JMP
;
        LDX SP
        LDAA PB1
        CMPA #$7E
        BEQ NOTJ1
        CMPA #$BD
        BNE NONO
        LDX 6,X
        INX
        INX
        INX
        BRA ISJ+3
;
; Disassembler
;
;  INSTRUCTION NMEMONIC LOOKUP
;  ROUTINE FOR 68XX OP CODES
;
TBLKUP  CMPA #$40
        BCC IMLR6
IMLR1   JSR PNT3C
        LDAA PB1
        CMPA #$32
        BEQ IMLR3
        CMPA #$36  ;had � instead of #
        BEQ IMLR3
        CMPA #$33
        BEQ IMLR4
        CMPA #$37
        BEQ IMLR4
IMLR2   LDX #BLANK
        BRA IMLR5
;
IMLR3   LDX #PNTA
        BRA IMLR5       ;end of "bug removed"
;
IMLR4   LDX #PNTB
IMLR5   JMP OUTSTR
IMLR6   CMPA #$4E
        BEQ IMLR7
        CMPA #$5E
        BNE IMLR8
;
IMLR7   CLRA
        BRA IMLR1
;
IMLR8   CMPA #$80
        BCC IMLR9
        ANDA #$4F
        JSR PNT3C
        LDAA TEMP
        CMPA #$2A
        BEQ IMLR2
        LDAA PB1
        CMPA #$60
        BCC IMLR2
        ANDA #$10
        BEQ IMLR3
        BRA IMLR4
;
IMLR9   ANDA #$3F
        CMPA #$F
        BEQ IMLR7
        CMPA #$7
        BEQ IMLR7
        ANDA #$F
        CMPA #$3
        BEQ IMLR7
        CMPA #$C
        BGE IMLR10
        ADDA #$50
        JSR PNT3C
        LDAA PB1
        ANDA #$40
        BEQ IMLR3
        BRA IMLR4
;
IMLR10  LDAA PB1
        CMPA #$8D
        BNE IMLR11
        LDAA #$53
        BRA IMLR1
;
IMLR11  CMPA #$C0
        BCC IMLR12
        CMPA #$9D
        BEQ IMLR7
        ANDA #$F
        ADDA #$50
        BRA IMLR13
;
IMLR12  ANDA #$F
        ADDA #$52
        CMPA #$60
        BLT IMLR7
;
IMLR13  JMP IMLR1
;
PNT3C   CLRB
        STAA TEMP
        ASLA
        ADDA TEMP
        ADCB #$0
        LDX #TBL
        STX XTEMP
        ADDA XTEMP+1
        ADCB XTEMP
        STAB XTEMP
        STAA XTEMP+1
        LDX XTEMP
        LDAA 0,X
        STAA TEMP
        BSR OUTA
        LDAA 1,X
        BSR OUTA
        LDAA 2,X
;
OUTA    JMP     OUTEEE
;
;  "V" COMMAND
;
; >V 
; FROM ADDR DF71
; DF71 20 0B 10 1D  6E BC 7B D4  AA 0B 88 2A  FA 44 0E FA     ..........*.D..
;
VIEW    JSR     BAD2
VCOM1   LDAA    #8
        STAA    MCONT
VCOM5   JSR     OCRLF
        JSR     OUTAHI
        LDAB    #$10
VCOM9   JSR     OUT2HS
        DECB
        BITB    #3
        BNE     VCOM10
        JSR     OUTS
        CMPB    #$0
VCOM10  BNE     VCOM9
        LDAB    #$4         ; Output 4 spaces
        JSR     SKIP
        LDX     ADDRHI
        LDAB    #$10
VCOM2   LDAA    0,X
        CMPA    #$20        ; Printable character
        BCS     VCOM3       ; No, less than $20 (space)
        CMPA    #$7F        ; Printable character?
        BCS     VCOM4       ; Yes, less than $7F
VCOM3   LDAA    #$2E        ; Output period "."
VCOM4   BSR     OUTA        ; LBSR OUTEEE
        INX
        DECB
        BNE     VCOM2
        STX     ADDRHI
        DEC     MCONT
        BNE     VCOM5
        JSR     INEEE
        CMPA    #SPC        ; If Space then next block
        BEQ     VCOM1
        CMPA    #$56        ; If "V" then start again
        BEQ     VIEW
        JMP     CONTRL
;
; Assembly Mnemonic Table
;
TBL     FCC "***NOPNOP***"
        FCC "******TAPTPA"
        FCC "INXDEXCLVSEV"
        FCC "CLCSECCLISEI"
        FCC "SBACBA******"
        FCC "******TABTBA"
        FCC "***DAA***ABA"
        FCC "************"
        FCC "BRA***BHIBLS"
        FCC "BCCBCSBNEBEQ"
        FCC "BVCBVSBPLBMI"
        FCC "BGEBLTBGTBLE"
        FCC "TSXINSPULPUL"
        FCC "DESTXSPSHPSH"
        FCC "***RTS***RTI"
        FCC "******WAISWI"
        FCC "NEG******COM"
        FCC "LSR***RORASR"
        FCC "ASLROLDEC***"
        FCC "INCTSTJMPCLR"
        FCC "SUBCMPSBCBSR"
        FCC "ANDBITLDASTA"
        FCC "EORADCORAADD"
        FCC "CPXJSRLDSSTS"
        FCC "LDXSTX"
SPLBD0  FCC "#$"
        FCB EOT
COMMX   FCC ",X"                ;
        FCB EOT
BLANK   FCC "   "               ; 3 spaces
        FCB EOT
PNTA    FCC "A "                ;
        FCB EOT
PNTB    FCC "B "                ;
        FCB EOT
;
CSPRMPT FCC "\rDigiBug v1.01 (H = Help)\r\n"
        FCB EOT
PROMPT  FCC "\r\n> "            ;
    	FCB EOT
;
BREG    FCC " B="
        FCB EOT
AREG    FCC "A="
        FCB EOT
XREG    FCC "X="
        FCB EOT
SREG    FCC "S="
        FCB EOT
PCTR    FCC "PC="
        FCB EOT
CSET    FCC "HINZVC"            ; Condition Code Register bit characters
;
ADASC   FCC "\r\nBreak Addr: "  ;
        FCB EOT
FROMAD  FCB "\r\nFrom Addr: "   ;
        FCB EOT
THRUAD  FCC "\r\nThru Addr: "   ;
        FCB EOT
TOADD   FCB "To Addr: "         ;
        FCB EOT
VALASC  FCB "\r\nValue: "       ;
        FCB EOT
;
; Command Jump Table
;
FUTABL  FCC     "M"
        FDB     MOVE
        FCC     "E"
        FDB     CHANGE
        FCC     "G"
        FDB     CONTG
        FCC     "R"
        FDB     PRINT
        FCC     "T"
        FDB     TRACE
        FCC     "@"
        FDB     ASCII
        FCC     "H"
        FDB     HELP
        FCC     "V"
        FDB     VIEW
        FCC     "I"
        FDB     IFILL
        FCC     "J"
        FDB     JUMP
        FCC     "F"
        FDB     FIND
        FCC     "D"
        FDB     DISSA
        FCC     "K"
        FDB     KONTIN
        FCC     "1"
        FDB     BKPNT
        FCC     "2"
        FDB     BKPNT2
        FCC     "L"
        FDB     SLOAD
        FCC     "*"
        FDB     START
        FCC     "O"
        FDB     ECHON
        FCC     "N"
        FDB     ECHOFF
TBLEND  EQU     *
;
; "L" Command - Load S1/S9
; May 2026 - Significantly re-written from original code.
; Many bugs squashed including ignoring the checksum and S9 line content.
;
; e.g.
; S1 13 2000 BD FC BC 86 01 20 07 D6 F1 CB 10 D7 F1 48 BD FE 3C
; S9 03 0000 FC
;
; ADDRHI = $20 (Hi)
; ADDRLO = $00 (Lo)
;
SLOAD   JSR     OCRLF
GOAGAIN JSR     INEEE           ; Get first character from ACIA  
        CMPA    #"S"            ; Is it "S"
        BNE     GOAGAIN         ; If not go read again
        JSR     INEEE           ; Get second character in frame
        STAA    RECTYP          ; Save the Record Type
        CMPA    #"0"            ; Is it a "0" (Header)
        BEQ     SLOAD1          ; If "0" go ahead!
        CMPA    #"1"            ; Is it a "1" (Data)
        BEQ     SLOAD1          ; If "1" go ahead!
        CMPA    #"9"            ; Is it a "9" (Termination)
        BNE     GOAGAIN         ; If not 0, 1, or 9 then go start again
; Okay we've got S0, S1 or S9
SLOAD1  CLR     CHKSUM          ; Clear Checksum
        BSR     GETHEX          ; Get following byte count from input stream
        SUBA    #$02            ; Subtract the Address Bytes from the count
        STAA    BYTECNT         ; Save data length (less the 2 Address Bytes)
        BSR     GETADD          ; Read next two bytes for dest address (into X)
GETCNT  BSR     GETHEX          ; Get the next byte (into A)
        DEC     BYTECNT         ; decrement counter
        BEQ     CHKCHK          ; If byte count now zero go and check chksum
        LDAB    #"1"            ; Check this is a Data line (Record Type "1")
        CMPB    RECTYP          ; 
        BNE     SKPSTR          ; If not Data line skip the byte store
        STAA    0,X             ; Store read byte into memory
        CMPA    0,X             ; Test if RAM OK
        BNE     QUESTN          ; If write failed send "?" and abort!
SKPSTR  INX                     ; Increment address pointer
        BRA     GETCNT          ; go get another byte
;
CHKCHK  COM     CHKSUM          ; Complement calculated checksum
        CMPA    CHKSUM          ; Is Checksum correct?
        BNE     QUESTN          ; Checksum error, send "?" and abort!
        LDAB    #"9"            ; Was this the termination line? (Record Type "9")
        CMPB    RECTYP          ; 
        BEQ     LDEXIT          ; Yes, then exit!
        BRA     GOAGAIN         ; Otherwise, go for another line
QUESTN  LDAA    #"?"            ; No, so output question mark
        JSR     OUTEEE          ; Send to console
LDEXIT  JMP     CONTRL          ; Jump to Monitor Warm Start
; 
; Input Address
;
GETADD  JSR     GETHEX          ; Read in byte
        STAA    ADDRHI          ; Store MSB of Address
        BSR     GETHEX          ; Get another byte of data
        STAA    ADDRLO          ; store LSB of Address
        LDX     ADDRHI          ; Load X register with full Address
        RTS                     ; Return from subroutine
;
;       ADD IN THE ADDRESS OFFSET
;
GETHEX  BSR     CONVHEX         ; Go get byte of data and convert to binary 
        ASLA                    ; Shift the the 4 bits into msb
        ASLA                    ; Shift the the 4 bits into msb 
        ASLA                    ; Shift the the 4 bits into msb 
        ASLA                    ; Shift the the 4 bits into msb 
        TAB                     ; Transfer "A" to "B"
        BSR     CONVHEX         ; Go get byte of data and convert to binary
        ABA                     ; Add 4 bits in "A" + "B" -> "A"
        LDAB    #1              ; Check this isn't the last byte
        CMPB    BYTECNT         ; Don't add last byte (checksum) to the checksum!
        BEQ     GETHEXR         ; If last byte then skip the addition
        TAB                     ; Transfer byte "A" to "B"
        ADDB    CHKSUM          ; Add byte into checksum
        STAB    CHKSUM          ; Store new checksum
GETHEXR RTS                     ; Return from subroutine
;       
CONVHEX JSR     INEEE           ; Get HEX character from ACIA
        SUBA    #$30            ; Convert to binary
        BMI     QUESTN          ; Convert to binary
        CMPA    #$09            ; Convert to binary
        BLE     RETURN2         ; Convert to binary
        CMPA    #$11            ; Convert to binary
        BMI     QUESTN          ; Convert to binary
        CMPA    #$16            ; Convert to binary
        BGT     QUESTN          ; Convert to binary
        SUBA    #$07            ; Convert to binary
RETURN2 RTS                     ; Return from sub routine
;
; Output Help Screen
;
HELP    LDX     #HLPSCR
        JSR     OUTSTR
        JMP     CONTRL
;
; Help Screen - List of Commands
;
HLPSCR
        FCC "\r\n"
        FCC     "Commands: "
        FCC "\r\n"
        FCC     "========= "
        FCC "\r\n"
        FCC	" A = Set A register          M = Move memory "
        FCC "\r\n"
        FCC	" B = Set B register          N = Echo Off "
        FCC "\r\n"
        FCC	" C = Set CC register         O = Echo On "
        FCC "\r\n"
        FCC	" D = Disassemble code        R = view Registers "
        FCC "\r\n"
        FCC	" E = Examine / Edit memory   S = Set Stack pointer "
        FCC "\r\n"
        FCC	" F = Find Byte               T = Trace program "
        FCC "\r\n"
        FCC	" G = Go / Execute program    V = View memory "
        FCC "\r\n"
        FCC	" H = Help - Command list     X = Set X Register "
        FCC "\r\n"
        FCC	" I = Insert / Fill memory    @ = Insert ASCII "
        FCC "\r\n"
        FCC	" J = Jump to address         1 = Breakpoint 1 "
        FCC "\r\n"
        FCC	" K = Continue after break    2 = Breakpoint 2 "
        FCC "\r\n"
        FCC	" L = Load S-records          * = Restart (reset) "
CRLFAS  FCC "\r\n"
        FCB EOT
;
; Pad remainder of ROM space with $FF
;
        dc.b [(*+($FFF8-*))&$FFF8-*]$FF
; 
; Reset Vector Table $FFF8 - $FFFF
;
        ORG $FFF8
;
        FDB IO
        FDB SWI
        FDB POWDWN
        FDB START
;
        END
;
