;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;error beep
; x contains song addr
;registers are preserved
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
play_song
	pshs a,x,y
	lda ,x+ ; get num notes
	ldb ,x+ ; curnote
@lp	pshs a
	lda ,x+ ; freq
	ldy ,x++ ; time
	cmpa #0
	beq @ps
	sta delay_value
	jsr sound_play
	bra @c
@ps	jsr waste_time
@c	incb 
	puls a
	deca
	bne @lp
	puls a,x,y
	clr 1,x  ; set cur note back to 0
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; x contains song addr
;registers are preserved
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
play_note
	pshs d,x,y
	tfr x,y
	ldb 1,x  ; curnote
	cmpa ,x 
	bne @g
	lda #$FF
	sta 1,x
	clrb
@g	inc 1,x  ; update cur note
    leax 2,x ; skip 2 header bytes
	abx ; 3 * curNote to get offset
	abx 
	abx 
	lda ,x  ;freq
	cmpa #0
	beq @w
	sta delay_value
	ldy 1,x  ;time
	jsr sound_play	
@w	jsr waste_time
@x	puls d,x,y
	rts
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;error beep
;plays a short error tone
;registers are preserved
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
error_beep:	
	pshs a,y
	ldy	#20		;length (short)
	lda #10	;low a
	sta freq
	jsr sound_play2
	puls y,a
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;error beep
;plays a short error tone
;registers are preserved
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
play_footstep:	
	pshs a,y
	ldy	#2		;length (short)
	lda #120	;low a
	sta freq
	jsr sound_play2
	puls y,a
	rts	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;multiplies y times 6. used by sound_play2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ytimes6
	pshs d
	exg y,d  ; y->d
	std temp_word
	ldy #4
@lp addd temp_word 	
	leay -1,y
	cmpy #0
	bne @lp
	exg d,y ; d->y
	puls d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PLAYS A TONE WHOSE INFO IS STORED IN THE 
;SND DATA STRUCTURE
; Y CONTAINS THE NUMBER OF TIMES TO LOOP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sound_play
	pshs d,x,y
	;setup snd
	lda PIA_CTRL1
	anda #$f7		;reset mux bit (why?)
	sta PIA_CTRL1	; (sound to spkr?)
	lda PIA_CTRL2	
	anda #$f7
	sta PIA_CTRL2 ; (sound on?)
	lda PIA_SND_ENABLE
	ora #8			; get bit 6
	sta PIA_SND_ENABLE
	;main sound loop - the delay which 
	;controls the length of the sound
	;ldy snd_data	; load repeat count (now supplied by caller)
@o	ldx	snd_data+3	; load start addr
@i	lda ,x+			; get next byte
	anda #$fc		; reset 2 ls bits
	sta	PIA_DATA
	jsr snd_delay	; use delay to control freq
	cmpx snd_data+5	; test for end addr
	bne @i			; keep going
	leay -1,y		; dec main lp countr (sets z flag)
	bne @o			; start over at beginning of sound data
	puls d,x,y
	rts	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; plays a tone 
; freq location contains frequency
; sound_length contains the number of times to loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sound_play2
	;adjust the length based on freq
	lda sound_length
	sta dividend
	ldb freq
	stb divisor
	jsr div8
	sta quotient 
	;main sound loop - the delay which 
	ldy quotient_16
	jsr ytimes6
	;setup snd
	;lda #65
	;sta $400
	lda PIA_CTRL1
	anda #$f7		;reset mux bit (why?)
	sta PIA_CTRL1	; (sound to spkr?)
	;lda #66
	;sta $400
	lda PIA_CTRL2	
	anda #$f7
	sta PIA_CTRL2 	; (sound on?)
	;lda #67
	;sta $400
	lda PIA_SND_ENABLE
	ora #8			; get bit 6
	sta PIA_SND_ENABLE
	;lda #68
	;sta $400
	;main loop
	leay 1,y		;make sure y is not 0
@o	ldx	snd_data+3	; load start addr
@i	lda ,x+			; get next byte
	anda #$fc		; reset 2 ls bits
	sta	PIA_DATA
	jsr snd_delay	; use delay to control freq
	cmpx snd_data+5	; test for end addr
	bne @i			; keep going
	leay -1,y		; dec main lp countr (sets z flag)
	bne @o			; start over at beginning of sound data
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	WASTE TIME
;	AN EMPTY LOOP TO WASTE TIME. 
;	THIS ROUTINE WILL GET CALLED 4 TIMES
;	PER SINE WAVE CYCLE.
;
;	CYCLES: 14 + 11 TIME THROUGH THE LOOP
;	25 CYCLES = 35,600 HZ
;	
;	@440HZ EACH CYCLE NEEDS TO TAKE .0022 seconds
;	THAT MEANS 4 LOOPS OF .00056 SECS
;	TO MAKE EACH DELAY TAKE .00056 SECONDS
;	THE LOOP COUNT NEEDS TO BE 500 cycles long
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
snd_delay:
	pshs a
	lda delay_value
@lp	deca
	cmpa #0
	bne @lp
	puls a
	rts		
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sound data
; 0-1 	repeat count.  0 = 65535
; 2		delay count
; 3-4	start_addr
; 5-6	end_addr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
snd_data	
	.dw 0x10				;repeat count
	.db 0x0f				;delay
	;.dw snd_sine_start	
	;.dw snd_sine_end
	.dw snd_tabl	
	.dw snd_tabl+4		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;data for sine wave
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
snd_tabl
	.db 0xfe,0x02,0x7f,0x02		; data basic feeds to ff20 (sound)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; delay values shown on left will result in the following note
; note these are for the coco2 running at 0.89mhz coco3 values
; will be different because of the faster clock speed
; 60 = a#
; 64 = a (880 hz)
; 69 = g# (830 hz)
; 73 = g (783 hz)
; 78 = f# (749 hz)
; 83 = f (698 hz)
; 88 = e (659 hz)
; 94 = d# (622 hz)
; 100 = d (587 hz)
; 106 = c# (55 4hz)
; 110 = middle c (523 hz)
; 120 = b
; 127 = a#
; 135 = a (440hz)
;
; to get the outer loop time (the tone length), just use
; the frequency from the table above (will require 16 bits)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fill_freq .dw 0x0000	
freq .db 0x01	
sound_length .db 0x00
tone_length .dw 0x00ff
delay_value .db 128

win_music
	.db 9
	.db 0
	.db $70  ; C
	.dw 60	
	.db $52
	.dw 70
	.db $3f
	.dw 90
	.db $70
	.dw 60
	.db $52
	.dw 70
	.db $3F
	.dw 90
	.db $70
	.dw 60
	.db $52
	.dw 70
	.db $3F
	.dw 90
	
wumpus_music
	.db 16  ; num notes
	.db 0  ; curNote
	.db $ef ; f
	.dw 75
	.db 0  ; pause
	.dw 0
	.db $ef ;f
	.dw 50
	.db 0 ; pause
	.dw 0
	.db $ef ; f
	.dw 25
	.db 0 ; pause
	.dw 0
	.db $ef  ; f
	.dw 75
	.db $cd  ; g#
	.dw 50
	.db $d5  ; g
	.dw 25
	.db 0 ; pause
	.dw 0
	.db $d5  ; g
	.dw 50
	.db $ef  ;f
	.dw 25
	.db 0  ; pause
	.dw 0
	.db $ef ; f
	.dw 50
	.db $ff ;e 
	.dw 25
	.db $ef ;f 
	.dw 75

fall_music
	.db 17  ; num sounds
	.db 0 ; cursound
	.db 10
	.dw 80
	.db 10
	.dw 80
	.db 11
	.dw 80
	.db 11
	.dw 70
	.db 12
	.dw 50
	.db 13
	.dw 45
	.db 14
	.dw 50
	.db 15
	.dw 50
	.db 16
	.dw 50
	.db 17
	.dw 45
	.db 18
	.dw 40
	.db 19
	.dw 40
	.db 20
	.dw 40
	.db 21
	.dw 40
	.db 22
	.dw 40
	.db 23
	.dw 40
	.db 24
	.dw 40
	.db 25
	.dw 40
	.db 26
	.dw 40
	.db 27
	.dw 40
	
intro_music
	.db 26
	.db 0
	.db $86  ; A
	.dw 75  
	.db $77  ; B
	.dw 75  
	.db $70  ; C
	.dw 75  
	.db $64  ; D
	.dw 75  	
	.db $57  ; E
	.dw 75  		
	.db $70  ; C
	.dw 75  
	.db $57  ; E
	.dw 125  		
	.db $5E  ; e flat
	.dw 75
	.db $77  ; B
	.dw 75  
	.db $5e  ; e flat
	.dw 125
	.db $64  ; D
	.dw 75 
	.db $7E  ; B flat
	.dw 75 
	.db $64  ; D
	.dw 125 
	.db $86  ; A
	.dw 75  
	.db $77  ; B
	.dw 75  
	.db $70  ; C
	.dw 75  
	.db $64  ; D
	.dw 75  	
	.db $57  ; E
	.dw 75  		
	.db $70  ; C
	.dw 75
	.db $86  ; A
	.dw 75 
	.db $40  ; A high
	.dw 120  
	.db $48  ; G high
	.dw 100  		
	.db $57  ; E
	.dw 75  		
	.db $70  ; C
	.dw 70	
	.db $57  ; E
	.dw 75  
	.db $48  ; G high
	.dw 150  	