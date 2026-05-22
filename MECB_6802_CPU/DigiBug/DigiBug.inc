;
; DigiBug standard routine definitions
;
START   EQU     $E100       ; Cold start / reset - monitor entry point
CONTRL  EQU     $E103       ; Warm start - monitor entry point
OQSTNE  EQU     $E106       ; Ouput Question Mark "?" and Exit to CONTRL
INADDR  EQU     $E109       ; Input 4 digit Hex Address (to X & ADDRHI/LO)
INBYTE  EQU     $E10C       ; Input 2 digit Hex Byte (to A)
OUTCH   EQU     $E10F       ; Output character (redirect to OUTEEE)
INCH    EQU     $E112       ; Input character (Redirect to INEEE)
OUTSTR  EQU     $E115       ; Output EOT terminated string at X
OUT2H   EQU     $E118       ; Output 2 Hex digits of byte at X (X = X+1)
OUT4HS  EQU     $E11B       ; Output 4 Hex digits and space of 2 bytes at X (X = X+2)
OUT2HS  EQU     $E11E       ; Output 2 Hex digits and space of byte at X (X = X+2)
OCRLF   EQU     $E121       ; Output Carriage Return / Line Feed
;