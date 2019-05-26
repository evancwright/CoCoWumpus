;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;next_rand
;this subroutine uses a linear shift
;to implement random number generation
;the taps are bits 0 and 3
;
;the seed (cur_rand) should be loaded before 
;this routine is called.  just don't load
;it with all zeros to start 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;user stack contains divisor (16 bit)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
randmod
	pshs d,x,y
	jsr rand	; puts number on stack	
	jsr mod2b   ; leaves number on stack
	puls y,x,d
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;lsr random number generator
;all registers are preserved
;number is returned on the user stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rand
	pshs d,x
	ldb cur_rand+1 ; get right byte
	andb left_tap_mask ; mask rand to get left tap	
	stb left_tap			;save it
	ldb cur_rand+1		;reload
	andb right_tap_mask	; mask rand to get right tap
	;right tap is the lsb (so we don't need to shift)
	stb right_tap
	lsl right_tap	;left justify the right tap 
	lsl right_tap	;so the two taps can be 
	lsl right_tap	;xor'd and easily
	lsl right_tap	;masked back onto the left
	lsl right_tap	;byte of the random number
	lsl right_tap
	lsl right_tap
	;now we have both taps, xor them
	lda left_tap
	eora right_tap	
	sta xor_rslt
	;now shift
	ldd cur_rand	;load left byte
	lsra ; puts bit 0 into carry bit 
	sta cur_rand ; store new msb
	bcc @nc
	ldb	cur_rand+1	;there was a carry
	lsrb
	orb one_in_msb ;  mask a 1 onto the left most bit
	bra @ds	 ;  done shifting
@nc	
	ldb	cur_rand+1 ; just shift, no 1 on left
	lsrb
@ds stb cur_rand+1 	; store right half of new rand
	;now mask the xor_rslt onto the msb
	lda cur_rand
	ora xor_rslt	; mask a '1' onto the msb
	sta cur_rand
	;subtract 1 since the working rand can't contain 0
	ldd cur_rand	; reload 2 byte value
	subd #1		; dec
	std cur_rand			
        ldx cur_rand 
	pshu x
	puls x,d
	rts	

