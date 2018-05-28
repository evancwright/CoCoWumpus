;calibration
;include this file directly (inline)
;it is not a subroutine
	
	ldx $72
	stx rv_save
	
	ldx #reset ; overwrite warm reset vector
	stx $72
	
	lda #WHITE_FILL
	jsr cls
	; draw prompt
	lda #12 ;width
	pshu a
	lda #22 ;height
	pshu a
	lda #10 ;x
	ldb #50 ;y
	ldy #press_reset
	jsr draw_sprite
	;draw colored squares
;	lda #4
;	ldb #4
;	jsr set_draw_offset
;	ldx #color_calibration
;	jsr draw_tile
	lda #3
	ldb #4
	jsr set_draw_offset
	ldx #sprite_wumpus_left
	jsr draw_tile
	lda #4
	ldb #4
	jsr set_draw_offset
	ldx #sprite_wumpus_right
	jsr draw_tile
	;press any key
	lda #12
	pshu a
	lda #6
	pshu a
	lda #10
	ldb #140
	ldy #press_a_key
	jsr draw_sprite
	;if correct
	lda #9
	pshu a
	lda #6
	pshu a
	lda #12
	ldb #150
	ldy #if_correct
	jsr draw_sprite
@lp2
	jsr KBSCAN
	cmpa #0
	beq @lp2

	;replace original warm start vector
	ldx rv_save
	stx $72
	
