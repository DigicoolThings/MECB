;
SoundByteTable	; Table of Sound Byte Indexes into the Frequency Table for each of the 3 SN76489 Tone Generators
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
	
		FCB 0, 12+7, 12+4	;Ru-
		FCB 255, 12+9, 12+4	;dolph,
		FCB 7, 255, 255
		FCB 255, 12+7, 12+4	;the
		FCB 4, 12+4, 12		;red-
		FCB 255, 255, 255
		FCB 7, 12+12, 12+4	;nosed
		FCB 255, 255, 255

		FCB 0, 12+9, 12+4	;rain-
		FCB 255, 255, 255
		FCB 7, 12+7, 12+4	;deer
		FCB 255, 255, 255
		FCB 4, 255, 255
		FCB 255, 255, 255
		FCB 7, 255, 255
		FCB 255, 255, 255

		FCB 0, 12+7, 12+4	;had
		FCB 255, 12+9, 12+5	;a
		FCB 7, 12+7, 12+4	;ve-
		FCB 255, 12+9, 12+5	;ry
		FCB 4, 12+7, 12+4	;shi-
		FCB 255, 255, 255
		FCB 3, 12+12, 12+9	;ny
		FCB 255, 255, 255

		FCB 2, 12+7, 12+11	;nose
		FCB 255, 255, 255
		FCB 7, 255, 255
		FCB 255, 255, 255
		FCB 5, 255, 255
		FCB 255, 255, 255
		FCB 2, 255, 255
		FCB 255, 255, 255

		FCB 7, 12+5, 12+2	;and 
		FCB 255, 12+7, 12+2	;if
		FCB 11, 255, 255
		FCB 255, 12+5, 12+2	;you
		FCB 2, 12+2, 12-1	;e-
		FCB 255, 255, 255
		FCB 5, 12+11, 12+7	;ver
		FCB 255, 255, 255

		FCB 7, 12+9, 12+2	;saw
		FCB 255, 255, 255
		FCB 11, 12+7, 12+2	;it,
		FCB 255, 255, 255
		FCB 2, 255, 255
		FCB 255, 255, 255
		FCB 5, 255, 255
		FCB 255, 255, 255

		FCB 7, 12+7, 12+5	;you
		FCB 255, 12+9, 12+5	;would
		FCB 5, 12+7, 12+5	;e-
		FCB 255, 12+9, 12+5	;ven
		FCB 4, 12+7, 12+5	;say
		FCB 255, 255, 255
		FCB 2, 12+9, 12+5	;it
		FCB 255, 255, 255

		FCB 0, 12+4, 12		;glo-
		FCB 255, 255, 255
		FCB 11, 12+7, 12+4	;ws.
		FCB 11, 255, 255
		FCB 9, 255, 255
		FCB 9, 255, 255
		FCB 7, 255, 255
		FCB 7, 255, 255


		FCB 0, 12+7, 12+4	;All
		FCB 255, 12+9, 12+4	;of
		FCB 7, 255, 255
		FCB 255, 12+7, 12+4	;the
		FCB 4, 12+4, 12		;ot-
		FCB 255, 255, 255
		FCB 7, 12+12, 12+4	;her
		FCB 255, 255, 255

		FCB 0, 12+9, 12+4	;rain-
		FCB 255, 255, 255
		FCB 7, 12+7, 12+4	;deer
		FCB 255, 255, 255
		FCB 4, 12+12+9, 12+12+4
		FCB 255, 255, 255
		FCB 7, 12+12+7, 12+12+4
		FCB 255, 255, 255

		FCB 0, 12+7, 12+4	;used
		FCB 255, 12+9, 12+5	;to
		FCB 7, 12+7, 12+4	;laugh
		FCB 255, 12+9, 12+5	;and
		FCB 4, 12+7, 12+4	;call
		FCB 255, 255, 255 
		FCB 3, 12+12, 12+9	;him
		FCB 255, 255, 255

		FCB 2, 12+11, 12+2	;names
		FCB 255, 255, 255
		FCB 7, 255, 12+2
		FCB 255, 255, 12+4
		FCB 5, 255, 12+5
		FCB 255, 255, 255
		FCB 2, 255, 255
		FCB 255, 255, 255

		FCB 7, 12+5, 12+2	;they
		FCB 255, 12+7, 12+2	;ne-
		FCB 11, 255, 255
		FCB 255, 12+5, 12+2	;ver
		FCB 2, 12+2, 12-1	;let
		FCB 255, 255, 255
		FCB 5, 12+11, 12+7	;poor
		FCB 255, 255, 255

		FCB 7, 12+9, 12+4	;Ru-
		FCB 255, 255, 255
		FCB 11, 12+7, 12+2	;dolph
		FCB 255, 255, 255
		FCB 2, 12+12+9, 12+12+5
		FCB 255, 255, 255
		FCB 5, 12+12+7, 12+12+2
		FCB 255, 255, 255

		FCB 7, 12+7, 12+5	;join
		FCB 255, 12+9, 12+5	;in
		FCB 5, 12+7, 12+5	;a-
		FCB 255, 12+9, 12+5	;ny
		FCB 4, 12+7, 12+5	;rain
		FCB 255, 255, 255
		FCB 2, 12+12+2, 12+7	;deer
		FCB 255, 255, 255

		FCB 0, 12+12, 12+4	;games
		FCB 12, 255, 12+4
		FCB 10, 255, 12+2
		FCB 255, 255, 255
		FCB 9, 255, 12
		FCB 255, 255, 255
		FCB 7, 255, 10
		FCB 255, 255, 255


		FCB 5, 12+9, 12+5	;Then
		FCB 255, 255, 255
		FCB 9, 12+9, 12+5	;one
		FCB 255, 255, 255
		FCB 0, 12+12, 12+9	;fog-
		FCB 255, 255, 255
		FCB 9, 12+12, 12+9	;gy
		FCB 255, 255, 255

		FCB 0, 12+7, 12+4	;Christ-
		FCB 255, 255, 255
		FCB 7, 12+4, 12+0	;mas
		FCB 255, 255, 255
		FCB 4, 12+7, 12+4	;eve,
		FCB 255, 255, 255
		FCB 3, 255, 255
		FCB 255, 255, 255

		FCB 2, 12+5, 12+2	;San-
		FCB 255, 255, 255
		FCB 7, 12+9, 12+5	;ta
		FCB 255, 255, 255
		FCB 5, 12+7, 12+4	;came
		FCB 255, 255, 255
		FCB 7, 12+5, 12+2	;to
		FCB 255, 255, 255

		FCB 0, 12+4, 12		;say
		FCB 255, 255, 255
		FCB 12, 255, 12+4
		FCB 12, 255, 12+4
		FCB 11, 255, 12+2
		FCB 11, 255, 12+2
		FCB 9, 255, 12
		FCB 9, 255, 12

		FCB 2, 12+2, 11		;Ru-
		FCB 255, 255, 255
		FCB 11, 12+2, 11	;dolph
		FCB 255, 255, 255
		FCB 2, 12+7, 12+2	;with
		FCB 255, 255, 255
		FCB 6, 12+9, 12+6	;your
		FCB 255, 255, 255

		FCB 7, 12+11, 12+7	;nose
		FCB 255, 255, 255
		FCB 2, 12+11, 12+7	;so 
		FCB 255, 255, 255
		FCB 7, 12+11, 12+7	;bright,
		FCB 255, 255, 255
		FCB 8, 255, 255
		FCB 255, 255, 255

		FCB 9, 12+12, 12+9	;won't
		FCB 255, 255, 255
		FCB 9, 12+12, 12+9	;you
		FCB 255, 255, 255
		FCB 2, 12+11, 12+6	;guide
		FCB 255, 255, 255
		FCB 2, 12+9, 12+6	;my
		FCB 255, 255, 255

		FCB 7, 12+7, 12+2	;sleigh
		FCB 7, 255, 255
		FCB 5, 12+5, 12+2	;to-
		FCB 255, 255, 255
		FCB 4, 12+2, 11		;night?
		FCB 255, 255, 255
		FCB 2, 255, 255
		FCB 255, 255, 255

		FCB 0, 12+7, 12+4	;Then
		FCB 255, 12+9, 12+4	;how
		FCB 7, 255, 255
		FCB 255, 12+7, 12+4	;the
		FCB 4, 12+4, 12		;child-
		FCB 255, 255, 255
		FCB 7, 12+12, 12+4	;ren
		FCB 255, 255, 255

		FCB 0, 12+9, 12+4	;loved
		FCB 255, 255, 255
		FCB 7, 12+7, 12+4	;him
		FCB 255, 255, 255
		FCB 4, 12+12+9, 12+12+4
		FCB 255, 255, 255
		FCB 7, 12+12+7, 12+12+4
		FCB 255, 255, 255

		FCB 0, 12+7, 12+4	;as
		FCB 255, 12+9, 12+5	;they
		FCB 7, 12+7, 12+4	;shou-
		FCB 255, 12+9, 12+5	;ted
		FCB 4, 12+7, 12+4	;out
		FCB 255, 255, 255
		FCB 3, 12+12, 12+9	;with
		FCB 255, 255, 255

		FCB 2, 12+11, 12+2	;glee
		FCB 255, 255, 255
		FCB 7, 12+11, 12+2
		FCB 255, 12+12, 12+4
		FCB 5, 12+14, 12+5
		FCB 255, 255, 255
		FCB 2, 255, 255
		FCB 255, 255, 255

		FCB 7, 12+5, 12+2	;Ru-
		FCB 255, 12+7, 12+2	;dolph,
		FCB 11, 255, 255
		FCB 255, 12+5, 12+2	;the
		FCB 2, 12+2, 12-1	;red-
		FCB 255, 255, 255
		FCB 5, 12+11, 12+7	;nosed
		FCB 255, 255, 255

		FCB 7, 12+9, 12+4	;rain-
		FCB 255, 255, 255
		FCB 11, 12+7, 12+2	;deer,
		FCB 255, 255, 255
		FCB 2, 12+12+9, 12+12+5
		FCB 255, 255, 255
		FCB 5, 12+12+7, 12+12+2
		FCB 255, 255, 255

		FCB 7, 12+7, 12+5	;you'll
		FCB 255, 12+9, 12+5	;go
		FCB 5, 12+7, 12+5	;down
		FCB 255, 12+9, 12+5	;in
		FCB 4, 12+7, 12+5	;his-
		FCB 255, 255, 255
		FCB 2, 12+12+2, 12+7	;to-
		FCB 255, 255, 255

		FCB 0, 12+12, 12+4	;ry.
		FCB 12, 255, 12+4
		FCB 7, 12+12+7, 12+12+2
		FCB 255, 255, 255
		FCB 12, 12+12+7, 12+12+4
		FCB 7, 255, 255
		FCB 4, 255, 255
		FCB 2, 255, 255

		FCB 254			; The End
;