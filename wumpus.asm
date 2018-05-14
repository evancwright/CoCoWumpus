;cocowumpus
;SAM VIDEO PAGE PAGE
SAM_V0_CLR EQU $FFC0
SAM_V0_SET EQU $FFC1
SAM_V1_CLR EQU $FFC2
SAM_V1_SET EQU $FFC3
SAM_V2_CLR EQU $FFC4
SAM_V2_SET EQU $FFC5

;SAM PAGE SELECT
;ffc6/ffc7   SAM Display Offset bit F0 
;ffc8/ffc9   SAM Display Offset bit F1 
;ffca/ffcb   SAM Display Offset bit F2 
;ffcc/ffcd   SAM Display Offset bit F3 
;ffce/ffcf   SAM Display Offset bit F4 
;ffd0/ffc1   SAM Display Offset bit F5 
;ffd2/ffc3   SAM Display Offset bit F6 
SAM_PG_F0_CLR EQU $FFC6
SAM_PG_F0_SET EQU $FFC7
SAM_PG_F1_CLR EQU $FFC8
SAM_PG_F1_SET EQU $FFC9
SAM_PG_F2_CLR EQU $FFCA
SAM_PG_F2_SET EQU $FFCB
SAM_PG_F3_CLR EQU $FFCC
SAM_PG_F3_SET EQU $FFCD
SAM_PG_F4_CLR EQU $FFCE
SAM_PG_F4_SET EQU $FFCF
SAM_PG_F5_CLR EQU $FFD0
SAM_PG_F5_SET EQU $FFD1
SAM_PG_F6_CLR EQU $FFD2
SAM_PG_F6_SET EQU $FFD3

VDG_CONTROL EQU $FF22

GM_0 EQU  16
GM_1 EQU  32
GM_2 EQU  64

VRAM EQU $E00
	;ORG 0xE00 ; START CODE HERE  (WHEN IT'S A BIN DISK FILE )
	ORG 0x1A00 ; START CODE HERE  (WHEN IT'S A BIN DISK FILE )
START

main
	sts sstack_sav
	stu ustack_sav
reset
	lds sstack_sav
	ldu ustack_sav
	nop  ; 
	jsr setup_sam
	lda color
	jsr cls
@lp	ldd 0
	ldx #sprite_data	
	jsr draw_tile
	bra @lp
	rts
	
;clears screen with color in A	
cls
	ldy #0
@lp	sta VRAM,y
	leay 1,y
	cmpy #3072 ; end of VRAM
	bne @lp	
	rts
	
;pmode 1
setup_sam
	; Full graphic 3-C  11001100 128x96x4   $C00(3072	
	lda #1 
	;set SAM mode
	sta SAM_V0_CLR
	sta SAM_V1_CLR
	sta SAM_V2_SET 
	;set page page (7)
	sta SAM_PG_F0_SET
	sta SAM_PG_F1_SET
	sta SAM_PG_F2_SET
	sta SAM_PG_F3_CLR
	sta SAM_PG_F4_CLR
	sta SAM_PG_F5_CLR
	sta SAM_PG_F6_CLR
	lda VDG_CONTROL
	;clear GM0 and GM1
	ANDA #0CFh  ; clear bits
	;set GM2
	ORA #GM_2
	;set bit 7 of VDG control to 1 for graphics
	ORA #80h
	sta VDG_CONTROL 
	rts

	
;copies a 16x16 tile to the 
;cordinate in a,b
;coords must be multiples of 4
;x contains the sprite addr
;no screen bounds checking
draw_tile
	pshs d,x,y
	mul	;won't work
	tfr d,y
	lda #0
@ol	
	ldb #0  ; inner loop counter
@il	pshs a
	lda ,x+
	sta VRAM,y
	puls a
	leay 1,y
	incb
	cmpb #4 ; sprites are 4 bytes wide
	bne @il 
	leay 28,y 	;drop down a line
	inca	
	cmpa #16 ;sprites are 16 rows tall
	bne @ol
	puls y,x,d
	rts

include random.asm
	
sprite_data
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,81,65,87
	.db 21,64,21,87
	.db 21,64,21,87
	.db 21,81,65,87
	.db 21,17,69,87
	.db 21,64,21,87
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,85,85,87
	.db 21,85,85,87

color .db $E4 ; 11100100	
sstack_save .dw 0
ustack_save .dw 0	
	END START

	; Full graphic 3-C  11001100 128x96x4   $C00(3072