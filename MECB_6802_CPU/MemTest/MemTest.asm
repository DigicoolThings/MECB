; MemTest (based on Emil's MemTest)
;
; Amended & simplified for DigiBug routine addresses and ASL Assembler
; Also added additional 1's complement value test (so all bits tested!)
; Intended for running in RAM (from a low address - e.g. $0100)
;
        CPU     6800        ; Specify MC6800 processor code (asl Assembler)
;
; DigiBug Monitor Routine Addresses
;
        include DigiBug.inc
;
BELL    EQU     $07
EOT     EQU     $04
;
MEMEND  EQU     $DEFF       ; Usable Memory End. Excludes DigiBug DF00 work page.
;
        ORG     $0100       ; Program start address
;
        LDS     #*-1        ; Reset stack (Program start -1)
        BRA     MEMTST
;
WRKSPC  RMB     2           ; Workspace + Seed for random function
;
; Memory Test
;
MEMTST  LDX     #STRBEG     ; Output Intro Message
        JSR     OUTSTR
;
        LDX     #STRFIL     ; Ouput Filling memory message
        JSR     OUTSTR
        JSR     MFILL       ; Fill the test memory range
;
        LDX     #STRVER     ; Output Verifying memory message
        JSR     OUTSTR
        JSR     MVER        ; Verify test memory range stores expected values
;
        JMP     CONTRL      ; We're done! Outa here.
;
; MFILL - Fill memory from MEMSTR to MEMEND with random values
;
MFILL   CLR     WRKSPC      ; Reset random seed
        CLR     WRKSPC+1
        LDX     #MEMSTR
        DEX                 ; Preset X to 1 byte below Start
        CLRB
MFILL1  JSR     RANDOM
        INX                 ; First increment test address
        STAA    0,X
        INCB
        BNE     MFILL2
        LDAA    #'.'        ; Every 256 bytes write a '.'
        JSR     OUTCH
MFILL2  CMPX    #MEMEND     ; Have we completed the MEMEND address?
        BNE     MFILL1
        RTS
;
; MVER - Verify memory from MEMSTR to MEMEND against random values
;        also verify 1's complement value storage (so all bits tested!)
;
MVER    CLR     WRKSPC      ; Reset random seed
        CLR     WRKSPC+1
        LDX     #MEMSTR
        DEX                 ; Preset X to 1 byte below Start
        CLRB
MVER1   JSR     RANDOM
        INX                 ; First increment test address
        CMPA    0,X         ; Verify psuedo random value
        BNE     MVERER      ; Match Error?
        COMA                ; Now do the 1's complement test
        STAA    0,X         ; Store inverted value
        CMPA    0,X         ; Verify inverted psuedo random value
        BNE     MVERER      ; Match Error?
        INCB
        BNE     MVER2
        LDAA    #'.'        ; Every 256 bytes output a '.'
        JSR     OUTCH
MVER2   CMPX    #MEMEND     ; Have we completed the MEMEND address?
        BNE     MVER1
        STX     WRKSPC
        LDX     #STROK      ; All memory verified OK!
        BRA     CMPMSG
;
MVERER  STX     WRKSPC
        LDX     #STRERR
CMPMSG  JSR     OUTSTR      ; Output completion message.
        LDX     #WRKSPC
        JSR     OUT4HS
        JSR     OCRLF
        RTS
;
; Strings for output
;
STRBEG  FCC     "\r\nMECB 6802 CPU Card Memory Check\r\n"
        FCB     EOT
STRFIL  FCC     "Filling memory with random data:\r\n"
        FCB     EOT
STRVER  FCC     "\r\nVerifying memory:\r\n"
        FCB     EOT
STROK   FCC     "\r\nMemory Check Successful! Top of Usable Memory $"
        FCB     EOT
STRERR  FCC     "\r\nMemory Check Failed! Error at $"
        FCB     BELL,EOT
;
; Emil's Random function (mostly unchanged)
;
RANDOM	PSHB                ; RANDOM NUMBER GENERATOR - SAVE B
        LDAA    WRKSPC+1    ; COMPUTE (WRKSPC * 2 * * 9) MOD 2 ** 16
        CLC
        ROLA
        CLC
        ROLA
        ADDA    WRKSPC      ; ADD WRKSPC TO RESULT
        LDAB    WRKSPC+1
        CLC                 ; MULTIPLY BY 2 ** 2
        ROLB
        ROLA
        CLC
        ROLB
        ROLA
        CLC
        ADDB    WRKSPC+1    ; ADD WRKSPC TO RESULT
        ADCA    WRKSPC
        CLC
        ADDB    #$19        ; ADD HEXADECIMAL 3619 TO THE RESULT
        ADDA    #$36
        STAA    WRKSPC      ; STORE RESULT IN WRKSPC
        STAB    WRKSPC+1
        PULB                ; RESTORE B
        RTS
;
MEMSTR  EQU     *           ; End of Program. Mark for Memory Test Start address
;
        END