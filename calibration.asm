;calibration
;include this file directly (inline)
;it is not a subroutine
	
	ldx $72
	stx rv_save
	
	ldx #reset ; overwrite warm reset vector
	stx $72
	
	lda #WHITE_FILL
	jsr cls
	lda #4
	ldb #4
	jsr set_draw_offset
	ldx #color_calibration
	jsr draw_tile
	
@lp2
	jsr KBSCAN
	cmpa #0
	beq @lp2

	;replace original warm start vector
	ldx rv_save
	stx $72
	
