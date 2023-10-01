;
FrequencyTable	; Table of 16 bit Frequency words for each Note.  nb. Values stored Big Endian.
		; Following are Kurt Woloch's original notes:
		; Here we'll store the frequency for each possible note. I've prepared the data so it doesn't need to be shifted anymore.
		; Actually, the order of the bytes is reversed since the "word" directive got used. Basically, the first byte given
		; (for instance the $3F out of $3F0F) contains the highest 6 bits in bits 0-5, and and 2nd byte contains the low 4 bits in bits 0-3.
		; That's the bit locations required by the sound chip.
		; The sound generator is clocked at 2 MHz, which means that the lowest achievable frequency should be 2000000/1023/32 = 61,09 Hz.
		; The note scale I used starts at this frequency and goes up by one half-tone each step. Actually, this isn't properly "tuned"... the
		; frequency of 61,09 HZ ist about 18 cents unter a "B". See more on that below in the note table.
		; Note: it's possible to get even lower frequencies by setting channel 3 to output "periodic noise" at the frequency of channel 2,
		; which actually makes it output a square wave with a 1/15 duty cycle at a frequency that's 1/15 of the "normal" channel 2 frequency,
		; which is a bit under 4 octaves lower. However, I don't use this trick here, but I did use it in a TI-99 game to give a "punchy" bass line.

		FDB $3F0F	; lowest note = C0; 00 111111 0000 1111 = 1023
		FDB $3C06	; C#0; 00 111100 0000 0110 = 966
		FDB $380F	; D0;	00 111000 0000 1111 = 911
		FDB $350C	; D#0; 00 110101 0000 1100 = 860
		FDB $320C	; E0; 00 110010 0000 1100 = 812
		FDB $2F0E	; F0; 00 101111 0000 1110 = 766
		FDB $2D03	; F#0;00 101101 0000 0011 = 723
		FDB $2A8B	; G0;00 101010 0000 1011= 683
		FDB $2804	; G#0;00 101000 0000 0100 = 644
		FDB $2600	; A0;00 100110 0000 0000 = 608
		FDB $230E	; A#0;00 100011 0000 1110 = 574
		FDB $210E	; H0;00 100001 0000 1110 = 542
		FDB $2000	; C1;00 100000 0000 0000 = 512
		FDB $1E03	; C#1;00 011110 0000 0011 = 483
		FDB $1C07	; D1;00 011100 0000 0111 = 455
		FDB $1A0E	; D#1;00 011010 0000 1110 = 430
		FDB $1906	; E1;00 011001 0000 0110 = 406
		FDB $170F	; F1;00 010111 0000 1111 = 383
		FDB $160A	; G1;00 010110 0000 1010 = 362
		FDB $1505	; F#1;00 010101 0000 0101 = 341
		FDB $1402	; G#1;00 010100 0000 0010 = 322
		FDB $1300	; A1;00 010011 0000 0000 = 304
		FDB $110F	; A#1;00 010001 0000 1111 = 287
		FDB $100F	; H1;00 010000 0000 1111 = 271
		FDB $1000	; C2; = 256
		FDB $0F01	; C#2 = 241
		FDB $0E04	; D2  = 228
		FDB $0D07	; D#2  = 215
		FDB $0C0B	; E2  = 203
		FDB $0C00	; F2  = 192
		FDB $0B05	; F#2  = 181
		FDB $0A0B	; G2  = 171
		FDB $0A01	; G#2  = 161
		FDB $0908	; A2  = 152
		FDB $0900	; A#2  = 144
		FDB $0807	; H2 = 135
;