;,u = x ; in units of 4 pixels (one byte)
;1,u = y ; in pixels (height is 192 )
;2,u = w ; in units of 4 pixels (one byte)
;3,u = h ; in units of 4 pixels (one byte)
;4,u = fill color
fill_rect
	pshs d,x,y
	lda #0
	pshs a ; loop counter
	;compute v skip amount
	lda #32
	suba 2,u
	pshs a  ; push skip amount
	lda #32 ; row width in bytes
	ldb 1,u ; y
	mul
	tfr d,x
	leax VRAM,x
	ldb ,u  ; x
	abx
	lda #0 ; col counter 
@lp ;
	pshs a 
	lda 4,u ; fill square 
	sta ,x+
	puls a
	inca
	cmpa 2,u ; filled a row?
	bne @c
	;skip one row ()
	lda #0  ; reset x counter
	ldb ,s  ; skip amount
	abx  ; b is how many bytes to drop   
	dec 3,u ; dec row counter
	beq @x
@c	;
	bra @lp
@x	leas 2,s ; pop 2 params
	leau 5,u
	puls d,x,y
	rts

;copies a 16x16 tile to the 
;coords must be multiples of 4
;x contains the sprite addr
;y contains dest addr
;no screen bounds checking
draw_tile
	pshs d,x,y
 	lda #0
@ol	
	ldb #0  ; inner loop counter
@il	pshs a
	lda ,x+
	sta ,y
	puls a
	leay 1,y
	incb
	cmpb #4 ; sprites are 4 bytes wide
	bne @il 
	leay 28,y 	;drop down a line
	inca	
	cmpa #TILE_HEIGHT ;sprites are 16 rows tall
	bne @ol
	puls y,x,d
	rts

;this masks a tile on the vram
;if a src pixel is white, it is not drawn
;used for drawing the player, pit, and bat
mask_tile
	pshs d,x,y
	lda #0
@ol	
	pshs a  ; save loop counter
	ldb #0  ; inner loop counter
@il	lda ,x 	;get the byte to draw
	anda #$C0  ; 11000000 mask upper bits
;	cmpa #$C0  
	cmpa transparent
	beq @s1 ; it's white, skip it
	pshs a
	lda ,y  ; dest already drawn byte
	anda #3Fh  ;00111111 clear top bits
	ora ,s	 ;or bits onto dest
    sta ,y  ; write it back
	puls a  ; clear temp
@s1 lda ,x  ; reload sprite bite
	anda #$30  ; 00110000 mask upper bits
	;cmpa #$30  ; is it white?
	cmpa transparent+1
	beq @s2
	pshs a  
    lda ,y  ; dest already drawn byte
	anda #$CF  ;11001111 bits 4,5
	ora ,s	 ;or bits onto dest
    sta ,y  ; write it back
	puls a   ; clear temp 
@s2	lda ,x  ; reload sprite bite
	anda #12  ; 00001100 mask upper bits
	;cmpa #12  ; is it white?
	cmpa transparent+2
	beq @s3
	pshs a  
    lda ,y  ; dest already drawn byte
	anda #$F3  ;11110011 bits 2,3
	ora ,s	 ;or bits onto dest
    sta ,y  ; write it back
	puls a   ; clear temp 
@s3 lda ,x  ; reload sprite bite
	anda #3  ; 00000011 mask upper bits
	;cmpa #3  ; is it white?
	cmpa transparent+3
	beq @c
	pshs a  
	lda ,y  ; dest already drawn byte
	anda #$FC  ;11111100 bits 0,1
	ora ,s	 ;or bits onto dest
    sta ,y  ; write it back
	puls a   ; clear temp 
@c	leax 1,x
	leay 1,y
	incb
	cmpb #4 ; sprites are 4 bytes wide
	bne @il 
	leay 28,y 	;drop down a line
	puls a  ; restore loop counter
	inca	
	cmpa #TILE_HEIGHT ;sprites are 16 rows tall
	bne @ol
	puls y,x,d
	rts

;a=x,b=y
;a,b are in 'tiles' (not bytes or pixels)
;resulting offset is in y
;computes   
set_draw_offset
	pshs d,x
	asla ; a * 4
	asla
	pshs a
	ldy #0
@lp	cmpb #0
	beq @d
	leay 768,y ; each line of tiles is 768 bytes
	decb
	bra @lp
@d  puls b   ; pop a*4 (how to add to x?)
	tfr y,x
	abx	; add b to x
	leax VRAM,x
	tfr x,y
	puls d,x
	rts

	
; since that's how many bytes d,x,y pushes/pulls
; a = screen x in bytes (units of 4 pixels)
; b = screen y in pixels
; ,u = height (in pixels)
; 1,u = width (in bytes = units of 4 pixels)
; y = sprite src
draw_sprite
	pshs d,x,y
	pshs a ; save x offset
	lda #32
	mul
	tfr d,x
	puls b  ; add x to addr
	abx
	leax VRAM,x		
	lda #32 ; (vksip = -1 * (32 - w) )
	suba 1,u
	sta vskip
	;a is outer loop (rows)
	;b is inner loop (cols)
	clra
@ol 
	clrb
	pshs a
@il 
	lda ,y+
	sta ,x+
	incb
	cmpb  1,u ; end of row
	bne @il	
	ldb vskip
	abx
	clrb
	puls a ;restore outer loop counter
	inca
	cmpa ,u  ; copied all rows?
	bne @ol
	bra @x
@x	leau 2,u  ; pop h,w params
	puls d,x,y
	rts	