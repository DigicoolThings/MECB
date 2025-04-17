*************************************
* COPYRIGHT (C) MOTOROLA, INC. 1979 *
*************************************

*************************************
* THIS IS THE BASE ASSIST09 ROM.
* IT MAY RUN WITH OR WITHOUT THE
* EXTENSION ROM WHICH
* WHEN PRESENT WILL BE AUTOMATICALLY
* INCORPORATED BY THE BLDVTR
* SUBROUTINE.
*************************************

*********************************************
* GLOBAL MODULE EQUATES
********************************************
ROMBEG  EQU     $F800           ; ROM START ASSEMBLY ADDRESS
RAMOFS  EQU     -$3900          ; ROM OFFSET TO RAM WORK PAGE
ROMSIZ  EQU     2048            ; ROM SIZE
ROM2OF  EQU     ROMBEG-ROMSIZ   ; START OF EXTENSION ROM
ACIA    EQU     $C008           ; DEFAULT ACIA ADDRESS
PTM     EQU     $C000           ; DEFAULT PTM ADDRESS
DFTCHP  EQU     0               ; DEFAULT CHARACTER PAD COUNT
DFTNLP  EQU     5               ; DEFAULT NEW LINE PAD COUNT
PROMPT  EQU     '>              ; PROMPT CHARACTER
NUMBKP  EQU     8               ; NUMBER OF BREAKPOINTS
*********************************************

*********************************************
* MISCELANEOUS EQUATES
*********************************************
EOT     EQU     $04             ; END OF TRANSMISSION
BELL    EQU     $07             ; BELL CHARACTER
LF      EQU     $0A             ; LINE FEED
CR      EQU     $0D             ; CARRIAGE RETURN
DLE     EQU     $10             ; DATA LINK ESCAPE
CAN     EQU     $18             ; CANCEL (CTL-X)

* PTM ACCESS DEFINITIONS
PTMSTA  EQU     PTM+1           ; READ STATUS REGISTER
PTMC13  EQU     PTM             ; CONTROL REGISTERS 1 AND 3
PTMC2   EQU     PTM+1           ; CONTROL REGISTER 2
PTMTM1  EQU     PTM+2           ; LATCH 1
PTMTM2  EQU     PTM+4           ; LATCH 2
PTMTM3  EQU     PTM+6           ; LATCH 3
SKIP2   EQU     $8C             ; "CMPX #" OPCODE - SKIPS TWO BYTES

*******************************************
* ASSIST09 MONITOR SWI FUNCTIONS
* THE FOLLOWING EQUATES DEFINE FUNCTIONS PROVIDED
* BY THE ASSIST09 MONITOR VIA THE SWI INSTRUCTION.
******************************************
INCHNP  EQU     0               ; INPUT CHAR IN A REG - NO PARITY
OUTCH   EQU     1               ; OUTPUT CHAR FROM A REG
PDATA1  EQU     2               ; OUTPUT STRING
PDATA   EQU     3               ; OUTPUT CR/LF THEN STRING
OUT2HS  EQU     4               ; OUTPUT TWO HEX AND SPACE
OUT4HS  EQU     5               ; OUTPUT FOUR HEX AND SPACE
PCRLF   EQU     6               ; OUTPUT CR/LF
SPACE   EQU     7               ; OUTPUT A SPACE
MONITR  EQU     8               ; ENTER ASSIST09 MONITOR
VCTRSW  EQU     9               ; VECTOR EXAMINE/SWITCH
BRKPT   EQU     10              ; USER PROGRAM BREAKPOINT
PAUSE   EQU     11              ; TASK PAUSE FUNCTION
NUMFUN  EQU     11              ; NUMBER OF AVAILABLE FUNCTIONS

* NEXT SUB-CODES FOR ACCESSING THE VECTOR TABLE.
* THEY ARE EQUIVALENT TO OFFSETS IN THE TABLE.
* RELATIVE POSITIONING MUST BE MAINTAINED

_AVTBL  EQU     0               ; ADDRESS OF VECTOR TABLE
_CMDL1  EQU     2               ; FIRST COMMAND LIST
_RSVD   EQU     4               ; RESERVED HARDWARE VECTOR
_SWI3   EQU     6               ; SWI3 ROUTINE
_SWI2   EQU     8               ; SWI2 ROUTINE
_FIRQ   EQU     10              ; FIRQ ROUTINE
_IRQ    EQU     12              ; IRQ ROUTINE
_SWI    EQU     14              ; SWI ROUTINE
_NMI    EQU     16              ; NMI ROUTINE
_RESET  EQU     18              ; RESET ROUTINE
_CION   EQU     20              ; CONSOLE ON
_CIDTA  EQU     22              ; CONSOLE INPUT DATA
_CIOFF  EQU     24              ; CONSOLE INPUT OFF
_COON   EQU     26              ; CONSOLE OUTPUT ON
_CODTA  EQU     28              ; CONSOLE OUTPUT DATA
_COOFF  EQU     30              ; CONSOLE OUTPUT OFF
_HSDTA  EQU     32              ; HIGH SPEED PRINTDATA
_BSON   EQU     34              ; PUNCH/LOAD ON
_BSDTA  EQU     36              ; PUNCH/LOAD DATA
_BSOFF  EQU     38              ; PUNCH/LOAD OFF
_PAUSE  EQU     40              ; TASK PAUSE ROUTINE
_EXPAN  EQU     42              ; EXPRESSION ANALYZER
_CMDL2  EQU     44              ; SECOND COMMAND LIST
_ACIA   EQU     46              ; ACIA ADDRESS
_PAD    EQU     48              ; CHARACTER PAD AND NEW LINE PAD
_ECHO   EQU     50              ; ECHO/LOAD AND NULL BKPT FLAG
_PTM    EQU     52              ; PTM ADDRESS
NUMVTR  EQU     52/2+1          ; NUMBER OF VECTORS
HIVTR   EQU     52              ; HIGHEST VECTOR OFFSET

******************************************
*           WORK AREA
* THIS WORK AREA IS ASSIGNED TO THE PAGE ADDRESSED BY
* -$1800,PCR FROM THE BASE ADDRESS OF THE ASSIST09
* ROM. THE DIRECT PAGE REGISTER DURING MOST ROUTINE
* OPERATIONS WILL POINT TO THIS WORK AREA. THE STACK
* INITIALLY STARTS UNDER THE RESERVED WORK AREAS AS
* DEFINED HEREIN.
******************************************
WORKPG  EQU     ROMBEG+RAMOFS   ; SETUP DIRECT PAGE ADDRESS
        SETDP   WORKPG!>8       ; NOTIFY ASSEMBLER
        ORG     WORKPG+256      ; READY PAGE DEFINITIONS

* THE FOLLOWING THRU BKPTOP MUST RESIDE IN THIS ORDER
* FOR PROPER INITIALIZATION
        ORG     *-4
PAUSER  EQU     *               ; PAUSE ROUTINE
        ORG     *-1
SWIBFL  EQU     *               ; BYPASS SWI AS BREAKPOINT FLAG
        ORG     *-1
BKPTCT  EQU     *               ; BREAKPOINT COUNT
        ORG     *-2             ; SLEVEL EQU
SLEVEL  EQU     *               ; STACK TRACE LEVEL
        ORG     -NUMVTR*2+*
VECTAB  EQU     *               ; VECTOR TABLE
        ORG     -2*NUMBKP+*
BKPTBL  EQU     *               ; BREAKPOINT TABLE
        ORG     -2*NUMBKP+*
BKPTOP  EQU     *               ; BREAKPOINT OPCODE TABLE
        ORG     *-2
WINDOW  EQU     *               ; WINDOW
        ORG     *-2
ADDR    EQU     *               ; ADDRESS POINTER VALUE
        ORG     *-1
BASEPG  EQU     *               ; BASE PAGE VALUE
        ORG     *-2
NUMBER  EQU     *               ; BINARY BUILD AREA
        ORG     *-2
LASTOP  EQU     *               ; LAST OPCODE TRACED
        ORG     *-2
RSTACK  EQU     *               ; RESET STACK POINTER
        ORG     *-2
PSTACK  EQU     *               ; COMMAND RECOVERY STACK
        ORG     *-2
PCNTER  EQU     *               ; LAST PROGRAM COUNTER
        ORG     *-2
TRACEC  EQU     *               ; TRACE COUNT
        ORG     *-1
SWICNT  EQU     *               ; TRACE "SWI" NEST LEVEL COUNT
        ORG     *-1             ; (MISFLG MUST FOLLOW SWICNT)
MISFLG  EQU     *               ; LOAD CMD/THRU BREAKPOINT FLAG
        ORG     *-1
DELIM   EQU     *               ; EXPRESSION DELIMITER/WORK BYTE
        ORG     *-40
ROM2WK  EQU     *               ; EXTENSION ROM RESERVED AREA
        ORG     *-21
TSTACK  EQU     *               ; TEMPORARY STACK HOLD
STACK   EQU     *               ; START OF INITIAL STACK

******************************************
* DEFAULT THE ROM BEGINNING ADDRESS TO 'ROMBEG'
* ASSIST09 IS POSITION ADDRESS INDEPENDENT, HOWEVER
* WE ASSEMBLE ASSUMING CONTROL OF THE HARDWARE VECTORS.
* NOTE THAT THE WORK RAM PAGE MUST BE 'RAMOFS'
* FROM THE ROM BEGINNING ADDRESS.
********************************************
        ORG     ROMBEG          ; ROM ASSEMBLY/DEFAULT ADDRESS

*****************************************************
* BLDVTR - BUILD ASSIST09 VECTOR TABLE
* HARDWARE RESET CALLS THIS SUBROUTINE TO BUILD THE
* ASSIST09 VECTOR TABLE. THIS SUBROUTINE RESIDES AT
* THE FIRST BYTE OF THE ASSIST09 ROM, AND CAN BE
* CALLED VIA EXTERNAL CONTROL CODE FOR REMOTE
* ASSIST09 EXECUTION.
* INPUT: S->VALID STACK RAM
* OUTPUT: U->VECTOR TABLE ADDRESS
* DPR->ASSIST09 WORK AREA PAGE
* THE VECTOR TABLE AND DEFAULTS ARE INITIALIZED
* ALL REGISTERS VOLATILE
*************************************************
BLDVTR  LEAX    VECTAB,PCR      ; ADDRESS VECTOR TABLE
        TFR     X,D             ; OBTAIN BASE PAGE ADDRESS
        TFR     A,DP            ; SETUP DPR
        STA     <BASEPG         ; STORE FOR QUICK REFERENCE
        LEAU    ,X              ; RETURN TABLE TO CALLER
        LEAY    <INITVT,PCR     ; LOAD FROM ADDR
        STU     ,X++            ; INIT VECTOR TABLE ADDRESS
        LDB     #NUMVTR-5       ; NUMBER RELOCATABLE VECTORS
        PSHS    B               ; STORE INDEX ON STACK
BLD2    TFR     Y,D             ; PREPARE ADDRESS RESOLVE
        ADDD    ,Y++            ; TO ABSOLUTE ADDRESS
        STD     ,X++            ; INTO VECTOR TABLE
        DEC     ,S              ; COUNT DOWN
        BNE     BLD2            ; BRANCH IF MORE TO INSERT
        LDB     #INTVE-INTVS    ; STATIC VALUE INIT LENGTH
BLD3    LDA     ,Y+             ; LOAD NEXT BYTE
        STA     ,X+             ; STORE INTO POSITION
        DECB                    ; COUNT DOWN
        BNE     BLD3            ; LOOP UNTIL DONE
        LEAY    ROM2OF,PCR      ; TEST POSSIBLE EXTENSION ROM
        LDX     #$20FE          ; LOAD "BRA *" FLAG PATTERN
        CMPX    ,Y++            ; ? EXTENDED ROM HERE
        BNE     BLDRTN          ; BRANCH NOT OUR ROM TO RETURN
        JSR     ,Y              ; CALL EXTENDED ROM INITIALIZE
BLDRTN  PULS    PC,B            ; RETURN TO INITIALIZER

*****************************************************
*                RESET ENTRY POINT
* HARDWARE RESET ENTERS HERE IF ASSIST09 IS ENABLED
* TO RECEIVE THE MC6809 HARDWARE VECTORS. WE CALL
* THE BLDVTR SUBROUTINE TO INITIALIZE THE VECTOR
* TABLE, STACK, AND THEN FIREUP THE MONITOR VIA SWI
* CALL.
*******************************************************
RESET   LEAS    STACK,PCR       ; SETUP INITIAL STACK
        BSR     BLDVTR          ; BUILD VECTOR TABLE
RESET2  CLRA                    ; ISSUE STARTUP MESSAGE
        TFR     A,DP            ; DEFAULT TO PAGE ZERO
        SWI                     ; PERFORM MONITOR FIREUP
        FCB     MONITR          ; TO ENTER COMMAND PROCESSING
        BRA     RESET2          ; REENTER MONITOR IF 'CONTINUE'

******************************************************
*        INITVT - INITIAL VECTOR TABLE
* THIS TABLE IS RELOCATED TO RAM AND REPRESENTS THE
* INITIAL STATE OF THE VECTOR TABLE. ALL ADDRESSES
* ARE CONVERTED TO ABSOLUTE FORM. THIS TABLE STARTS
* WITH THE SECOND ENTRY, ENDS WITH STATIC CONSTANT
* INITIALIZATION DATA WHICH CARRIES BEYOND THE TABLE.
************************************************
INITVT  FDB     CMDTBL-*        ; DEFAULT FIRST COMMAND TABLE
        FDB     RSRVDR-*        ; DEFAULT UNDEFINED HARDWARE VECTOR
        FDB     SWI3R-*         ; DEFAULT SWI3
        FDB     SWI2R-*         ; DEFAULT SWI2
        FDB     FIRQR-*         ; DEFAULT FIRQ
        FDB     IRQR-*          ; DEFAULT IRQ ROUTINE
        FDB     SWIR-*          ; DEFAULT SWI ROUTINE
        FDB     NMIR-*          ; DEFAULT NMI ROUTINE
        FDB     RESET-*         ; RESTART VECTOR
        FDB     CION-*          ; DEFAULT CION
        FDB     CIDTA-*         ; DEFAULT CIDTA
        FDB     CIOFF-*         ; DEFAULT CIOFF
        FDB     COON-*          ; DEFAULT COON
        FDB     CODTA-*         ; DEFAULT CODTA
        FDB     COOFF-*         ; DEFAULT COOFF
        FDB     HSDTA-*         ; DEFAULT HSDTA
        FDB     BSON-*          ; DEFAULT BSON
        FDB     BSDTA-*         ; DEFAULT BSDTA
        FDB     BSOFF-*         ; DEFAULT BSOFF
        FDB     PAUSER-*        ; DEFAULT PAUSE ROUTINE
        FDB     EXP1-*          ; DEFAULT EXPRESSION ANALYZER
        FDB     CMDTB2-*        ; DEFAULT SECOND COMMAND TABLE
* CONSTANTS
INTVS   FDB     ACIA            ; DEFAULT ACIA
        FCB     DFTCHP,DFTNLP   ; DEFAULT NULL PADDS
        FDB     0               ; DEFAULT ECHO
        FDB     PTM             ; DEFAULT PTM
        FDB     0               ; INITIAL STACK TRACE LEVEL
        FCB     0               ; INITIAL BREAKPOINT COUNT
        FCB     0               ; SWI BREAKPOINT LEVEL
        FCB     $39             ; DEFAULT PAUSE ROUTINE (RTS)
INTVE   EQU     *
*B
***********************************************
*            ASSIST09 SWI HANDLER
* THE SWI HANDLER PROVIDES ALL INTERFACING NECESSARY
* FOR A USER PROGRAM. A FUNCTION BYTE IS ASSUMED TO
* FOLLOW THE SWI INSTRUCTION. IT IS BOUND CHECKED
* AND THE PROPER ROUTINE IS GIVEN CONTROL. THIS
* INVOCATION MAY ALSO BE A BREAKPOINT INTERRUPT.
* IF SO, THE BREAKPOINT HANDLER IS ENTERED.
* INPUT: MACHINE STATE DEFINED FOR SWI
* OUTPUT: VARIES ACCORDING TO FUNCTION CALLED. PC ON
* CALLERS STACK INCREMENTED BY ONE IF VALID CALL.
* VOLATILE REGISTERS: SEE FUNCTIONS CALLED
* STATE: RUNS DISABLED UNLESS FUNCTION CLEARS I FLAG.
************************************************
* SWI FUNCTION VECTOR TABLE
SWIVTB  FDB     ZINCH-SWIVTB    ; INCHNP
        FDB     ZOTCH1-SWIVTB   ; OUTCH
        FDB     ZPDTA1-SWIVTB   ; PDATA1
        FDB     ZPDATA-SWIVTB   ; PDATA
        FDB     ZOT2HS-SWIVTB   ; OUT2HS
        FDB     ZOT4HS-SWIVTB   ; OUT4HS
        FDB     ZPCRLF-SWIVTB   ; PCRLF
        FDB     ZSPACE-SWIVTB   ; SPACE
        FDB     ZMONTR-SWIVTB   ; MONITR
        FDB     ZVSWTH-SWIVTB   ; VCTRSW
        FDB     ZBKPNT-SWIVTB   ; BREAKPOINT
        FDB     ZPAUSE-SWIVTB   ; TASK PAUSE

SWIR    DEC     SWICNT,PCR      ; UP "SWI" LEVEL FOR TRACE
        LBSR    LDDP            ; SETUP PAGE AND VERIFY STACK
* CHECK FOR BREAKPOINT TRAP
        LDU     10,S            ; LOAD PROGRAM COUNTER
        LEAU    -1,U            ; BACK TO SWI ADDRESS
        TST     <SWIBFL         ; ? THIS "SWI" BREAKPOINT
        BNE     SWIDNE          ; BRANCH IF SO TO LET THROUGH
        LBSR    CBKLDR          ; OBTAIN BREAKPOINT POINTERS
        NEGB                    ; OBTAIN POSITIVE COUNT
SWILP   DECB                    ; COUNT DOWN
        BMI     SWIDNE          ; BRANCH WHEN DONE
        CMPU    ,Y++            ; ? WAS THIS A BREAKPOINT
        BNE     SWILP           ; BRANCH IF NOT
        STU     10,S            ; SET PROGRAM COUNTER BACK
        LBRA    ZBKPNT          ; GO DO BREAKPOINT
SWIDNE  CLR     <SWIBFL         ; CLEAR IN CASE SET
        PULU    D               ; OBTAIN FUNCTION BYTE, UP PC
        CMPB    #NUMFUN         ; ? TOO HIGH
        LBHI    ERROR           ; YES, DO BREAKPOINT
        STU     10,S            ; BUMP PROGRAM COUNTER PAST SWI
        ASLB                    ; FUNCTION CODE TIMES TWO
        LEAU    SWIVTB,PCR      ; OBTAIN VECTOR BRANCH ADDRESS
        LDD     B,U             ; LOAD OFFSET
        JMP     D,U             ; JUMP TO ROUTINE

**********************************************
* REGISTERS TO FUNCTION ROUTINES:
*  DP-> WORK AREA PAGE
*  D,Y,U=UNRELIABLE           X=AS CALLED FROM USER
*  S=AS FROM SWI INTERRUPT
*********************************************

**************************************************
*            [SWI FUNCTION 8]
*              MONITOR ENTRY
*  FIREUP THE ASSIST09 MONITOR.
*  THE STACK WITH ITS VALUES FOR THE DIRECT PAGE
*  REGISTER AND CONDITION CODE FLAGS ARE USED AS IS.
*   1) INITIALIZE CONSOLE I/O
*   2) OPTIONALLY PRINT SIGNON
*   3) INITIALIZE PTM FOR SINGLE STEPPING
*   4) ENTER COMMAND PROCESSOR
* INPUT: A=0 INIT CONSOLE AND PRINT STARTUP MESSAGE
*        A#0 OMIT CONSOLE INIT AND STARTUP MESSAGE
*************************************************

SIGNON  FCC     /ASSIST09/      ; SIGNON EYE-CATCHER
        FCB     EOT
ZMONTR  STS     <RSTACK         ; SAVE FOR BAD STACK RECOVERY
        TST     1,S             ; ? INIT CONSOLE AND SEND MSG
        BNE     ZMONT2          ; BRANCH IF NOT
        JSR     [VECTAB+_CION,PCR] ; READY CONSOLE INPUT
        JSR     [VECTAB+_COON,PCR] ; READY CONSOLE OUTPUT
        LEAX    SIGNON,PCR         ; READY SIGNON EYE-CATCHER
        SWI                     ; PERFORM
        FCB     PDATA           ; PRINT STRING
ZMONT2  LDX     <VECTAB+_PTM    ; LOAD PTM ADDRESS
        BEQ     CMD             ; BRANCH IF NOT TO USE A PTM
        CLR     PTMTM1-PTM,X    ; SET LATCH TO CLEAR RESET
        CLR     PTMTM1+1-PTM,X  ; AND SET GATE HIGH
        LDD     #$01A6          ; SETUP TIMER 1 MODE
        STA     PTMC2-PTM,X     ; SETUP FOR CONTROL REGISTER1
        STB     PTMC13-PTM,X    ; SET OUTPUT ENABLED/
* SINGLE SHOT/ DUAL 8 BIT/INTERNAL MODE/OPERATE
        CLR     PTMC2-PTM,X     ; SET CR2 BACK TO RESET FORM
* FALL INTO COMMAND PROCESSOR

***************************************************
*          COMMAND HANDLER
*  BREAKPOINTS ARE REMOVED AT THIS TIME.
*  PROMPT FOR A COMMAND, AND STORE ALL CHARACTERS
*  UNTIL A SEPARATOR ON THE STACK.
*  SEARCH FOR FIRST MATCHING COMMAND SUBSET,
*  CALL IT OR GIVE '?' RESPONSE.
*  DURING COMMAND SEARCH:
*      B=OFFSET TO NEXT ENTRY ON X
*      U=SAVED S
*      U-1=ENTRY SIZE+2
*      U-2=VALID NUMBER FLAG (>=0 VALID)/COMPARE CNT
*      U-3=CARRIAGE RETURN FLAG (0=CR HAS BEEN DONE)
*      U-4=START OF COMMAND STORE
*      S+0=END OF COMMAND STORE
***********************************************

CMD     SWI                     ; TO NEW LINE
        FCB     PCRLF           ; FUNCTION
* DISARM THE BREAKPOINTS
CMDNEP  LBSR    CBKLDR          ; OBTAIN BREAKPOINT POINTERS
        BPL     CMDNOL          ; BRANCH IF NOT ARMED OR NONE
        NEGB                    ; MAKE POSITIVE
        STB     <BKPTCT         ; FLAG AS DISARMED
CMDDDL  DECB                    ; ? FINISHED
        BMI     CMDNOL          ; BRANCH IF SO
        LDA     -NUMBKP*2,Y     ; LOAD OPCODE STORED
        STA     [,Y++]          ; STORE BACK OVER "SWI"
        BRA     CMDDDL          ; LOOP UNTIL DONE
CMDNOL  LDX     10,S            ; LOAD USERS PROGRAM COUNTER
        STX     <PCNTER         ; SAVE FOR EXPRESSION ANALYZER
        LDA     #PROMPT         ; LOAD PROMPT CHARACTER
        SWI                     ; SEND TO OUTPUT HANDLER
        FCB     OUTCH           ; FUNCTION
        LEAU    ,S              ; REMEMBER STACK RESTORE ADDRESS
        STU     <PSTACK         ; REMEMBER STACK FOR ERROR USE
        CLRA                    ; PREPARE ZERO
        CLRB                    ; PREPARE ZERO
        STD     <NUMBER         ; CLEAR NUMBER BUILD AREA
        STD     <MISFLG         ; CLEAR MISCEL. AND SWICNT FLAGS
        STD     <TRACEC         ; CLEAR TRACE COUNT
        LDB     #2              ; SET D TO TWO
        PSHS    D,CC            ; PLACE DEFAULTS ONTO STACK
* CHECK FOR "QUICK" COMMANDS.
        LBSR    READ            ; OBTAIN FIRST CHARACTER
        LEAX    CDOT+2,PCR      ; PRESET FOR SINGLE TRACE
        CMPA    #'.             ; ? QUICK TRACE
        BEQ     CMDXQT          ; BRANCH EQUAL FOR TRACE ONE
        LEAX    CMPADP+2,PCR    ; READY MEMORY ENTRY POINT
        CMPA    #'/             ; ? OPEN LAST USED MEMORY
        BEQ     CMDXQT          ; BRANCH TO DO IT IF SO
* PROCESS NEXT CHARACTER
CMD2    CMPA    #'              ; ? BLANK OR DELIMITER
        BLS    CMDGOT           ; BRANCH YES, WE HAVE IT
        PSHS   A                ; BUILD ONTO STACK
        INC    -1,U             ; COUNT THIS CHARACTER
        CMPA   #'/              ; ? MEMORY COMMAND
        BEQ    CMDMEM           ; BRANCH IF SO
        LBSR   BLDHXC           ; TREAT AS HEX VALUE
        BEQ    CMD3             ; BRANCH IF STILL VALID NUMBER
        DEC    -2,U             ; FLAG AS INVALID NUMBER
CMD3    LBSR   READ             ; OBTAIN NEXT CHARACTER
        BRA    CMD2             ; TEST NEXT CHARACTER
* GOT COMMAND, NOW SEARCH TABLES
CMDGOT  SUBA   #CR              ; SET ZERO IF CARRIAGE RETURN
        STA    -3,U             ; SETUP FLAG
        LDX    <VECTAB+_CMDL1   ; START WITH FIRST CMD LIST
CMDSCH  LDB    ,X+              ; LOAD ENTRY LENGTH
        BPL    CMDSME           ; BRANCH IF NOT LIST END
        LDX    <VECTAB+_CMDL2   ; NOW TO SECOND CMD LITS
        INCB                    ; ? TO CONTINUE TO DEFAULT LIST
        BEQ     CMDSCH          ; BRANCH IF SO
CMDBAD  LDS     <PSTACK         ; RESTORE STACK
        LEAX    ERRMSG,PCR      ; POINT TO ERROR STRING
        SWI                     ; SEND OUT
        FCB     PDATA1          ; TO CONSOLE
        BRA     CMD             ; AND TRY AGAIN
* SEARCH NEXT ENTRY
CMDSME  DECB                    ; TAKE ACCOUNT OF LENGTH BYTE
        CMPB    -1,U            ; ? ENTERED LONGER THAN ENTRY
        BHS     CMDSIZ          ; BRANCH IF NOT TOO LONG
CMDFLS  ABX                     ; SKIP TO NEXT ENTRY
        BRA     CMDSCH          ; AND TRY NEXT
CMDSIZ  LEAY    -3,U            ; PREPARE TO COMPARE
        LDA     -1,U            ; LOAD SIZE+2
        SUBA    #2              ; TO ACTUAL SIZE ENTERED
        STA     -2,U            ; SAVE SIZE FOR COUNTDOWN
CMDCMP  DECB                    ; DOWN ONE BYTE
        LDA     ,X+             ; NEXT COMMAND CHARACTER
        CMPA    ,-Y             ; ? SAME AS THAT ENTERED
        BNE     CMDFLS          ; BRANCH TO FLUSH IF NOT
        DEC     -2,U            ; COUNT DOWN LENGTH OF ENTRY
        BNE     CMDCMP          ; BRANCH IF MORE TO TEST
        ABX                     ; TO NEXT ENTRY
        LDD     -2,X            ; LOAD OFFSET
        LEAX    D,X             ; COMPUTE ROUTINE ADDRESS+2
CMDXQT  TST     -3,U            ; SET CC FOR CARRIAGE RETURN TEST
        LEAS    ,U              ; DELETE STACK WORK AREA
        JSR     -2,X            ; CALL COMMAND
        LBRA    CMDNOL          ; GO GET NEXT COMMAND
CMDMEM  TST     -2,U            ; ? VALID HEX NUMBER ENTERED
        BMI     CMDBAD          ; BRANCH ERROR IF NOT
        LEAX    <CMEMN-CMPADP,X ; TO DIFFERENT ENTRY
        LDD     <NUMBER         ; LOAD NUMBER ENTERED
        BRA     CMDXQT          ; AND ENTER MEMORY COMMAND

** COMMANDS ARE ENTERED AS A SUBROUTINE WITH:
**    DPR->ASSIST09 DIRECT PAGE WORK AREA
**    Z=1 CARRIAGE RETURN ENTERED
**    Z=0 NON CARRIAGE RETURN DELIMITER
**    S=NORMAL RETURN ADDRESS
** THE LABEL "CMDBAD" MAY BE ENTERED TO ISSUE AN
** AN ERROR FLAG (*).
**************************************************
*       ASSIST09 COMMAND TABLES
* THESE ARE THE DEFAULT COMMAND TABLES. EXTERNAL
* TABLES OF THE SAME FORMAT MAY EXTEND/REPLACE
* THESE BY USING THE VECTOR SWAP FUNCTION.
*
* ENTRY FORMAT:
*    +0...TOTAL SIZE OF ENTRY (INCLUDING THIS BYTE)
*    +1...COMMAND STRING
*    +N...TWO BYTE OFFSET TO COMMAND (ENTRYADDR-*)
*
* THE TABLES TERMINATE WITH A ONE BYTE -1 OR -2.
* THE -1 CONTINUES THE COMMAND SEARCH WITH THE
*        SECOND COMMAND TABLE.
* THE -2 TERMINATES COMMAND SEARCHES.
*****************************************************

* THIS IS THE DEFAULT LIST FOR THE SECOND COMMAND
* LIST ENTRY.

CMDTB2  FCB     -2              ; STOP COMMAND SEARCHES

* THIS IS THE DEFAULT LIST FOR THE FIRST COMMAND
* LIST ENTRY.

CMDTBL  EQU     *               ; MONITOR COMMAND TABLE
        FCB     4
        FCC     /B/             ; 'BREAKPOINT' COMMAND
        FDB     CBKPT-*
        FCB     4
        FCC     /C/             ; 'CALL' COMMAND
        FDB     CCALL-*
        FCB     4
        FCC     /D/             ; 'DISPLAY' COMMAND
        FDB     CDISP-*
        FCB     4
        FCC     /E/             ; 'ENCODE' COMMAND
        FDB     CENCDE-*
        FCB     4
        FCC     /G/             ; 'GO' COMMAND
        FDB     CGO-*
        FCB     4
        FCC     /L/             ; 'LOAD' COMMAND
        FDB     CLOAD-*
        FCB     4
        FCC     /M/             ; 'MEMORY' COMMAND
        FDB     CMEM-*
        FCB     4
        FCC     /N/             ; 'NULLS' COMMAND
        FDB     CNULLS-*
        FCB     4
        FCC     /O/             ; 'OFFSET' COMMAND
        FDB     COFFS-*
        FCB     4
        FCC     /P/             ; 'PUNCH' COMMAND
        FDB     CPUNCH-*
        FCB     4
        FCC     /R/             ; 'REGISTERS' COMMAND
        FDB     CREG-*
        FCB     4
        FCC     /S/             ; 'STLEVEL' COMMAND
        FDB     CSTLEV-*
        FCB     4
        FCC     /T/             ; 'TRACE' COMMAND
        FDB     CTRACE-*
        FCB     4
        FCC     /V/             ; 'VERIFY' COMMAND
        FDB     CVER-*
        FCB     4
        FCC     /W/             ; 'WINDOW' COMMAND
        FDB     CWINDO-*
        FCB     -1              ; END, CONTINUE WITH THE SECOND

*************************************************
*             [SWI FUNCTIONS 4 AND 5]
*      4 - OUT2HS - DECODE BYTE TO HEX AND ADD SPACE
*      5 - OUT4HS - DECODE WORD TO HEX AND ADD SPACE
* INPUT: X->BYTE OR WORD TO DECODE
* OUTPUT: CHARACTERS SENT TO OUTPUT HANDLER
*         X->NEXT BYTE OR WORD
*************************************************
ZOUT2H  LDA     ,X+             ; LOAD NEXT BYTE
        PSHS    D               ; SAVE - DO NOT REREAD
        LDB     #16             ; SHIFT BY 4 BITS
        MUL                     ; WITH MULTIPLY
        BSR     ZOUTHX          ; SEND OUT AS HEX
        PULS    D               ; RESTORE BYTES
        ANDA    #$0F            ; ISOLATE RIGHT HEX
ZOUTHX  ADDA    #$90            ; PREPARE A-F ADJUST
        DAA                     ; ADJUST
        ADCA    #$40            ; PREPARE CHARACTER BITS
        DAA                     ; ADJUST
SEND    JMP     [VECTAB+_CODTA,PCR] ; SEND TO OUT HANDLER

ZOT4HS  BSR     ZOUT2H          ; CONVERT FIRST BYTE
ZOT2HS  BSR     ZOUT2H          ; CONVERT BYTE TO HEX
        STX     4,S             ; UPDATE USERS X REGISTER
* FALL INTO SPACE ROUTINE

*************************************************
*            [SWI FUNCTION 7]
*         SPACE - SEND BLANK TO OUTPUT HANDLER
* INPUT: NONE
* OUTPUT: BLANK SEND TO CONSOLE HANDLER
*************************************************
ZSPACE  LDA     #'              ; LOAD BLANK
        BRA     ZOTCH2          ; SEND AND RETURN

***********************************************
*             [SWI FUNCTION 9]
*          SWAP VECTOR TABLE ENTRY
* INPUT: A=VECTOR TABLE CODE (OFFSET)
* X=0 OR REPLACEMENT VALUE
* OUTPUT: X=PREVIOUS VALUE
***********************************************
ZVSWTH  LDA     1,S             ; LOAD REQUESTERS A
        CMPA    #HIVTR          ; ? SUB-CODE TOO HIGH
        BHI     ZOTCH3          ; IGNORE CALL IF SO
        LDY     <VECTAB+_AVTBL  ; LOAD VECTOR TABLE ADDRESS
        LDU     A,Y             ; U=OLD ENTRY
        STU     4,S             ; RETURN OLD VALUE TO CALLERS X
        STX     -2,S            ; ? X=0
        BEQ     ZOTCH3          ; YES, DO NOT CHANGE ENTRY
        STX     A,Y             ; REPLACE ENTRY
        BRA     ZOTCH3          ; RETURN FROM SWI
*D

************************************************
*               [SWI FUNCTION 0]
*  INCHNP - OBTAIN INPUT CHAR IN A (NO PARITY)
* NULLS AND RUBOUTS ARE IGNORED.
* AUTOMATIC LINE FEED IS SENT UPON RECEIVING A
* CARRIAGE RETURN.
* UNLESS WE ARE LOADING FROM TAPE.
************************************************
ZINCHP  BSR     XQPAUS          ; RELEASE PROCESSOR
ZINCH   BSR     XQCIDT          ; CALL INPUT DATA APPENDAGE
        BCC     ZINCHP          ; LOOP IF NONE AVAILABLE
        TSTA                    ; ? TEST FOR NULL
        BEQ     ZINCH           ; IGNORE NULL
        CMPA    #$7F            ; ? RUBOUT
        BEQ     ZINCH           ; BRANCH YES TO IGNORE
        STA     1,S             ; STORE INTO CALLERS A
        TST     <MISFLG         ; ? LOAD IN PROGRESS
        BNE     ZOTCH3          ; BRANCH IF SO TO NOT ECHO
        CMPA    #CR             ; ? CARRIAGE RETURN
        BNE     ZIN2            ; NO, TEST ECHO BYTE
        LDA     #LF             ; LOAD LINE FEED
        BSR     SEND            ; ALWAYS ECHO LINE FEED
ZIN2    TST     <VECTAB+_ECHO   ; ? ECHO DESIRED
        BNE     ZOTCH3          ; NO, RETURN
* FALL THROUGH TO OUTCH
************************************************
*            [SWI FUNCTION 1]
*        OUTCH - OUTPUT CHARACTER FROM A
* INPUT: NONE
* OUTPUT: IF LINEFEED IS THE OUTPUT CHARACTER THEN
* C=0 NO CTL-X RECEIVED, C=1 CTL-X RECEIVED
************************************************
ZOTCH1  LDA     1,S             ; LOAD CHARACTER TO SEND
        LEAX    <ZPCRLS,PCR     ; DEFAULT FOR LINE FEED
        CMPA    #LF             ; ? LINE FEED
        BEQ     ZPDTLP          ; BRANCH TO CHECK PAUSE IF SO
ZOTCH2  BSR     SEND            ; SEND TO OUTPUT ROUTINE
ZOTCH3  INC     <SWICNT         ; BUMP UP "SWI" TRACE NEST LEVEL
        RTI                     ; RETURN FROM "SWI" FUNCTION

**************************************************
* [SWI FUNCTION 6]
* PCRLF - SEND CR/LF TO CONSOLE HANDLER
* INPUT: NONE
* OUTPUT: CR AND LF SENT TO HANDLER
* C=0 NO CTL-X, C=1 CTL-X RECEIVED
**************************************************
ZPCRLS  FCB     EOT             ; NULL STRING
ZPCRLF LEAX     ZPCRLS,PCR      ; READY CR,LF STRING
* FALL INTO CR/LF CODE

**************************************************
* [SWI FUNCTION 3]
* PDATA - OUTPUT CR/LF AND STRING
* INPUT: X->STRING
* OUTPUT: CR/LF AND STRING SENT TO OUTPUT CONSOLE
* HANDLER.
* C=0 NO CTL-X, C=1 CTL-X RECEIVED
* NOTE: LINE FEED MUST FOLLOW CARRIAGE RETURN FOR
* PROPER PUNCH DATA.
**************************************************

ZPDATA  LDA     #CR             ; LOAD CARRIAGE RETURN
        BSR     SEND            ; SEND IT
        LDA     #LF             ; LOAD LINE FEED
* FALL INTO PDATA1

*************************************************
* [SWI FUNCTION 2]
* PDATA1 - OUTPUT STRING TILL EOT ($04)
* THIS ROUTINE PAUSES IF AN INPUT BYTE BECOMES
* AVAILABLE DURING OUTPUT TRANSMISSION UNTIL A
* SECOND IS RECEIVED.
* INPUT: X->STRING
* OUTPUT: STRING SENT TO OUTPUT CONSOLE DRIVER
* C=0 NO CTL-X, C=1 CTL-X RECEIVED
*************************************************

ZPDTLP  BSR     SEND            ; SEND CHARACTER TO DRIVER
ZPDTA1  LDA     ,X+             ; LOAD NEXT CHARACTER
        CMPA    #EOT            ; ? EOT
        BNE     ZPDTLP          ; LOOP IF NOT
* FALL INTO PAUSE CHECK FUNCTION

********************************************
* [SWI FUNCTION 12]
* PAUSE - RETURN TO TASK DISPATCHING AND CHECK
* FOR FREEZE CONDITION OR CTL-X BREAK
* THIS FUNCTION ENTERS THE TASK PAUSE HANDLER SO
* OPTIONALLY OTHER 6809 PROCESSES MAY GAIN CONTROL.
* UPON RETURN, CHECK FOR A 'FREEZE' CONDITION
* WITH A RESULTING WAIT LOOP, OR CONDITION CODE
* RETURN IF A CONTROL-X IS ENTERED FROM THE INPUT
* HANDLER.
* OUTPUT: C=1 IF CTL-X HAS ENTERED, C=0 OTHERWISE
******************************************

ZPAUSE  BSR     XQPAUS          ; RELEASE CONTROL AT EVERY LINE
        BSR     CHKABT          ; CHECK FOR FREEZE OR ABORT
        TFR     CC,B            ; PREPARE TO REPLACE CC
        STB     ,S              ; OVERLAY OLD ONE ON STACK
        BRA     ZOTCH3          ; RETURN FROM "SWI"

* CHKABT - SCAN FOR INPUT PAUSE/ABORT DURING OUTPUT
* OUTPUT: C=0 OK, C=1 ABORT (CTL-X ISSUED)
* VOLATILE: U,X,D
CHKABT  BSR     XQCIDT          ; ATTEMPT INPUT
        BCC     CHKRTN          ; BRANCH NO TO RETURN
        CMPA    #CAN            ; ? CTL-X FOR ABORT
        BNE     CHKWT           ; BRANCH NO TO PAUSE
CHKSEC  COMB                    ; SET CARRY
CHKRTN  RTS                     ; RETURN TO CALLER WITH CC SET
CHKWT   BSR     XQPAUS          ; PAUSE FOR A MOMENT
        BSR     XQCIDT          ; ? KEY FOR START
        BCC     CHKWT           ; LOOP UNTIL RECEIVED
        CMPA    #CAN            ; ? ABORT SIGNALED FROM WAIT
        BEQ     CHKSEC          ; BRANCH YES
        CLRA                    ; SET C=0 FOR NO ABORT
        RTS                     ; AND RETURN

* SAVE MEMORY WITH JUMPS
XQPAUS  JMP   [VECTAB+_PAUSE,PCR] ; TO PAUSE ROUTINE
XQCIDT  JSR   [VECTAB+_CIDTA,PCR] ; TO INPUT ROUTINE
        ANDA  #$7F              ; STRIP PARITY
        RTS                     ; RETURN TO CALLER

********************************************
* NMI DEFAULT INTERRUPT HANDLER
* THE NMI HANDLER IS USED FOR TRACING INSTRUCTIONS.
* TRACE PRINTOUTS OCCUR ONLY AS LONG AS THE STACK
* TRACE LEVEL IS NOT BREACHED BY FALLING BELOW IT.
* TRACING CONTINUES UNTIL THE COUNT TURNS ZERO OR
* A CTL-X IS ENTERED FROM THE INPUT CONSOLE DEVICE.
*********************************************

MSHOWP  FCB     'O,'P,'-,EOT    ; OPCODE PREP

NMIR    BSR     LDDP            ; LOAD PAGE AND VERIFY STACK
        TST     <MISFLG         ; ? THRU A BREAKPOINT
        BNE     NMICON          ; BRANCH IF SO TO CONTINUE
        TST     <SWICNT         ; ? INHIBIT "SWI" DURING TRACE
        BMI     NMITRC          ; BRANCH YES
        LEAX    12,S            ; OBTAIN USERS STACK POINTER
        CMPX    <SLEVEL         ; ? TO TRACE HERE
        BLO     NMITRC          ; BRANCH IF TOO LOW TO DISPLAY
        LEAX    MSHOWP,PCR      ; LOAD OP PREP
        SWI                     ; SEND TO CONSOLE
        FCB     PDATA1          ; FUNCTION
        ROL     <DELIM          ; SAVE CARRY BIT
        LEAX    LASTOP,PCR      ; POINT TO LAST OP
        SWI                     ; SEND OUT AS HEX
        FCB     OUT4HS          ; FUNCTION
        BSR     REGPRS          ; FOLLOW MEMORY WITH REGISTERS
        BCS     ZBKCMD          ; BRANCH IF "CANCEL"
        ROR     <DELIM          ; RESTORE CARRY BIT
        BCS     ZBKCMD          ; BRANCH IF "CANCEL"
        LDX     <TRACEC         ; LOAD TRACE COUNT
        BEQ     ZBKCMD          ; IF ZERO TO COMMAND HANDLER
        LEAX    -1,X            ; MINUS ONE
        STX     <TRACEC         ; REFRESH
        BEQ     ZBKCMD          ; STOP TRACE WHEN ZERO
        BSR     CHKABT          ; ? ABORT THE TRACE
        BCS     ZBKCMD          ; BRANCH YES TO COMMAND HANDLER
NMITRC  LBRA    CTRCE3          ; NO, TRACE ANOTHER INSTRUCTION

REGPRS  LBSR    REGPRT          ; PRINT REGISTERS AS FROM COMMAND
        RTS                     ; RETURN TO CALLER

* JUST EXECUTED THRU A BRKPNT. NOW CONTINUE NORMALLY

NMICON  CLR     <MISFLG        ; CLEAR THRU FLAG
        LBSR    ARMBK2         ; ARM BREAKPOINTS
RTI     RTI                    ; AND CONTINUE USERS PROGRAM

* LDDP - SETUP DIRECT PAGE REGISTER, VERIFY STACK.
* AN INVALID STACK CAUSES A RETURN TO THE COMMAND
* HANDLER.
* INPUT: FULLY STACKED REGISTERS FROM AN INTERRUPT
* OUTPUT: DPR LOADED TO WORK PAGE

ERRMSG  FCB     '?,BELL,$20,EOT ; ERROR RESPONSE

LDDP    LDB     BASEPG,PCR      ; LOAD DIRECT PAGE HIGH BYTE
        TFR     B,DP            ; SETUP DIRECT PAGE REGISTER
        CMPA    3,S             ; ? IS STACK VALID
        BEQ     RTS             ; YES, RETURN
        LDS     <RSTACK         ; RESET TO INITIAL STACK POINTER
ERROR   LEAX    ERRMSG,PCR      ; LOAD ERROR REPORT
        SWI                     ; SEND OUT BEFORE REGISTERS
        FCB     PDATA           ; ON NEXT LINE
* FALL INTO BREAKPOINT HANDLER

**********************************************
* [SWI FUNCTION 10]
* BREAKPOINT PROGRAM FUNCTION
* PRINT REGISTERS AND GO TO COMMAND HANLER
***********************************************

ZBKPNT  BSR     REGPRS          ; PRINT OUT REGISTERS
ZBKCMD  LBRA    CMDNEP          ; NOW ENTER COMMAND HANDLER

********************************************
* IRQ, RESERVED, SWI2 AND SWI3 INTERRUPT HANDLERS
* THE DEFAULT HANDLING IS TO CAUSE A BREAKPOINT.
********************************************
SWI2R   EQU     *               ; SWI2 ENTRY
SWI3R   EQU     *               ; SWI3 ENTRY
IRQR    EQU     *               ; IRQ ENTRY
RSRVDR  BSR     LDDP            ; SET BASE PAGE, VALIDATE STACK
        BRA     ZBKPNT          ; FORCE A BREAKPOINT

******************************************
* FIRQ HANDLER
* JUST RETURN FOR THE FIRQ INTERRUPT
******************************************
FIRQR   EQU     RTI             ; IMMEDIATE RETURN

**************************************************
* DEFAULT I/O DRIVERS
**************************************************
* CIDTA - RETURN CONSOLE INPUT CHARACTER
* OUTPUT: C=0 IF NO DATA READY, C=1 A=CHARACTER
* U VOLATILE

CIDTA   LDU     <VECTAB+_ACIA   ; LOAD ACIA ADDRESS
        LDA     ,U              ; LOAD STATUS REGISTER
        LSRA                    ; TEST RECEIVER REGISTER FLAG
        BCC     CIRTN           ; RETURN IF NOTHING
        LDA     1,U             ; LOAD DATA BYTE
CIRTN   RTS                     ; RETURN TO CALLER

* CION - INPUT CONSOLE INITIALIZATION
* COON - OUTPUT CONSOLE INITIALIZATION
* A,X VOLATILE
CION   EQU      *
COON   LDA      #3              ; RESET ACIA CODE
       LDX      <VECTAB+_ACIA   ; LOAD ACIA ADDRESS
       STA      ,X              ; STORE INTO STATUS REGISTER
       LDA      #$51            ; SET CONTROL
       STA      ,X              ; REGISTER UP
RTS    RTS                      ; RETURN TO CALLER

* THE FOLLOWING HAVE NO DUTIES TO PERFORM
CIOFF EQU       RTS             ; CONSOLE INPUT OFF
COOFF EQU       RTS             ; CONSOLE OUTPUT OFF

* CODTA - OUTPUT CHARACTER TO CONSOLE DEVICE
* INPUT: A=CHARACTER TO SEND
* OUTPUT: CHAR SENT TO TERMINAL WITH PROPER PADDING
* ALL REGISTERS TRANSPARENT

CODTA   PSHS    U,D,CC          ; SAVE REGISTERS,WORK BYTE
        LDU     <VECTAB+_ACIA   ; ADDRESS ACIA
        BSR     CODTAO          ; CALL OUTPUT CHAR SUBROUTINE
        CMPA    #DLE            ; ? DATA LINE ESCAPE
        BEQ     CODTRT          ; YES, RETURN
        LDB     <VECTAB+_PAD    ; DEFAULT TO CHAR PAD COUNT
        CMPA    #CR             ; ? CR
        BNE     CODTPD          ; BRANCH NO
        LDB     <VECTAB+_PAD+1  ; LOAD NEW LINE PAD COUNT
CODTPD  CLRA                    ; CREATE NULL
        STB     ,S              ; SAVE COUNT
        FCB     SKIP2           ; ENTER LOOP
CODTLP  BSR     CODTAO          ; SEND NULL
        DEC     ,S              ; ? FINISHED
        BPL     CODTLP          ; NO, CONTINUE WITH MORE
CODTRT  PULS    PC,U,D,CC       ; RESTORE REGISTERS AND RETURN

CODTAD  LBSR    XQPAUS          ; TEMPORARY GIVE UP CONTROL
CODTAO  LDB     ,U              ; LOAD ACIA CONTROL REGISTER
        BITB    #$02            ; ? TX REGISTER CLEAR
        BEQ     CODTAD          ; RELEASE CONTROL IF NOT
        STA     1,U             ; STORE INTO DATA REGISTER
        RTS                     ; RETURN TO CALLER
*E

* BSON - TURN ON READ/VERIFY/PUNCH MECHANISM
* A IS VOLATILE

BSON    LDA     #$11            ; SET READ CODE
        TST     6,S             ; ? READ OR VERIFY
        BNE     BSON2           ; BRANCH YES
        INCA                    ; SET TO WRITE
BSON2   SWI                     ; PERFORM OUTPUT
        FCB     OUTCH           ; FUNCTION
        INC     <MISFLG         ; SET LOAD IN PROGRESS FLAG
        RTS                     ; RETURN TO CALLER

* BSOFF - TURN OFF READ/VERIFY/PUNCH MECHANISM
* A,X VOLATILE

BSOFF   LDA     #$14            ; TO DC4 - STOP
        SWI                     ; SEND OUT
        FCB     OUTCH           ; FUNCTION
        DECA                    ; CHANGE TO DC3 (X-OFF)
        SWI                     ; SEND OUT
        FCB     OUTCH           ; FUNCTION
        DEC     <MISFLG         ; CLEAR LOAD IN PROGRESS FLAG
        LDX     #25000          ; DELAY 1 SECOND (2MHZ CLOCK)
BSOFLP  LEAX    -1,X            ; COUNT DOWN
        BNE     BSOFLP          ; LOOP TILL DONE
        RTS                     ; RETURN TO CALLER

* BSDTA - READ/VERIFY/PUNCH HANDLER
* INPUT: S+6=CODE BYTE, VERIFY(-1),PUNCH(0),LOAD(1)
* S+4=START ADDRESS
* S+2=STOP ADDRESS
* S+0=RETURN ADDRESS
* OUTPUT: Z=1 NORMAL COMPLETION, Z=0 INVALID LOAD/VER
* REGISTERS ARE VOLATILE
BSDTA   LDU     2,S             ; U=TO ADDRESS OR OFFSET
        TST     6,S             ; ? PUNCH
        BEQ     BSDPUN          ; BRANCH YES

* DURING READ/VERIFY: S+2=MSB ADDRESS SAVE BYTE
* S+1=BYTE COUNTER
* S+0=CHECKSUM
* U HOLDS OFFSET
        LEAS    -3,S            ; ROOM FOR WORK/COUNTER/CHECKSUM
BSDLD1  SWI                     ; GET NEXT CHARACTER
        FCB     INCHNP          ; FUNCTION
BSDLD2  CMPA    #'S             ; ? START OF S1/S9
        BNE     BSDLD1          ; BRANCH NOT
        SWI                     ; GET NEXT CHARACTER
        FCB     INCHNP          ; FUNCTION
        CMPA    #'9             ; ? HAVE S9
        BEQ     BSDSRT          ; YES, RETURN GOOD CODE
        CMPA    #'1             ; ? HAVE NEW RECORD
        BNE     BSDLD2          ; BRANCH IF NOT
        CLR     ,S              ; CLEAR CHECKSUM
        BSR     BYTE            ; OBTAIN BYTE COUNT
        STB     1,S             ; SAVE FOR DECREMENT

* READ ADDRESS
        BSR     BYTE            ; OBTAIN HIGH VALUE
        STB     2,S             ; SAVE IT
        BSR     BYTE            ; OBTAIN LOW VALUE
        LDA     2,S             ; MAKE D=VALUE
        LEAY    D,U             ; Y=ADDRESS+OFFSET
* STORE TEXT
BSDNXT  BSR     BYTE            ; NEXT BYTE
        BEQ     BSDEOL          ; BRANCH IF CHECKSUM
        TST     9,S             ; ? VERIFY ONLY
        BMI     BSDCMP          ; YES, ONLY COMPARE
        STB     ,Y              ; STORE INTO MEMORY
BSDCMP  CMPB    ,Y+             ; ? VALID RAM
        BEQ     BSDNXT          ; YES, CONTINUE READING
BSDSRT  PULS    PC,X,A          ; RETURN WITH Z SET PROPER
BSDEOL  INCA                    ; ? VALID CHECKSUM
        BEQ     BSDLD1          ; BRANCH YES
        BRA     BSDSRT          ; RETURN Z=0 INVALID

* BYTE BUILDS 8 BIT VALUE FROM TWO HEX DIGITS IN
BYTE    BSR     BYTHEX         ; OBTAIN FIRST HEX
        LDB     #16            ; PREPARE SHIFT
        MUL                    ; OVER TO A
        BSR     BYTHEX         ; OBTAIN SECOND HEX
        PSHS    B              ; SAVE HIGH HEX
        ADDA    ,S+            ; COMBINE BOTH SIDES
        TFR     A,B            ; SEND BACK IN B
        ADDA    2,S            ; COMPUTE NEW CHECKSUM
        STA     2,S            ; STORE BACK
        DEC     3,S            ; DECREMENT BYTE COUNT
BYTRTS  RTS                    ; RETURN TO CALLER

BYTHEX  SWI                    ; GET NEXT HEX
        FCB     INCHNP         ; CHARACTER
        LBSR    CNVHEX         ; CONVERT TO HEX
        BEQ     BYTRTS         ; RETURN IF VALID HEX
        PULS    PC,U,Y,X,A     ; RETURN TO CALLER WITH Z=0

* PUNCH STACK USE: S+8=TO ADDRESS
*                  S+6=RETURN ADDRESS
*                  S+4=SAVED PADDING VALUES
*                  S+2 FROM ADDRESS
*                  S+1=FRAME COUNT/CHECKSUM
*                  S+0=BYTE COUNT

BSDPUN  LDU     <VECTAB+_PAD    ; LOAD PADDING VALUES
        LDX     4,S             ; X=FROM ADDRESS
        PSHS    U,X,D           ; CREATE STACK WORK AREA
        LDD     #24             ; SET A=0, B=24
        STB     <VECTAB+_PAD    ; SETUP 24 CHARACTER PADS
        SWI                     ; SEND NULLS OUT
        FCB     OUTCH           ; FUNCTION
        LDB     #4              ; SETUP NEW LINE PAD TO 4
        STD     <VECTAB+_PAD    ; SETUP PUNCH PADDING
* CALCULATE SIZE
BSPGO   LDD     8,S             ; LOAD TO
        SUBD    2,S             ; MINUS FROM=LENGTH
        CMPD    #24             ; ? MORE THAN 23
        BLO     BSPOK           ; NO, OK
        LDB     #23             ; FORCE TO 23 MAX
BSPOK   INCB                    ; PREPARE COUNTER
        STB     ,S              ; STORE BYTE COUNT
        ADDB    #3              ; ADJUST TO FRAME COUNT
        STB     1,S             ; SAVE

*PUNCH CR,LF,NULS,S,1
       LEAX     <BSPSTR,PCR     ; LOAD START RECORD HEADER
       SWI                      ; SEND OUT
       FCB      PDATA           ; FUNCTION
* SEND FRAME COUNT
       CLRB                     ; INITIALIZE CHECKSUM
       LEAX     1,S             ; POINT TO FRAME COUNT AND ADDR
       BSR      BSPUN2          ; SEND FRAME COUNT
*DATA ADDRESS
      BSR       BSPUN2          ; SEND ADDRESS HI
      BSR       BSPUN2          ; SEND ADDRESS LOW
*PUNCH DATA
       LDX      2,S             ; LOAD START DATA ADDRESS
BSPMRE BSR      BSPUN2          ; SEND OUT NEXT BYTE
       DEC      ,S              ; ? FINAL BYTE
       BNE      BSPMRE          ; LOOP IF NOT DONE
       STX      2,S             ; UPDATE FROM ADDRESS VALUE
*PUNCH CHECKSUM
       COMB                     ; COMPLEMENT
       STB      1,S             ; STORE FOR SENDOUT
       LEAX     1,S             ; POINT TO IT
       BSR      BSPUNC          ; SEND OUT AS HEX
       LDX      8,S             ; LOAD TOP ADDRESS
       CMPX     2,S             ; ? DONE
       BHS      BSPGO           ; BRANCH NOT
       LEAX     <BSPEOF,PCR     ; PREPARE END OF FILE
       SWI                      ; SEND OUT STRING
       FCB      PDATA           ; FUNCTION
       LDD      4,S             ; RECOVER PAD COUNTS
       STD      <VECTAB+_PAD    ; RESTORE
       CLRA                     ; SET Z=1 FOR OK RETURN
       PULS     PC,U,X,D        ; RETURN WITH OK CODE
BSPUN2 ADDB     ,X              ; ADD TO CHECKSUM
BSPUNC LBRA     ZOUT2H          ; SEND OUT AS HEX AND RETURN

BSPSTR FCB      'S,'1,EOT        ; CR,LF,NULLS,S,1
BSPEOF FCC      /S9030000FC/         ; EOF STRING
       FCB      CR,LF,EOT

* HSDTA - HIGH SPEED PRINT MEMORY
* INPUT: S+4=START ADDRESS
* S+2=STOP ADDRESS
* S+0=RETURN ADDRESS
* X,D VOLATILE

* SEND TITLE

HSDTA   SWI                     ; SEND NEW LINE
        FCB     PCRLF           ; FUNCTION
        LDB     #6              ; PREPARE 6 SPACES
HSBLNK  SWI                     ; SEND BLANK
        FCB     SPACE           ; FUNCTION
        DECB                    ; COUNT DOWN
        BNE     HSBLNK          ; LOOP IF MORE
        CLRB                    ; SETUP BYTE COUNT
HSHTTL  TFR     B,A             ; PREPARE FOR CONVERT
        LBSR    ZOUTHX          ; CONVERT TO A HEX DIGIT
        SWI                     ; SEND BLANK
        FCB     SPACE           ; FUNCTION
        SWI                     ; SEND ANOTHER
        FCB     SPACE           ; BLANK
        INCB                    ; UP ANOTHER
        CMPB    #$10            ; ? PAST 'F'
        BLO     HSHTTL          ; LOOP UNTIL SO
HSHLNE  SWI                     ; TO NEXT LINE
        FCB     PCRLF           ; FUNCTION
        BCS     HSDRTN          ; RETURN IF USER ENTERED CTL-X
        LEAX    4,S             ; POINT AT ADDRESS TO CONVERT
        SWI                     ; PRINT OUT ADDRESS
        FCB     OUT4HS          ; FUNCTION
        LDX     4,S             ; LOAD ADDRESS PROPER
        LDB     #16             ; NEXT SIXTEEN
HSHNXT  SWI                     ; CONVERT BYTE TO HEX AND SEND
        FCB     OUT2HS          ; FUNCTION
        DECB                    ; COUNT DOWN
        BNE     HSHNXT          ; LOOP IF NOT SIXTEENTH
        SWI                     ; SEND BLANK
        FCB     SPACE           ; FUNCTION
        LDX     4,S             ; RELOAD FROM ADDRESS
        LDB     #16             ; COUNT
HSHCHR  LDA     ,X+             ; NEXT BYTE
        BMI     HSHDOT          ; TOO LARGE, TO A DOT
        CMPA    #'              ; ? LOWER THAN A BLANK
        BHS     HSHCOK          ; NO, BRANCH OK
HSHDOT  LDA     #'.             ; CONVERT INVALID TO A BLANK
HSHCOK  SWI                     ; SEND CHARACTER
        FCB     OUTCH           ; FUNCTION
        DECB                    ; ? DONE
        BNE     HSHCHR          ; BRANCH NO
        CMPX    2,S             ; ? PAST LAST ADDRESS
        BHS     HSDRTN          ; QUIT IF SO
        STX     4,S             ; UPDATE FROM ADDRESS
        LDA     5,S             ; LOAD LOW BYTE ADDRESS
        ASLA                    ; ? TO SECTION BOUNDARY
        BNE     HSHLNE          ; BRANCH IF NOT
        BRA     HSDTA           ; BRANCH IF SO
HSDRTN  SWI                     ; SEND NEW LINE
        FCB     PCRLF           ; FUNCTION
        RTS                     ; RETURN TO CALLER
*F

***********************************************
*     A S S I S T 0 9    C O M M A N D S
***********************************************

*************REGISTERS - DISPLAY AND CHANGE REGISTERS
CREG    BSR     REGPRT          ; PRINT REGISTERS
        INCA                    ; SET FOR CHANGE FUNCTION
        BSR     REGCHG          ; GO CHANGE, DISPLAY REGISTERS
        RTS                     ; RETURN TO COMMAND PROCESSOR

********************************************
* REGPRT - PRINT/CHANGE REGISTERS SUBROUTINE
* WILL ABORT TO 'CMDBAD' IF OVERFLOW DETECTED DURING
* A CHANGE OPERATION. CHANGE DISPLAYS REGISTERS WHEN
* DONE.

* REGISTER MASK LIST CONSISTS OF:
* A) CHARACTERS DENOTING REGISTER
* B) ZERO FOR ONE BYTE, -1 FOR TWO
* C) OFFSET ON STACK TO REGISTER POSITION
* INPUT: SP+4=STACKED REGISTERS
* A=0 PRINT, A#0 PRINT AND CHANGE
* OUTPUT: (ONLY FOR REGISTER DISPLAY)
* C=1 CONTROL-X ENTERED, C=0 OTHERWISE
* VOLATILE: D,X (CHANGE)
* B,X (DISPLAY)
*******************************************

REGMSK  FCB     'P,'C,-1,19     ; PC REG
        FCB     'A,0,10         ; A REG
        FCB     'B,0,11         ; B REG
        FCB     'X,-1,13        ; X REG
        FCB     'Y,-1,15        ; Y REG
        FCB     'U,-1,17        ; U REG
        FCB     'S,-1,1         ; S REG
        FCB     'C,'C,0,9       ; CC REG
        FCB     'D,'P,0,12      ; DP REG
        FCB     0               ; END OF LIST

REGPRT  CLRA                    ; SETUP PRINT ONLY FLAG
REGCHG  LEAX    4+12,S          ; READY STACK VALUE
        PSHS    Y,X,A           ; SAVE ON STACK WITH OPTION
        LEAY    REGMSK,PCR      ; LOAD REGISTER MASK
REGP1   LDD     ,Y+             ; LOAD NEXT CHAR OR <=0
        TSTA                    ; ? END OF CHARACTERS
        BLE     REGP2           ; BRANCH NOT CHARACTER
        SWI                     ; SEND TO CONSOLE
        FCB     OUTCH           ; FUNCTION BYTE
        BRA     REGP1           ; CHECK NEXT
REGP2   LDA     #'-             ; READY '-'
        SWI                     ; SEND OUT
        FCB     OUTCH           ; WITH OUTCH
        LEAX    B,S             ; X->REGISTER TO PRINT
        TST     ,S              ; ? CHANGE OPTION
        BNE     REGCNG          ; BRANCH YES
        TST     -1,Y            ; ? ONE OR TWO BYTES
        BEQ     REGP3           ; BRANCH ZERO MEANS ONE
        SWI                     ; PERFORM WORD HEX
        FCB     OUT4HS          ; FUNCTION
        FCB     SKIP2           ; SKIP BYTE PRINT
REGP3   SWI                     ; PERFORM BYTE HEX
        FCB     OUT2HS          ; FUNCTION
REG4    LDD     ,Y+             ; TO FRONT OF NEXT ENTRY
        TSTB                    ; ? END OF ENTRIES
        BNE     REGP1           ; LOOP IF MORE
        SWI                     ; FORCE NEW LINE
        FCB     PCRLF           ; FUNCTION
REGRTN  PULS    PC,Y,X,A        ; RESTORE STACK AND RETURN

REGCNG  BSR     BLDNNB          ; INPUT BINARY NUMBER
        BEQ     REGNXC          ; IF CHANGE THEN JUMP
        CMPA    #CR             ; ? NO MORE DESIRED
        BEQ     REGAGN          ; BRANCH NOPE
        LDB     -1,Y            ; LOAD SIZE FLAG
        DECB                    ; MINUS ONE
        NEGB                    ; MAKE POSITIVE
        ASLB                    ; TIMES TWO (=2 OR =4)
REGSKP  SWI                     ; PERFORM SPACES
        FCB     SPACE           ; FUNCTION
        DECB
        BNE     REGSKP          ; LOOP IF MORE
        BRA     REG4            ; CONTINUE WITH NEXT REGISTER
REGNXC  STA     ,S              ; SAVE DELIMITER IN OPTION
*                               ; (ALWAYS > 0)
        LDD     <NUMBER         ; OBTAIN BINARY RESULT
        TST     -1,Y            ; ? TWO BYTES WORTH
        BNE     REGTWO          ; BRANCH YES
        LDA     ,-X             ; SETUP FOR TWO
REGTWO  STD     ,X              ; STORE IN NEW VALUE
        LDA     ,S              ; RECOVER DELIMITER
        CMPA    #CR             ; ? END OF CHANGES
        BNE     REG4            ; NO, KEEP ON TRUCK'N
* MOVE STACKED DATA TO NEW STACK IN CASE STACK
* POINTER HAS CHANGED
REGAGN  LEAX    TSTACK,PCR      ; LOAD TEMP AREA
        LDB     #21             ; LOAD COUNT
REGTF1  PULS    A               ; NEXT BYTE
        STA     ,X+             ; STORE INTO TEMP
        DECB                    ; COUNT DOWN
        BNE     REGTF1          ; LOOP IF MORE
        LDS     -20,X           ; LOAD NEW STACK POINTER
        LDB     #21             ; LOAD COUNT AGAIN
REGTF2 LDA      ,-X             ; NEXT TO STORE
       PSHS     A               ; BACK ONTO NEW STACK
       DECB                     ; COUNT DOWN
       BNE      REGTF2          ; LOOP IF MORE
       BRA      REGRTN          ; GO RESTART COMMAND

*********************************************
* BLDNUM - BUILDS BINARY VALUE FROM INPUT HEX
* THE ACTIVE EXPRESSION HANDLER IS USED.
* INPUT: S=RETURN ADDRESS
* OUTPUT: A=DELIMITER WHICH TERMINATED VALUE
* (IF DELM NOT ZERO)
* "NUMBER"=WORD BINARY RESULT
* Z=1 IF INPUT RECEIVED, Z=0 IF NO HEX RECEIVED
* REGISTERS ARE TRANSPARENT
**********************************************
* EXECUTE SINGLE OR EXTENDED ROM EXPRESSION HANDLER
*
* THE FLAG "DELIM" IS USED AS FOLLOWS:
* DELIM=0 NO LEADING BLANKS, NO FORCED TERMINATOR
* DELIM=CHR ACCEPT LEADING 'CHR'S, FORCED TERMINATOR
BLDNNB  CLRA                    ; NO DYNAMIC DELIMITER
        FCB     SKIP2           ; SKIP NEXT INSTRUCTION
* BUILD WITH LEADING BLANKS
BLDNUM  LDA     #'              ; ALLOW LEADING BLANKS
        STA     <DELIM          ; STORE AS DELIMITER
        JMP     [VECTAB+_EXPAN,PCR]   ; TO EXP ANALYZER
* THIS IS THE DEFAULT SINGLE ROM ANALYZER. WE ACCEPT:
* 1) HEX INPUT
* 2) 'M' FOR LAST MEMORY EXAMINE ADDRESS
* 3) 'P' FOR PROGRAM COUNTER ADDRESS
* 4) 'W' FOR WINDOW VALUE
* 5) '@' FOR INDIRECT VALUE

EXP1    PSHS    X,B             ; SAVE REGISTERS
EXPDLM  BSR     BLDHXI          ; CLEAR NUMBER, CHECK FIRST CHAR
        BEQ     EXP2            ; IF HEX DIGIT CONTINUE BUILDING
* SKIP BLANKS IF DESIRED
        CMPA    <DELIM          ; ? CORRECT DELIMITER
        BEQ     EXPDLM          ; YES, IGNORE IT
* TEST FOR M OR P
        LDX     <ADDR           ; DEFAULT FOR 'M'
        CMPA    #'M             ; ? MEMORY EXAMINE ADDR WANTED
        BEQ     EXPTDL          ; BRANCH IF SO
        LDX     <PCNTER         ; DEFAULT FOR 'P'
        CMPA    #'P             ; ? LAST PROGRAM COUNTER WANTED
        BEQ     EXPTDL          ; BRANCH IF SO
        LDX     <WINDOW         ; DEFAULT TO WINDOW
        CMPA    #'W             ; ? WINDOW WANTED
        BEQ     EXPTDL

EXPRTN  PULS    PC,X,B          ; RETURN AND RESTORE REGISTERS
* GOT HEX, NOW CONTINUE BUILDING
EXP2    BSR     BLDHEX          ; COMPUTE NEXT DIGIT
        BEQ     EXP2            ; CONTINUE IF MORE
        BRA     EXPCDL          ; SEARCH FOR +/-
* STORE VALUE AND CHECK IF NEED DELIMITER
EXPTDI  LDX     ,X              ; INDIRECTION DESIRED
EXPTDL  STX     <NUMBER         ; STORE RESULT
        TST     <DELIM          ; ? TO FORCE A DELIMITER
        BEQ     EXPRTN          ; RETURN IF NOT WITH VALUE
        BSR     READ            ; OBTAIN NEXT CHARACTER
* TEST FOR + OR -
EXPCDL  LDX     <NUMBER         ; LOAD LAST VALUE
        CMPA    #'+             ; ? ADD OPERATOR
        BNE     EXPCHM          ; BRANCH NOT
        BSR     EXPTRM          ; COMPUTE NEXT TERM
        PSHS    A               ; SAVE DELIMITER
        LDD     <NUMBER         ; LOAD NEW TERM
EXPADD  LEAX    D,X             ; ADD TO X
        STX     <NUMBER         ; STORE AS NEW RESULT
        PULS    A               ; RESTORE DELIMITER
        BRA     EXPCDL          ; NOW TEST IT
EXPCHM  CMPA    #'-             ; ? SUBTRACT OPERATOR
        BEQ     EXPSUB          ; BRANCH IF SO
        CMPA    #'@             ; ? INDIRECTION DESIRED
        BEQ     EXPTDI          ; BRANCH IF SO
        CLRB                    ; SET DELIMITER RETURN
        BRA     EXPRTN          ; AND RETURN TO CALLER
EXPSUB  BSR     EXPTRM          ; OBTAIN NEXT TERM
        PSHS    A               ; SAVE DELIMITER
        LDD     <NUMBER         ; LOAD UP NEXT TERM
        NEGA                    ; NEGATE A
        NEGB                    ; NEGATE B
        SBCA    #0              ; CORRECT FOR A
        BRA     EXPADD          ; GO ADD TO EXPRESSION
* COMPUTE NEXT EXPRESSION TERM
* OUTPUT: X=OLD VALUE
* 'NUMBER'=NEXT TERM
EXPTRM  BSR     BLDNUM          ; OBTAIN NEXT VALUE
        BEQ     CNVRTS          ; RETURN IF VALID NUMBER
BLDBAD  LBRA    CMDBAD          ; ABORT COMMAND IF INVALID

*********************************************
* BUILD BINARY VALUE USING INPUT CHARACTERS.
* INPUT: A=ASCII HEX VALUE OR DELIMITER
* SP+0=RETURN ADDRESS
* SP+2=16 BIT RESULT AREA
* OUTPUT: Z=1 A=BINARY VALUE
* Z=0 IF INVALID HEX CHARACTER (A UNCHANGED)
* VOLATILE: D
****************************************
BLDHXI  CLR     <NUMBER         ; CLEAR NUMBER
        CLR     <NUMBER+1       ; CLEAR NUMBER
BLDHEX  BSR     READ            ; GET INPUT CHARACTER
BLDHXC  BSR     CNVHEX          ; CONVERT AND TEST CHARACTER
        BNE     CNVRTS          ; RETURN IF NOT A NUMBER
        LDB     #16             ; PREPARE SHIFT
        MUL                     ; BY FOUR PLACES
        LDA     #4              ; ROTATE BINARY INTO VALUE
BLDSHF  ASLB                    ; OBTAIN NEXT BIT
        ROL     <NUMBER+1       ; INTO LOW BYTE
        ROL     <NUMBER         ; INTO HI BYTE
        DECA                    ; COUNT DOWN
        BNE     BLDSHF          ; BRANCH IF MORE TO DO
        BRA     CNVOK           ; SET GOOD RETURN CODE

****************************************
* CONVERT ASCII CHARACTER TO BINARY BYTE
* INPUT: A=ASCII
* OUTPUT: Z=1 A=BINARY VALUE
* Z=0 IF INVALID
* ALL REGISTERS TRANSPARENT
* (A UNALTERED IF INVALID HEX)
**************************************
CNVHEX  CMPA    #'0             ; ? LOWER THAN A ZERO
        BLO     CNVRTS          ; BRANCH NOT VALUE
        CMPA    #'9             ; ? POSSIBLE A-F
        BLE     CNVGOT          ; BRANCH NO TO ACCEPT
        CMPA    #'A             ; ? LESS THEN TEN
        BLO     CNVRTS          ; RETURN IF MINUS (INVALID)
        CMPA    #'F             ; ? NOT TOO LARGE
        BHI     CNVRTS          ; NO, RETURN TOO LARGE
        SUBA    #7              ; DOWN TO BINARY
CNVGOT  ANDA    #$0F            ; CLEAR HIGH HEX
CNVOK   ORCC    #4              ; FORCE ZERO ON FOR VALID HEX
CNVRTS  RTS                     ; RETURN TO CALLER

* GET INPUT CHAR, ABORT COMMAND IF CONTROL-X (CANCEL)
READ     SWI                    ; GET NEXT CHARACTER
         FCB    INCHNP          ; FUNCTION
         CMPA   #CAN            ; ? ABORT COMMAND
         BEQ    BLDBAD          ; BRANCH TO ABORT IF SO
         RTS                    ; RETURN TO CALLER
*G

***************GO - START PROGRAM EXECUTION
CGO      BSR    GOADDR          ; BUILD ADDRESS IF NEEDED
         RTI                    ; START EXECUTING

* FIND OPTIONAL NEW PROGRAM COUNTER. ALSO ARM THE
* BREAKPOINTS.
GOADDR   PULS   Y,X             ; RECOVER RETURN ADDRESS
         PSHS   X               ; STORE RETURN BACK
         BNE    GONDFT          ; IF NO CARRIAGE RETURN THEN NEW PC

* DEFAULT PROGRAM COUNTER, SO FALL THROUGH IF
* IMMEDIATE BREAKPOINT.
         LBSR   CBKLDR          ; SEARCH BREAKPOINTS
         LDX    12,S            ; LOAD PROGRAM COUNTER
ARMBLP  DECB                    ; COUNT DOWN
        BMI     ARMBK2          ; DONE, NONE TO SINGLE TRACE
        LDA     -NUMBKP*2,Y     ; PRE-FETCH OPCODE
        CMPX    ,Y++            ; ? IS THIS A BREAKPOINT
        BNE     ARMBLP          ; LOOP IF NOT
        CMPA    #$3F            ; ? SWI BREAKPOINTED
        BNE     ARMNSW          ; NO, SKIP SETTING OF PASS FLAG
        STA     <SWIBFL         ; SHOW UPCOMING SWI NOT BRKPNT
ARMNSW  INC     <MISFLG         ; FLAG THRU A BREAKPOINT
        LBRA    CDOT            ; DO SINGLE TRACE W/O BREAKPOINTS

* OBTAIN NEW PROGRAM COUNTER
GONDFT  LBSR    CDNUM           ; OBTAIN NEW PROGRAM COUNTER
        STD     12,S            ; STORE INTO STACK
ARMBK2  LBSR    CBKLDR          ; OBTAIN TABLE
        NEG     <BKPTCT         ; COMPLEMENT TO SHOW ARMED
ARMLOP  DECB                    ; ? DONE
        BMI     CNVRTS          ; RETURN WHEN DONE
        LDA     [,Y]            ; LOAD OPCODE
        STA     -NUMBKP*2,Y     ; STORE INTO OPCODE TABLE
        LDA     #$3F            ; READY "SWI" OPCODE
        STA     [,Y++]          ; STORE AND MOVE UP TABLE
        BRA     ARMLOP          ; AND CONTINUE

*******************CALL - CALL ADDRESS AS SUBROUTINE
CCALL   BSR     GOADDR          ; FETCH ADDRESS IF NEEDED
        PULS    U,Y,X,DP,D,CC   ; RESTORE USERS REGISTERS
        JSR     [,S++]          ; CALL USER SUBROUTINE
CGOBRK  SWI                     ; PERFORM BREAKPOINT
        FCB     BRKPT           ; FUNCTION
        BRA     CGOBRK          ; LOOP UNTIL USER CHANGES PC

****************MEMORY - DISPLAY/CHANGE MEMORY
* CMEMN AND CMPADP ARE DIRECT ENTRY POINTS FROM
* THE COMMAND HANDLER FOR QUICK COMMANDS
CMEM    LBSR    CDNUM           ; OBTAIN ADDRESS
CMEMN   STD     <ADDR           ; STORE DEFAULT
CMEM2   LDX     <ADDR           ; LOAD POINTER
        LBSR    ZOUT2H          ; SEND OUT HEX VALUE OF BYTE
        LDA     #'-             ; LOAD DELIMITER
        SWI                     ; SEND OUT
        FCB     OUTCH           ; FUNCTION
CMEM4   LBSR    BLDNNB          ; OBTAIN NEW BYTE VALUE
        BEQ     CMENUM          ; BRANCH IF NUMBER
* COMA - SKIP BYTE
        CMPA    #',             ; ? COMMA
        BNE     CMNOTC          ; BRANCH NOT
        STX     <ADDR           ; UPDATE POINTER
        LEAX    1,X             ; TO NEXT BYTE
        BRA     CMEM4           ; AND INPUT IT
CMENUM  LDB     <NUMBER+1       ; LOAD LOW BYTE VALUE
        BSR     MUPDAT          ; GO OVERLAY MEMORY BYTE
        CMPA    #',             ; ? CONTINUE WITH NO DISPLAY
        BEQ     CMEM4           ; BRANCH YES
* QUOTED STRING
CMNOTC  CMPA    #$27            ; ? QUOTED STRING
        BNE     CMNOTQ          ; BRANCH NO
CMESTR  BSR     READ            ; OBTAIN NEXT CHARACTER
        CMPA    #$27            ; ? END OF QUOTED STRING
        BEQ     CMSPCE          ; YES, QUIT STRING MODE
        TFR     A,B             ; TO B FOR SUBROUTINE
        BSR     MUPDAT          ; GO UPDATE BYTE
        BRA     CMESTR          ; GET NEXT CHARACTER
* BLANK - NEXT BYTE
CMNOTQ  CMPA    #$20            ; ? BLANK FOR NEXT BYTE
        BNE     CMNOTB          ; BRANCH NOT
        STX     <ADDR           ; UPDATE POINTER
CMSPCE  SWI                     ; GIVE SPACE
        FCB     SPACE           ; FUNCTION
        BRA     CMEM2           ; NOW PROMPT FOR NEXT

* LINE FEED - NEXT BYTE WITH ADDRESS
CMNOTB  CMPA    #LF             ; ? LINE FEED FOR NEXT BYTE
        BNE     CMNOTL          ; BRANCH NO
        LDA     #CR             ; GIVE CARRIAGE RETURN
        SWI                     ; TO CONSOLE
        FCB     OUTCH           ; HANDLER
        STX     <ADDR           ; STORE NEXT ADDRESS
        BRA     CMPADP          ; BRANCH TO SHOW

* UP ARROW - PREVIOUS BYTE AND ADDRESS
CMNOTL  CMPA    #'^             ; ? UP ARROW FOR PREVIOUS BYTE
        BNE     CMNOTU          ; BRANCH NOT
        LEAX    -2,X            ; DOWN TO PREVIOUS BYTE
        STX     <ADDR           ; STORE NEW POINTER
CMPADS  SWI                     ; FORCE NEW LINE
        FCB     PCRLF           ; FUNCTION
CMPADP  BSR     PRTADR          ; GO PRINT ITS VALUE
        BRA     CMEM2           ; THEN PROMPT FOR INPUT

* SLASH - NEXT BYTE WITH ADDRESS
CMNOTU  CMPA    #'/             ; ? SLASH FOR CURRENT DISPLAY
        BEQ     CMPADS          ; YES, SEND ADDRESS
        RTS                     ; RETURN FROM COMMAND

* PRINT CURRENT ADDRESS
PRTADR  LDX     <ADDR           ; LOAD POINTER VALUE
        PSHS    X               ; SAVE X ON STACK
        LEAX    ,S              ; POINT TO IT FOR DISPLAY
        SWI                     ; DISPLAY POINTER IN HEX
        FCB     OUT4HS          ; FUNCTION
        PULS    PC,X            ; RECOVER POINTER AND RETURN

* UPDATE BYTE
MUPDAT  LDX     <ADDR           ; LOAD NEXT BYTE POINTER
        STB     ,X+             ; STORE AND INCREMENT X
        CMPB    -1,X            ; ? SUCCESFULL STORE
        BNE     MUPBAD          ; BRANCH FOR '?' IF NOT
        STX     <ADDR           ; STORE NEW POINTER VALUE
        RTS                     ; BACK TO CALLER
MUPBAD  PSHS    A               ; SAVE A REGISTER
        LDA     #'?             ; SHOW INVALID
        SWI                     ; SEND OUT
        FCB     OUTCH           ; FUNCTION
        PULS    PC,A            ; RETURN TO CALLER

********************WINDOW - SET WINDOW VALUE
CWINDO  BSR     CDNUM           ; OBTAIN WINDOW VALUE
        STD     <WINDOW         ; STORE IT IN
        RTS                     ; END COMMAND

******************DISPLAY - HIGH SPEED DISPLAY MEMORY
CDISP   BSR     CDNUM           ; FETCH ADDRESS
        ANDB    #$F0            ; FORCE TO 16 BOUNDARY
        TFR     D,Y             ; SAVE IN Y
        LEAX    15,Y            ; DEFAULT LENGTH
        BCS     CDISPS          ; BRANCH IF END OF INPUT
        BSR     CDNUM           ; OBTAIN COUNT
        LEAX    D,Y             ; ASSUME COUNT, COMPUTE END ADDR
CDISPS  PSHS    Y,X             ; SETUP PARAMETERS FOR HSDATA
        CMPD    2,S             ; ? WAS IT COUNT
        BLS     CDCNT           ; BRANCH YES
        STD     ,S              ; STORE HIGH ADDRESS
CDCNT   JSR     [VECTAB+_HSDTA,PCR] ; CALL PRINT ROUTINE
        PULS    PC,U,Y          ; CLEAN STACK AND END COMMAND

* OBTAIN NUMBER - ABORT IF NONE
* ONLY DELIMITERS OF CR, BLANK, OR '/' ARE ACCEPTED
* OUTPUT: D=VALUE, C=1 IF CARRIAGE RETURN DELMITER,
* ELSE C=0
CDNUM   LBSR    BLDNUM          ; OBTAIN NUMBER
        BNE     CDBADN          ; BRANCH IF INVALID
        CMPA    #'/             ; ? VALID DELIMITER
        BHI     CDBADN          ; BRANCH IF NOT FOR ERROR
        CMPA    #CR+1           ; LEAVE COMPARE FOR CARRIAGE RET
        LDD     <NUMBER         ; LOAD NUMBER
        RTS                     ; RETURN WITH COMPARE
CDBADN  LBRA    CMDBAD          ; RETURN TO ERROR MECHANISM

*****************PUNCH - PUNCH MEMORY IN S1-S9 FORMAT
CPUNCH  BSR     CDNUM           ; OBTAIN START ADDRESS
        TFR     D,Y             ; SAVE IN Y
        BSR     CDNUM           ; OBTAIN END ADDRESS
        CLR     ,-S             ; SETUP PUNCH FUNCTION CODE
        PSHS    Y,D             ; STORE VALUES ON STACK
CCALBS  JSR     [VECTAB+_BSON,PCR] ; INITIALIZE HANDLER
        JSR     [VECTAB+_BSDTA,PCR] ; PERFORM FUNCTION
        PSHS    CC              ; SAVE RETURN CODE
        JSR     [VECTAB+_BSOFF,PCR] ; TURN OFF HANDLER
        PULS    CC              ; OBTAIN CONDITION CODE SAVED
        BNE     CDBADN          ; BRANCH IF ERROR
        PULS    PC,Y,X,A        ; RETURN FROM COMMAND

*****************LOAD - LOAD MEMORY FROM S1-S9 FORMAT
CLOAD   BSR     CLVOFS          ; CALL SETUP AND PASS CODE
        FCB     1               ; LOAD FUNCTION CODE FOR PACKET

CLVOFS  LEAU    [,S++]          ; LOAD CODE IN HIGH BYTE OF U
        LEAU    [,U]            ; NOT CHANGING CC AND RESTORE S
        BEQ     CLVDFT          ; BRANCH IF CARRIAGE RETURN NEXT
        BSR     CDNUM           ; OBTAIN OFFSET
        FCB     SKIP2           ; SKIP DEFAULT OFFSET
CLVDFT  CLRA                    ; CREATE ZERO OFFSET
        CLRB                    ; AS DEFAULT
        PSHS    U,DP,D          ; SETUP CODE, NULL WORD, OFFSET
        BRA     CCALBS          ; ENTER CALL TO BS ROUTINES

******************VERIFY - COMPARE MEMORY WITH FILES
CVER    BSR     CLVOFS          ; COMPUTE OFFSET IF ANY
        FCB     -1              ; VERIFY FNCTN CODE FOR PACKET

*******************TRACE - TRACE INSTRUCTIONS
******************* . - SINGLE STEP TRACE
CTRACE  BSR     CDNUM           ; OBTAIN TRACE COUNT
        STD     <TRACEC         ; STORE COUNT
CDOT    LEAS    2,S             ; RID COMMAND RETURN FROM STACK
CTRCE3  LDU     [10,S]          ; LOAD OPCODE TO EXECUTE
        STU     <LASTOP         ; STORE FOR TRACE INTERRUPT
        LDU     <VECTAB+_PTM    ; LOAD PTM ADDRESS
        LDD     #$0701          ; 7,1 CYCLES DOWN+CYCLES UP
        STD     PTMTM1-PTM,U    ; START NMI TIMEOUT
        RTI                     ; RETURN FOR ONE INSTRUCTION

*************NULLS  -  SET NEW LINE AND CHAR PADDING
CNULLS  BSR     CDNUM           ; OBTAIN NEW LINE PAD
        STD     <VECTAB+_PAD    ; RESET VALUES
        RTS                     ; END COMMAND

******************STLEVEL - SET STACK TRACE LEVEL
CSTLEV  BEQ     STLDFT          ; TAKE DEFAULT
        BSR     CDNUM           ; OBTAIN NEW STACK LEVEL
        STD     <SLEVEL         ; STORE NEW ENTRY
        RTS                     ; TO COMMAND HANDLER
STLDFT  LEAX    14,S            ; COMPUTE NMI COMPARE
        STX     <SLEVEL         ; AND STORE IT
        RTS                     ; END COMMAND

******************OFFSET - COMPUTE SHORT AND LONG
******************                  BRANCH OFFSETS
COFFS   BSR     CDNUM           ; OBTAIN INSTRUCTION ADDRESS
        TFR     D,X             ; USE AS FROM ADDRESS
        BSR     CDNUM           ; OBTAIN TO ADDRESS
* D=TO INSTRUCTION, X=FROM INSTRUCTION OFFSET BYTE(S)
        LEAX    1,X             ; ADJUST FOR *+2 SHORT BRANCH
        PSHS    Y,X             ; STORE WORK WORD AND VALUE ON S
        SUBD    ,S              ; FIND OFFSET
        STD     ,S              ; SAVE OVER STACK
        LEAX    1,S             ; POINT FOR ONE BYTE DISPLAY
        SEX                     ; SIGN EXTEND LOW BYTE
        CMPA    ,S              ; ? VALID ONE BYTE OFFSET
        BNE     COFNO1          ; BRANCH IF NOT
        SWI                     ; SHOW ONE BYTE OFFSET
        FCB     OUT2HS          ; FUNCTION
COFNO1  LDU     ,S              ; RELOAD OFFSET
        LEAU    -1,U            ; CONVERT TO LONG BRANCH OFFSET
        STU     ,X              ; STORE BACK WHERE X POINTS NOW
        SWI                     ; SHOW TWO BYTE OFFSET
        FCB     OUT4HS          ; FUNCTION
        SWI                     ; FORCE NEW LINE
        FCB     PCRLF           ; FUNCTION
        PULS    PC,X,D          ; RESTORE STACK AND END COMMAND
*H

*************BREAKPOINT - DISPLAY/ENTER/DELETE/CLEAR
*************             BREAKPOINTS
CBKPT   BEQ     CBKDSP          ; BRANCH DISPLAY OF JUST 'B'
        LBSR    BLDNUM          ; ATTEMPT VALUE ENTRY
        BEQ     CBKADD          ; BRANCH TO ADD IF SO
        CMPA    #'-             ; ? CORRECT DELIMITER
        BNE     CBKERR          ; NO, BRANCH FOR ERROR
        LBSR    BLDNUM          ; ATTEMPT DELETE VALUE
        BEQ     CBKDLE          ; GOT ONE, GO DELETE IT
        CLR     <BKPTCT         ; WAS 'B -', SO ZERO COUNT
CBKRTS  RTS                     ; END COMMAND
* DELETE THE ENTRY
CBKDLE  BSR     CBKSET          ; SETUP REGISTERS AND VALUE
CBKDLP  DECB                    ; ? ANY ENTRIES IN TABLE
        BMI     CBKERR          ; BRANCH NO, ERROR
        CMPX    ,Y++            ; ? IS THIS THE ENTRY
        BNE     CBKDLP          ; NO, TRY NEXT
* FOUND, NOW MOVE OTHERS UP IN ITS PLACE
CBKDLM  LDX     ,Y++            ; LOAD NEXT ONE UP
        STX     -4,Y            ; MOVE DOWN BY ONE
        DECB                    ; ? DONE
        BPL     CBKDLM          ; NO, CONTINUE MOVE
        DEC     <BKPTCT         ; DECREMENT BREAKPOINT COUNT
CBKDSP  BSR     CBKSET          ; SETUP REGISTERS AND LOAD VALUE
        BEQ     CBKRTS          ; RETURN IF NONE TO DISPLY
CBKDSL  LEAX    ,Y++            ; POINT TO NEXT ENTRY
        SWI                     ; DISPLAY IN HEX
        FCB     OUT4HS          ; FUNCTION
        DECB                    ; COUNT DOWN
        BNE     CBKDSL          ; LOOP IF NGABLE RAM
        SWI                     ; SKIP TO NEW LINK
        FCB     PCRLF           ; FUNCTIONRTS
        RTS

* ADD NEW ENTRY
CBKADD  BSR     CBKSET          ; SETUP REGISTERS
        CMPB    #NUMBKP         ; ? ALREADY FULL
        BEQ     CBKERR          ; BRANCH ERROR IF SO
        LDA     ,X              ; LOAD BYTE TO TRAP
        STB     ,X              ; TRY TO CHANGE
        CMPB    ,X              ; ? CHANGEABLE RAM
        BNE     CBKERR          ; BRANCH ERROR IF NOT
        STA ,X                  ; RESTORE BYTE
CBKADL  DECB                    ; COUNT DOWN
        BMI     CBKADT          ; BRANCH IF DONE TO ADD IT
        CMPX    ,Y++            ; ? ENTRY ALREADY HERE
        BNE     CBKADL          ; LOOP IF NOT
CBKERR  LBRA    CMDBAD          ; RETURN TO ERROR PRODUCE
CBKADT  STX ,Y                  ; ADD THIS ENTRY
        CLR     -NUMBKP*2+1,Y   ; CLEAR OPTIONAL BYTE
        INC     <BKPTCT         ; ADD ONE TO COUNT
        BRA     CBKDSP          ; AND NOW DISPLAY ALL OF 'EM
* SETUP REGISTERS FOR SCAN
CBKSET  LDX     <NUMBER         ; LOAD VALUE DESIRED
CBKLDR  LEAY    BKPTBL,PCR      ; LOAD START OF TABLE
        LDB     <BKPTCT         ; LOAD ENTRY COUNT
        RTS                     ; RETURN

*****************ENCODE  -  ENCODE A POSTBYTE
CENCDE  CLR     ,-S             ; DEFAULT TO NOT INDIRECT
        CLRB                    ; ZERO POSTBYTE VALUE
        LEAX    <CONV1,PCR      ; START TABLE SEARCH
        SWI                     ; OBTAIN FIRST CHARACTER
        FCB     INCHNP          ; FUNCTION
        CMPA    #'[             ; ? INDIRECT HERE
        BNE     CEN2            ; BRANCH IF NOT
        LDA     #$10            ; SET INDIRECT BIT ON
        STA     ,S              ; SAVE FOR LATER
CENGET  SWI                     ; OBTAIN NEXT CHARACTER
        FCB     INCHNP          ; FUNCTION
CEN2    CMPA    #CR             ; ? END OF ENTRY
        BEQ     CEND1           ; BRANCH YES
CENLP1  TST     ,X              ; ? END OF TABLE
        BMI     CBKERR          ; BRANCH ERROR IF SO
        CMPA    ,X++            ; ? THIS THE CHARACTER
        BNE     CENLP1          ; BRANCH IF NOT
        ADDB    -1,X            ; ADD THIS VALUE
        BRA     CENGET          ; GET NEXT INPUT
CEND1   LEAX    <CONV2,PCR      ; POINT AT TABLE 2
        TFR     B,A             ; SAVE COPY IN A
        ANDA    #$60            ; ISOLATE REGISTER MASK
        ORA     ,S              ; ADD IN INDIRECTION BIT
        STA     ,S              ; SAVE BACK AS POSTBYTE SKELETON
        ANDB    #$9F            ; CLEAR REGISTER BITS
CENLP2  TST     ,X              ; ? END OF TABLE
        BEQ     CBKERR          ; BRANCH ERROR IF SO
        CMPB    ,X++            ; ? SAME VALUE
        BNE     CENLP2          ; LOOP IF NOT
        LDB     -1,X            ; LOAD RESULT VALUE
        ORB     ,S              ; ADD TO BASE SKELETON
        STB     ,S              ; SAVE POSTBYTE ON STACK
        LEAX    ,S              ; POINT TO IT
        SWI                     ; SEND OUT AS HEX
        FCB     OUT2HS          ; FUNCTION
        SWI                     ; TO NEXT LINE
        FCB     PCRLF           ; FUNCTION
        PULS    PC,B            ; END OF COMMAND

* TABLE ONE DEFINES VALID INPUT IN SEQUENCE
CONV1
        FCB     'A,$04,'B,$05,'D,$06,'H,$01
        FCB     'H,$01,'H,$01,'H,$00,',,$00
        FCB     '-,$09,'-,$01,'S,$70,'Y,$30
        FCB     'U,$50,'X,$10,'+,$07,'+,$01
        FCB     'P,$80,'C,$00,'R,$00,'],$00
        FCB     $FF             ; END OF TABLE

* CONV2 USES ABOVE CONVERSION TO SET POSTBYTE
* BIT SKELETON.
CONV2
        FDB     $1084,$1100     ; R,      H,R
        FDB     $1288,$1389     ; HH,R    HHHH,R
        FDB     $1486,$1585     ; A,R     B,R
        FDB     $168B,$1780     ; D,R     ,R+
        FDB     $1881,$1982     ; ,R++    ,-R
        FDB     $1A83,$828C     ; ,--R    HH,PCR
        FDB     $838D,$039F     ; HHHH,PCR [HHHH]
        FCB     0               ; END OF TABLE

****************************************************
*            DEFAULT INTERRUPT TRANSFERS           *
****************************************************
RSRVD   JMP     [VECTAB+_RSVD,PCR]      ; RESERVED VECTOR
SWI3    JMP     [VECTAB+_SWI3,PCR]      ; SWI3 VECTOR
SWI2    JMP     [VECTAB+_SWI2,PCR]      ; SWI2 VECTOR
FIRQ    JMP     [VECTAB+_FIRQ,PCR]      ; FIRQ VECTOR
IRQ     JMP     [VECTAB+_IRQ,PCR]       ; IRQ VECTOR
SWI     JMP     [VECTAB+_SWI,PCR]       ; SWI VECTOR
NMI     JMP     [VECTAB+_NMI,PCR]       ; NMI VECTOR

******************************************************
*            ASSIST09 HARDWARE VECTOR TABLE
* THIS TABLE IS USED IF THE ASSIST09 ROM ADDRESSES
* THE MC6809 HARDWARE VECTORS.
******************************************************
        ORG     ROMBEG+ROMSIZ-16 ; SETUP HARDWARE VECTORS
        FDB     RSRVD           ; RESERVED SLOT
        FDB     SWI3            ; SOFTWARE INTERRUPT 3
        FDB     SWI2            ; SOFTWARE INTERRUPT 2
        FDB     FIRQ            ; FAST INTERRUPT REQUEST
        FDB     IRQ             ; INTERRUPT REQUEST
        FDB     SWI             ; SOFTWARE INTERRUPT
        FDB     NMI             ; NON-MASKABLE INTERRUPT
        FDB     RESET           ; RESTART
