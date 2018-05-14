;reset.asm
;tests the reset vector
KBSCAN 	EQU $A1CB
RED_SQUARE EQU 191
BLUE_SQUARE EQU 175

	org $E00
start
	lda #RED_SQUARE
	sta $400
	lda #BLUE_SQUARE
	sta $420
@sp	JSR KBSCAN  ; PUTS KEYCODE INTO A - 0 = NO KEY
	CMPA #0
	BEQ @sp
	
	
	end start