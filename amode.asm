;cocowumpus

;ROM ROUTINES
KBSCAN 	EQU $A1CB

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


	include snddefs.asm
	
GM_0 EQU  16
GM_1 EQU  32
GM_2 EQU  64
COLOR_BIT EQU 8
WIDTH EQU 16
TILE_BYTE_WIDTH EQU 4
TILE_HEIGHT EQU 24
ROW_SKIP EQU ((TILE_HEIGHT*32)-32) ; 480
NUM_TILES EQU 64 ; 12 x 8 = 
MAX_ROOMS EQU 80
VISITED EQU 1
WUMPUS EQU 2
PIT EQU 4
DRAFT EQU 8
SLIME EQU 16
BAT EQU 32
MARKED EQU 64 ; used for marking draft/slime
BAT_SEEN EQU 128

CLR_MARK EQU $BF ; 1011 1111
CLR_SLIME EQU $EF
CLR_BAT EQU $DF
CLR_BAT_SEEN EQU $7F
DRAW_X EQU 0
DRAW_Y EQU 1
UP EQU 2
DOWN EQU 3
LEFT EQU 4
RIGHT EQU 5

EASY EQU 0
MEDIUM EQU 1
HARD EQU 2

BLACK EQU 0
BLUE EQU 1
ORANGE EQU 2
ORANGE_FILL EQU $AA
BLACK_FILL EQU $00
BLUE_FILL EQU $55
WHITE_FILL EQU $FF
WHITE EQU 3

ROOM EQU 0
TUNNEL_1 EQU 1
TUNNEL_2 EQU 2
TUNNEL_3 EQU 3
TUNNEL_4 EQU 4 ; right side of /

ROOM_SIZE EQU 8 ; table entry size

ROOM_TYPE_OFFSET EQU 6 
ROOM_FLAGS_OFFSET EQU 7
 
DIGIT_HEIGHT EQU 14
DIGIT_WIDTH EQU 2 
DIGIT_SIZE EQU 28
PLAYER_SCORE_X EQU 8 
PIT_SCORE_X EQU 16
WUMPUS_SCORE_X EQU 26
SCORE_Y EQU 80
 
VRAM EQU $E00
	;ORG 0xE00 ; START CODE HERE  (WHEN IT'S A BIN DISK FILE )
	;ORG 0x1A00 ; START CODE HERE  (WHEN IT'S A BIN DISK FILE )
	ORG 0x2600
START

main
	lda #BLACK_FILL
	jsr cls
	
	;save stacks
	sts sstack_save
	stu ustack_save

reset	
	nop ; BASIC LOOKS FOR THIS
	;restore stacks
	lds sstack_save
	ldu ustack_save
	
	jsr setup_sam
	include calibration.asm
	
	jsr draw_title
	jsr animate_bat
	jsr animate_fall
	jsr get_skill_level
	jsr reset_game
	lda #BLACK_FILL
	jsr cls
@lp
	jsr draw_board
	jsr draw_player
@k	jsr KBSCAN
	cmpa #0
	beq @k
	cmpa #'A'
	beq @m
	cmpa #'S'
	beq @m
	cmpa #'W'
	beq @m
	cmpa #'D'
	beq @m
	cmpa #'Q'
	beq @s
	bra @k
@s ;put player in 'shooting state'
   lda #1
   sta shooting
   bra @x
@m	
	jsr key_to_offset
	pshs a ; save offset
	sta move_dir
	lda player_room
	jsr set_room_ptr
	puls b ; restore dir offset
	abx
	lda ,x ; load direction
	cmpa #$FF ; invalid dir
	beq @er
	ldb shooting
	cmpb #0
	beq @mv	
	jsr shoot_arrow
	bra @x
@mv	jsr move_player
	bra @x
@er	jsr error_beep
@x	bra @lp
	rts
	
;clears screen with color in A	
cls
	ldy #0
@lp	sta VRAM,y
	leay 1,y
	cmpy #6144 ; end of VRAM
	bne @lp	
	rts
	
;pmode 1
setup_sam
	; Full graphic 3-C  11001100 128x96x4   $C00(3072	
	lda #1 
	;set SAM mode
	sta SAM_V0_CLR
	sta SAM_V1_SET
	sta SAM_V2_SET 
	;set page page (7)
	sta SAM_PG_F0_SET
	sta SAM_PG_F1_SET
	sta SAM_PG_F2_SET
	sta SAM_PG_F3_CLR
	sta SAM_PG_F4_CLR
	sta SAM_PG_F5_CLR
	sta SAM_PG_F6_CLR
	lda #$FC
	sta VDG_CONTROL 
	rts

draw_title
	lda #BLUE_FILL
	jsr cls
	lda #WHITE_FILL
	pshu a
	lda #172 ; height
	pshu a
	lda #28 ; width
	pshu a
	lda #8 ;y 
	pshu a
	lda #2  ; x
	pshu a
	jsr fill_rect
	;
	ldy #(VRAM+(768*3)+4)
	ldx #sprite_wumpus_left	
	jsr draw_tile
	;
	leay 4,y
	ldx #sprite_wumpus_right	
	jsr draw_tile
	;
	ldy #(VRAM+(768*4)+4)
	ldx #title_w
	jsr draw_tile	
	leay 4,y
	ldx #title_u	
	jsr draw_tile
	leay 4,y
	ldx #title_m	
	jsr draw_tile
	leay 4,y
	ldx #title_p	
	jsr draw_tile
	leay 4,y
	ldx #title_u2	
	jsr draw_tile
	leay 4,y
	ldx #title_s	
	jsr draw_tile	
	ldx #intro_music
	jsr play_song
	; draw press any key
	ldy #(VRAM+(768*5)+14)
	ldx #press_a_key
	jsr draw_tile
	jsr any_key
	rts

;draws the tallies
draw_score_screen
	lda #BLUE_FILL
	jsr cls
	lda #WHITE_FILL
	;white rect
	pshu a
	lda #172 ; height
	pshu a
	lda #28 ; width
	pshu a
	lda #8 ;y 
	pshu a
	lda #2  ; x
	pshu a
	jsr fill_rect
	;draw pit
	lda #4 ; width
	pshu a
	lda #24 ; height
	pshu a
	lda #PIT_SCORE_X-3  ; x,y
	ldb #50 ; 
	ldy #sprite_pit
	jsr draw_sprite	
	;draw wumpus
	lda #4 ; width
	pshu a
	lda #24 ; height
	pshu a
	lda #WUMPUS_SCORE_X-3  ; x,y
	ldb #50 ; 
	ldy #tile_wumpus
	jsr draw_sprite
	;draw player
	lda #4 ; width
	pshu a
	lda #24 ; height
	pshu a
	lda #PLAYER_SCORE_X-3  ; x,y
	ldb #50 ; 
	ldy #player_icon
	jsr draw_sprite
	;draw scores
	lda #PLAYER_SCORE_X
	ldb #SCORE_Y
	ldx #player_score
	jsr draw_score
	;
	lda #PIT_SCORE_X
	ldb #SCORE_Y
	ldx #pit_score
	jsr draw_score
	;
	lda #WUMPUS_SCORE_X
	ldb #SCORE_Y
	ldx #wump_score
	jsr draw_score
	; draw press any key
	ldy #(VRAM+(768*5)+13)
	ldx #press_a_key
	jsr draw_tile
	jsr any_key
	rts
	
draw_board
	lda #0
;	ldx #sprite_data
	ldx #rooms
	ldy #VRAM
@lp
	pshs a
	ldd ,x ; get room x,y
	jsr set_draw_offset  ; set y based on A
	puls a ; restore room #
	jsr draw_room
	inca 
	cmpa last_room 
    bhi @x
	leax ROOM_SIZE,x
	ldb #0
	bra @lp
@x	rts

draw_player
	lda player_room
	ldb #ROOM_SIZE
	mul
	tfr d,x
	leax rooms,x
	lda ,x  ; x coord of room
	ldb 1,x ; y coord of room
	jsr set_draw_offset
	;set transparency to white
	jsr mask_white
	;ldx #sprite_player
	jsr set_player_sprite
	jsr mask_tile
	rts
	
	
	
	
;a contains new room
move_player
	sta player_room	
	jsr set_room_ptr
	;visit it
	lda ROOM_FLAGS_OFFSET,x
	ora #VISITED
	sta ROOM_FLAGS_OFFSET,x
	;is there a wumpus?
	lda ROOM_FLAGS_OFFSET,x
	anda #WUMPUS
	cmpa #WUMPUS
	bne @a
	jsr animate_wumpus
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr reveal_board
	ldx #wump_score
	jsr increment_score
	jsr draw_score_screen
	jsr reset_game
	bra @x
	;is there a pit?
@a	lda ROOM_FLAGS_OFFSET,x
	anda #PIT
	cmpa #PIT
	bne @b
	jsr animate_fall
	jsr reveal_board
	ldx #pit_score
	jsr increment_score
	jsr draw_score_screen
	jsr reset_game
	bra @x
@b	;is there a bat?
	lda ROOM_FLAGS_OFFSET,x
	anda #BAT
	cmpa #BAT
	bne @m
	; has the bat been seen before
	lda ROOM_FLAGS_OFFSET,x
	anda #BAT_SEEN
	cmpa #BAT_SEEN
	beq @bs
	;now the bat has been seen
	lda ROOM_FLAGS_OFFSET,x
	ora #BAT_SEEN
	sta ROOM_FLAGS_OFFSET,x
	bra @m
@bs	lda ROOM_FLAGS_OFFSET,x ; remove bat
	anda #CLR_BAT
	anda #CLR_BAT_SEEN
	sta ROOM_FLAGS_OFFSET,x
	jsr animate_bat
	;move bat
	jsr find_non_tunnel
	lda ROOM_FLAGS_OFFSET,x
	ora #BAT
	sta ROOM_FLAGS_OFFSET,x
	;move player
	ldd #64
	pshu d
	jsr randmod
	pulu d
	tfr b,a
;	stb player_room
;	tfr b,a
;	jsr set_room_ptr
;	lda ROOM_FLAGS_OFFSET,x
;	ora #VISITED
;	sta ROOM_FLAGS_OFFSET,x	
	jsr move_player
	bra @x
@m	jsr play_footstep
@x	rts	
	
key_to_offset
	cmpa #'W'
	bne @a
	lda #2
	bra @x
@a  cmpa #'S'
	bne @b
	lda #3
	bra @x
@b	cmpa #'A'
	bne @c
	lda #4
	bra @x
@c	lda #5  ; must be 'D'
@x	rts

;x points to the room entry in the table
;if its a room, draw the sprite
;if its a tunnel, mask the sprite
draw_room
	pshs d,x,y
	lda ROOM_FLAGS_OFFSET,x
	anda #VISITED	
	cmpa #VISITED
	bne @x	
	lda ROOM_TYPE_OFFSET,x	
	cmpa #ROOM
	bne @t
	pshs x
	jsr set_room_sprite
	jsr draw_tile
	puls x
	;does is have a  ?
	lda ROOM_FLAGS_OFFSET,x
	anda #WUMPUS
	cmpa #WUMPUS 
	bne @b
	jsr mask_white
	pshs x
	ldx #sprite_wumpus
	jsr mask_tile
	puls x
@b	;does is have a bat?
	lda ROOM_FLAGS_OFFSET,x
	anda #BAT
	cmpa #BAT
	bne @x 
	jsr mask_white
	ldx #sprite_bat
	jsr mask_tile
	bra @x
@t  
	jsr set_tunnel_sprite
	;set transparency to orange
	jsr mask_orange
	jsr mask_tile
@x	puls d,x,y
	rts

;a contains room type
;post: x points to room
set_tunnel_sprite
	cmpa #TUNNEL_1
	bne @a
	ldx #sprite_tunnel_1
	bra @x
@a  cmpa #TUNNEL_2
	bne @b
	ldx #sprite_tunnel_2
	bra @x
@b  cmpa #TUNNEL_3
	bne @c
	ldx #sprite_tunnel_3
	bra @x
@c  ldx #sprite_tunnel_4
@x	rts

;sets the x to the player sprite 
;based on the type of room the player is in 
;if the player is in the wumpus room
;the sprite is set to all white (to hide it)
set_player_sprite
	pshs d
	lda player_room
	jsr set_room_ptr
	lda ROOM_TYPE_OFFSET,x
	ldb ROOM_FLAGS_OFFSET,x
	andb #WUMPUS
	cmpa #ROOM
	bne @a
	;its a room
	cmpb #WUMPUS
	bne @r
	ldx #sprite_white
	bra @x
@r	ldx #sprite_player
	bra @x	
@a	cmpa #TUNNEL_1
	bne @b
	ldx #sprite_player_up_left
	bra @x	
@b	cmpa #TUNNEL_2
	bne @c
	ldx #sprite_player_down_right ; works-move sprite up
	bra @x	
@c	cmpa #TUNNEL_3
	bne @d
	ldx #sprite_player_down_left
	bra @x	
@d	ldx #sprite_player_up_right  ; type 4
@x  puls d
	rts
	
;sets x to the sprite required
;by the room# in a
;assume its a room and not a tunnel
set_room_sprite
	pshs d,y
	lda ROOM_FLAGS_OFFSET,x
	anda #PIT
	cmpa #PIT
	bne @a
	ldx #sprite_pit
	bra @x
@a  lda ROOM_FLAGS_OFFSET,x
	anda #(DRAFT|SLIME)
	cmpa #(DRAFT|SLIME)
	bne @b
	ldx #sprite_draft_slime
	bra @x
@b	lda ROOM_FLAGS_OFFSET,x
	anda #SLIME
	cmpa #SLIME
	bne @c
	ldx #sprite_room_slime
	bra @x
@c 	lda ROOM_FLAGS_OFFSET,x
	anda #DRAFT
	cmpa #DRAFT
	bne @d
	ldx #sprite_room_draft
	bra @x
@d	ldx #sprite_room
@x	puls d,y
	rts

 

;after: x points to room to modify	
find_non_tunnel
	pshs b ;save b
	pshs a ; create a local var
@lp
	ldd #64  
	pshu d
	jsr randmod
	pulu x ; pull result
	tfr x,d ; 16 bit # to d
	tfr b,a ; lower half to a
	sta 1,s  ; save room# in local var
	ldb #ROOM_SIZE
	mul
	tfr d,x
	leax rooms,x	
	ldb ROOM_TYPE_OFFSET,x
	cmpb #ROOM
	beq @x
	bra @lp
@x	
	lda 1,s ; reload room#
	leas 1,s ; pop local var
	puls b ; restore b
	rts
	
;makes a / tunnel
;the bottom half becomes a new room
;at the end of the array	
make_tunnel_1
	pshs d,x,y
	jsr find_non_tunnel ;sets a,x
	lda #TUNNEL_1
	sta ROOM_TYPE_OFFSET,x ; upper /
	lda last_room
	inca
	sta last_room
	;need to set old down's up to new room
	lda DOWN,x
	pshu a ; room to alter
	lda #UP ; direction
	pshu a
	lda last_room ; push current room (dest)
	pshu a
	jsr set_room_connection
	;need to set old right's left to new room
	lda RIGHT,x
	pshu a
	lda #LEFT
	pshu a
	lda  last_room ; push current room
	pshu a
	jsr set_room_connection
	;compute offset of new room
	ldb #ROOM_SIZE
	mul
	tfr d,y
	leay rooms,y ; y points to new room
	lda #TUNNEL_2
	sta ROOM_TYPE_OFFSET,y
	lda DRAW_X,x ; copy coorinates
	sta DRAW_X,y
	lda DRAW_Y,x
	sta DRAW_Y,y	
	lda #$FF
	sta UP,y ; can't go left or up in new
	sta LEFT,y
	lda RIGHT,x ; copy right and down rooms
	sta RIGHT,y
	lda DOWN,x
	sta DOWN,y
	lda #$FF    ; old room can't go right or down now
	sta RIGHT,x
	sta DOWN,x
	puls d,x,y
	rts

;makes a \ tunnel
;the upper right half becomes a new room
;at the end of the array	
make_tunnel_2
	pshs d,x,y
	jsr find_non_tunnel ;sets a,x
	lda #TUNNEL_3
	sta ROOM_TYPE_OFFSET,x ; upper /
	lda last_room
	inca
	sta last_room
	;need to set old up's down to new room
	lda UP,x
	pshu a ; room to alter
	lda #DOWN ; direction
	pshu a
	lda last_room ; push current room (dest)
	pshu a
	jsr set_room_connection
	;need to set old right's left to new room
	lda RIGHT,x
	pshu a
	lda #LEFT
	pshu a
	lda  last_room ; push current room
	pshu a
	jsr set_room_connection
	;compute offset of new room
	ldb #ROOM_SIZE
	mul
	tfr d,y
	leay rooms,y ; y points to new room
	lda #TUNNEL_4
	sta ROOM_TYPE_OFFSET,y
	lda DRAW_X,x ; copy coorinates
	sta DRAW_X,y
	lda DRAW_Y,x
	sta DRAW_Y,y	
	lda #$FF
	sta DOWN,y ; can't go left or dwn in new
	sta LEFT,y
	lda RIGHT,x ; copy right and down rooms
	sta RIGHT,y
	lda UP,x
	sta UP,y
	lda #$FF    ; old room can't go up or right now
	sta RIGHT,x
	sta UP,x
	puls d,x,y
	rts

;,u = room to alter
;1,u = direction
;2,u = where it goes
set_room_connection
	pshs d,x,y
	lda 2,u
	ldb #ROOM_SIZE
	mul
	tfr d,x
	leax rooms,x
	ldb 1,u
	abx
	lda ,u ; get dest room
	sta ,x
	leau 3,u  ; clear args
	puls d,x,y
	rts

;finds the room that going in the specified
;direction from the start room eventually leads
;to.
;,u = direction
;1,u = start room #
;result in 'a'
;x is modified
find_room_end
	jsr clear_marks
	lda 1,u
	jsr mark_room ; mark start room, sets x
	ldb ,u  ; get direction
	abx
	lda ,x ; get start room
@lp	jsr mark_room  ; mark current room
	pshs a ; save room
	ldb #ROOM_SIZE
	mul
	tfr d,x  ; clobbers a
	leax rooms,x
	puls a  ; restore room
	ldb ROOM_TYPE_OFFSET,x
	cmpb #ROOM
	beq @x
	;lda with the non visited direction
	lda UP,x	
	jsr is_marked
	cmpb #0
	beq @ct
    lda DOWN,x	
	jsr is_marked
	cmpb #0
	beq @ct
    lda LEFT,x	
	jsr is_marked
	cmpb #0
	beq @ct
	lda RIGHT,x	; right is only remaining dir
@ct	bra @lp
@x	leau 2,u ; pop params
	rts

	
;sets transparency to white	
mask_white
	pshs d
	ldd white_mask
	std transparent
	ldd white_mask+2
	std transparent+2
	puls d
	rts

;sets transparency to orange
mask_orange
	pshs d
	ldd orange_mask
	std transparent
	ldd orange_mask+2
	std transparent+2
	puls d
	rts

;set MARKED flag in room A
;x is modified to room entry
mark_room
	pshs d
	ldb #ROOM_SIZE
	mul
	tfr d,x
	leax rooms,x
	lda ROOM_FLAGS_OFFSET,x
	ora #MARKED
	sta ROOM_FLAGS_OFFSET,x
	puls d
	rts
	
;sets B to 1 or 0 if room A is marked/not marked
is_marked
	pshs a,x
	cmpa #$FF ; invalid room
	beq @y 
	ldb #ROOM_SIZE
	mul
	tfr d,x
	leax rooms,x
	lda ROOM_FLAGS_OFFSET,x
	anda #MARKED
	cmpa #0
	beq @n
@y	ldb #1
	bra @x
@n  ldb #0
@x	puls a,x
	rts

;sets x to point to room in A
set_room_ptr
	pshs b
	ldb #ROOM_SIZE
	mul
	tfr d,x
	leax rooms,x
	puls b
	rts
	
;unsets the MARKED bit on all the rooms
;no registers affected
clear_marks
	pshs d,x
	lda #0
	ldb #0
	ldx #rooms
@lp
	lda ROOM_FLAGS_OFFSET,x
	anda #CLR_MARK
	sta ROOM_FLAGS_OFFSET,x
	incb 
	cmpb last_room
	bhi @x
	leax ROOM_SIZE,x
	bra @lp
@x	puls d,x
	rts

place_player
	pshs a
@lp	
	jsr find_non_tunnel
	sta ,s
	lda ROOM_FLAGS_OFFSET,x
	anda #WUMPUS
	cmpa #WUMPUS
	beq @lp
	lda ROOM_FLAGS_OFFSET,x
	anda #PIT
	cmpa #PIT
	beq @lp 
	lda ROOM_FLAGS_OFFSET,x
	anda #BAT
	cmpa #BAT
	beq @lp 	
	puls a 
	sta player_room
	;make it visited
	lda ROOM_FLAGS_OFFSET,x
	ora #VISITED
	sta ROOM_FLAGS_OFFSET,x
	rts

place_bat
	jsr find_non_tunnel
	lda ROOM_FLAGS_OFFSET,x
	ora #BAT
	sta ROOM_FLAGS_OFFSET,x
	rts
	
place_pit	
	jsr find_non_tunnel
	tfr a,b
	;make it a pit room
	lda ROOM_FLAGS_OFFSET,x
	ora #PIT
	sta ROOM_FLAGS_OFFSET,x
	pshs b ; save start room
    pshu b ; push start room
	lda #UP
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #DRAFT
	sta ROOM_FLAGS_OFFSET,x 
	;down
	lda ,s
	pshu a
	lda #DOWN
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #DRAFT
	sta ROOM_FLAGS_OFFSET,x 
	;left
	lda ,s
	pshu a
	lda #LEFT
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #DRAFT
	sta ROOM_FLAGS_OFFSET,x 
	;right
	lda ,s
	pshu a
	lda #RIGHT
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #DRAFT
	sta ROOM_FLAGS_OFFSET,x 
	puls a ; pop local var
	rts
	
place_wumpus
	jsr find_non_tunnel
	tfr a,b
	lda ROOM_FLAGS_OFFSET,x
	ora #WUMPUS
	sta ROOM_FLAGS_OFFSET,x
	pshs x
	;mark up down left,right as having slime
	pshs b ; save start room
    pshu b ; push start room
	lda #UP
	pshu a ; push direction
	jsr find_room_end
	jsr slime_neighbors
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	;down
	lda ,s
	pshu a
	lda #DOWN
	pshu a ; push direction
	jsr find_room_end
	jsr slime_neighbors
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	;left
	lda ,s
	pshu a
	lda #LEFT
	pshu a ; push direction
	jsr find_room_end
	jsr slime_neighbors
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	;right
	lda ,s
	pshu a
	lda #RIGHT
	pshu a ; push direction
	jsr find_room_end
	jsr slime_neighbors
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	puls a ; pop local var
	puls x
	;clear slime in wumpus room
	lda ROOM_FLAGS_OFFSET,x
	anda #CLR_SLIME
	sta ROOM_FLAGS_OFFSET,x
	rts

;a contains room to slime
;registers preserved
slime_neighbors
	pshs d,x,y
	;mark up down left,right as having slime
	tfr a,b
	pshs b ; save start room
    pshu b ; push start room
	lda #UP
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	;down
	lda ,s
	pshu a
	lda #DOWN
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	;left
	lda ,s
	pshu a
	lda #LEFT
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	;right
	lda ,s
	pshu a
	lda #RIGHT
	pshu a ; push direction
	jsr find_room_end
	lda ROOM_FLAGS_OFFSET,x
	ora #SLIME
	sta ROOM_FLAGS_OFFSET,x 
	puls a ; pop local var
	puls d,x,y
	rts

;shoots an arrow into the room in 'a'
shoot_arrow
	jsr animate_arrow
	lda player_room
	pshu a
	lda move_dir
	pshu a	
	jsr find_room_end ; set's x
	lda ROOM_FLAGS_OFFSET,x
	anda #WUMPUS
	cmpa #WUMPUS
	bne @n
	;animate win
	jsr animate_win
	jsr reveal_board
	ldx #player_score
	jsr increment_score
	jsr draw_score_screen
	jsr reset_game
	bra @x
@n  jsr animate_wumpus
	jsr reveal_board
	jsr reset_game
@x	lda #0 ; reset shoot flag
	sta shooting
	rts
	
;draws the arrow flying
animate_arrow
	pshs d,x,y
	ldx #tunnel_tile_map
	jsr draw_tile_map
	lda #0
	ldb #3
	jsr set_draw_offset
	ldx #sprite_arrow_1
	jsr draw_tile
	jsr waste_time
	jsr waste_time
	jsr waste_time
	ldx #sprite_arrow_2
	jsr draw_tile
	jsr waste_time
@lp
	;overwrite old tile
	ldx #white_tile
	jsr draw_tile
	;
	inca
	cmpa #8
	beq @d
	jsr set_draw_offset
	ldx #sprite_arrow_1
	jsr draw_tile
	jsr waste_time
	jsr waste_time
	jsr waste_time
	ldx #sprite_arrow_2
	jsr draw_tile
	bra @lp
@d
	puls d,x,y
	rts

;draws the player falling
animate_fall
	ldx #fall_music
	clr 1,x ; reset cur sound
 	ldx #pit_tile_map
	jsr draw_tile_map
	ldx #sprite_falling_player_1
	lda #3
	ldb #0
	jsr set_draw_offset
	jsr draw_tile
	jsr waste_time
	;music
	pshs x
	ldx #fall_music
	jsr play_note
	puls x
	;end music
	ldx #sprite_falling_player_2
	jsr draw_tile
	;jsr waste_time
	;music
	pshs x
	ldx #fall_music
	jsr play_note
	puls x
	;end music
@l1 
	;erase last tile
	ldx #sprite_white
	jsr draw_tile
	; inc loop counter
	incb
	cmpb #7
	beq @d
	pshs a ; save loop counter
	lda #3
	jsr set_draw_offset
	puls a ; restore loop counter
	ldx #sprite_falling_player_1
	jsr draw_tile
	;jsr waste_time
	;jsr waste_time
 	;draw 2nd tile
	;music
	pshs x
	ldx #fall_music
	jsr play_note
	puls x
	;end music
	ldx #sprite_falling_player_2
	jsr draw_tile
	;jsr waste_time
	;music
	pshs x
	ldx #fall_music
	jsr play_note
	puls x
	;end music
	bra @l1
@d	
	ldx #sprite_splat
	jsr draw_tile
	jsr any_key
	;
	lda #BLACK_FILL
	jsr cls
	rts

;animates the teeth	
animate_wumpus
	lda #ORANGE_FILL
	jsr cls
	ldx #VRAM
	ldd #0
	jsr set_draw_offset
	sty temp_upper
	ldx #sprite_tooth_upper
	jsr draw_row
	lda #0
	ldb #7
	jsr set_draw_offset
	sty temp_lower
	ldx #sprite_tooth_lower
	jsr draw_row
	lda #0
@tl	
	;white out old top line
	ldy temp_upper
	ldx #sprite_white
	jsr draw_row
	;add 768 to old top
	leay 768,y
	sty temp_upper
	;draw new line of upper teeth
	ldx #sprite_tooth_upper
	jsr draw_row
	;update loop counter
	jsr waste_time
	jsr waste_time
	jsr waste_time
	inca
	cmpa #6
	beq @d
	bra @tl
@d	;draw the eyes
	ldx #wumpus_music
	clr 1,x ; reset music
	jsr play_song
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	jsr waste_time
	;eyes
	lda #2
	ldb #2
	jsr set_draw_offset
	ldx #sprite_left_eye
	jsr draw_tile
	lda #5
	ldb #2
	jsr set_draw_offset
	ldx #sprite_right_eye
	jsr draw_tile
;@lp1
;	jsr KBSCAN
;	cmpa #0
;	beq @lp1	
	rts

;draws the tile in x 8 times
;to the address stored in y
draw_row
	pshs d,x,y
	lda #0
@l2 
	pshs x
	pshs y
	jsr draw_tile
	puls y
	leay 4,y
	puls x 
	inca 
	cmpa #8
	bcs @l2		
	puls d,x,y
	rts	
	
;animates the bat flying a player to a new room
animate_bat
	pshs d,x,y
	ldx #tunnel_tile_map
	jsr draw_tile_map
	lda #0
	ldb #3
	jsr set_draw_offset
	ldx #sprite_player_bat_1
	jsr draw_tile
	jsr waste_time
	jsr waste_time
	ldx #sprite_player_bat_2
	jsr draw_tile
	jsr waste_time
	jsr waste_time
@lp
	;overwrite old tile
	ldx #white_tile
	jsr draw_tile
	;next tile
	inca
	cmpa #8
	beq @d
	jsr set_draw_offset
	ldx #sprite_player_bat_1
	jsr draw_tile
	jsr waste_time
	jsr waste_time
	ldx #sprite_player_bat_2
	jsr draw_tile
	jsr waste_time
	jsr waste_time
	bra @lp
@d
	lda #BLACK_FILL
	jsr cls
	puls d,x,y
	rts
	
;animates the victory screen
animate_win
	ldx #win_tile_map
	jsr draw_tile_map
	
	;draw the victory sprite
	lda #9 ; width
	pshu a
	lda #20 ; height
	pshu a
	lda #12  ; x,y
	ldb #80 ; 
	ldy #sprite_victory
	jsr draw_sprite
	
	ldx #win_music
	jsr play_song
	jsr any_key
	rts

get_skill_level
	ldx #choose_skill_tile_map
	jsr draw_tile_map
	jsr draw_selected_skill
@lp1
	jsr KBSCAN
	cmpa #0
	beq @lp1
	cmpa #$0d  ; cr
	beq @x
	cmpa #'W'  ; up?
	bne @d
	dec skill_level
    lda skill_level
	cmpa #$ff
	bne @c
	lda #2
	sta skill_level
	bra @c
@d  cmpa #'S'
	bne @lp1
	inc skill_level
    lda skill_level
	cmpa #3
	bne @c
	lda #0
	sta skill_level
@c	jsr draw_selected_skill
	bra @lp1
@x	rts

draw_selected_skill
	pshs d,x,y
	lda skill_level
	cmpa #0
	bne @m
	lda #2
	ldb #3
	jsr set_draw_offset
	ldx #sprite_player
	jsr draw_tile
	lda #2
	ldb #4
	jsr set_draw_offset
	ldx #white_tile
	jsr draw_tile
	lda #2
	ldb #5
	jsr set_draw_offset
	ldx #white_tile
	jsr draw_tile
	bra @x
@m	cmpa #1
	bne @h
	lda #2
	ldb #3
	jsr set_draw_offset
	ldx #white_tile
	jsr draw_tile
	lda #2
	ldb #4
	jsr set_draw_offset
	ldx #sprite_player
	jsr draw_tile
	lda #2
	ldb #5
	jsr set_draw_offset
	ldx #white_tile
	jsr draw_tile
	bra @x
@h	lda #2
	ldb #3
	jsr set_draw_offset
	ldx #white_tile
	jsr draw_tile
	lda #2
	ldb #4
	jsr set_draw_offset
	ldx #white_tile
	jsr draw_tile
	lda #2
	ldb #5
	jsr set_draw_offset
	ldx #sprite_player
	jsr draw_tile
@x	puls d,x,y
	rts
	
waste_time
	pshs d,x,y
	ldb #$0F
@l1	
	lda #$FF
@l2	deca
	cmpa #0
	bne @l2
	decb
	cmpb #0
	bne @l1
	puls d,x,y
	rts

;x contains addr of tile map
draw_tile_map
	pshs d,x,y
	lda #0
	ldb #0
	ldy #VRAM
@lp pshs x
	ldx ,x
	jsr draw_tile
	puls x
	leax 2,x ; move to next tile addr
	leay 4,y ; move 4 bytes over to next tile
	inca 
	cmpa #64 ; 64 tiles on screen
    beq @x
	incb
	cmpb #8
	bne @lp
	leay 768-32,y ; drop down one line of tiles
	ldb #0
	bra @lp
@x
	puls d,x,y
	rts

;sets the visited bit to true on 
;all the rooms
reveal_board
	pshs d,x,y
	lda #0
@lp	pshs a
	jsr set_room_ptr
	lda ROOM_FLAGS_OFFSET,x
	ora #VISITED
	sta ROOM_FLAGS_OFFSET,x
	puls a
	inca
	cmpa last_room
	bcs @lp ; <
	beq @lp ; = 
	jsr draw_board
	jsr any_key
	puls d,x,y
	rts
	
;reinitializes all rooms and places
;player and hazards
reset_game
	jsr reset_rooms
	jsr make_tunnels
	jsr place_pit
	jsr place_pit
	jsr place_wumpus
	jsr place_bat
	jsr place_bat
	jsr place_player	
	lda #BLACK_FILL
	jsr cls
	jsr draw_board
	rts

make_tunnels
	jsr make_tunnel_1
	jsr make_tunnel_1
	jsr make_tunnel_2
    jsr make_tunnel_2
	lda skill_level
	cmpa #EASY
	beq @x
	jsr make_tunnel_1
	jsr make_tunnel_1
	jsr make_tunnel_2
    jsr make_tunnel_2
	jsr make_tunnel_1
    jsr make_tunnel_2	
	lda skill_level
	cmpa #MEDIUM
	beq @x
	jsr make_tunnel_1
	jsr make_tunnel_1
	jsr make_tunnel_2
    jsr make_tunnel_2	
	jsr make_tunnel_2
    jsr make_tunnel_2	
@x	rts
	
;overwrites the room data with a 'clean' copy
;and resets the last room #
reset_rooms
	ldx #rooms
	ldy #initial_room_cfg
@lp	lda ,y+
	sta ,x+
	cmpy #end_cfg_data
	bne @lp
	lda #63
	sta last_room
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;increments a score up to 999
;x points to score data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
increment_score
	inc 3,x
	lda #10
	cmpa 3,x
	bne @x
	;carry into 2nd digit
	clr 3,x
	inc 2,x
	cmpa 2,x
	bne @x
	;carry into 3rd digit
	clr 2,x
	inc 1,x
	cmpa 1,x
	bne @x
	;rolled over
	clr 1,x	
@x	rts
	
;reseeds random seed	
any_key
	leas -1,s  ; push local
	clra	
@lp
	inc ,s
	jsr KBSCAN
	cmpa #0
	beq @lp
	ldb CUR_RAND+1 ; left lsb to msb
	stb CUR_RAND
	lda ,s			; new lsb 
	cmpa #0	
	bne @s
	lda #1   ; don't let a seed be 0!
@s	sta CUR_RAND+1
	leas 1,s  ; pop local
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;draws the score on the screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; a = x in 4 pixel units
; b = y in pixels`
; x contains score data address
draw_score
	pshs d,x,y
	pshs a ; save x (2,s)
	pshs b ; save y (1,s)
	lda ,x 
	pshs a ; save #digits (,s)
	leax 3,x ; rightmost digit 
	clra ; loop counter
@lp pshs a 
	pshs x  ; data score data addr
	lda ,x  ; get digit
	ldb #DIGIT_SIZE ; in bytes
	mul
	tfr d,y
	leay digits,y ; y now has sprite addr
	lda #DIGIT_WIDTH
	pshu a
	lda #DIGIT_HEIGHT
	pshu a	
	lda 5,s ; reload x coord  
	ldb 4,s ; reload y coord  
	jsr draw_sprite ; draw sprite x and addr y
	dec 5,s ; move left on screen
	dec 5,s ; move left on screen
	puls x ; restore data addr
	leax -1,x ; move to next digit
	puls a ; reload loop counter
	inca
    cmpa ,s ; drawn all digits?
	bne @lp
	leas 3,s   ; pop locals
	puls d,x,y
	rts
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PLAYS THE WIN MUSIC 
;A IS CLOBBERED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
play_win_music
	lda #3
@lp	pshs d,x,y
	ldy	#55		;length (0.125 x 440hz)
	lda #135		;a
	sta freq
	jsr sound_play
	ldy	#73		;length (0.125 x 587)
	lda #100		;d
	sta freq
	jsr sound_play
	ldy	#110		;length (0.125 x  749)
	lda #78		;f#
	sta freq
	jsr sound_play	
	puls y,x,d
	deca
	cmpa #0
	bne @lp
	rts		
	
	include math.asm
	include random.asm
	include drawing.asm
	
	;format: x,y,u,d,l,r,room type,flags
rooms
	.db 0,0,56,8,7,1,0,0 ; x,y,u,d,l,r,flags 0
	.db 1,0,57,9,0,2,0,0 ; x,y,u,d,l,r,flags 1
	.db 2,0,58,10,1,3,0,0 ; x,y,u,d,l,r,flags 2
	.db 3,0,59,11,2,4,0,0 ; x,y,u,d,l,r,flags 3
	.db 4,0,60,12,3,5,0,0 ; x,y,u,d,l,r,flags 4
	.db 5,0,61,13,4,6,0,0 ; x,y,u,d,l,r,flags 5
	.db 6,0,62,14,5,7,0,0 ; x,y,u,d,l,r,flags 6
	.db 7,0,63,15,6,0,0,0 ; x,y,u,d,l,r,flags 7
	
	.db 0,1,0,16,15,9,0,0 ; x,y,u,d,l,r,flags 8
	.db 1,1,1,17,8,10,0,0 ; x,y,u,d,l,r,flags 9
	.db 2,1,2,18,9,11,0,0 ; x,y,u,d,l,r,flags 10
	.db 3,1,3,19,10,12,0,0 ; x,y,u,d,l,r,flags 11
	.db 4,1,4,20,11,13,0,0 ; x,y,u,d,l,r,flags 12
	.db 5,1,5,21,12,14,0,0 ; x,y,u,d,l,r,flags 13
	.db 6,1,6,22,13,15,0,0 ; x,y,u,d,l,r,flags 14
	.db 7,1,7,23,14,8,0,0 ; x,y,u,d,l,r,flags 15

	.db 0,2,8,24,23,17,0,0 ; x,y,u,d,l,r,flags 16
	.db 1,2,9,25,16,18,0,0 ; u,d,l,r,flags 17
	.db 2,2,10,26,17,19,0,0 ; u,d,l,r,flags 18
	.db 3,2,11,27,18,20,0,0 ; u,d,l,r,flags 19
	.db 4,2,12,28,19,21,0,0 ; u,d,l,r,flags 20
	.db 5,2,13,29,20,22,0,0 ; u,d,l,r,flags 21
	.db 6,2,14,30,21,23,0,0 ; u,d,l,r,flags 22
	.db 7,2,15,31,22,16,0,0 ; u,d,l,r,flags 23

	.db 0,3,16,32,31,25,0,0 ; x,y,u,d,l,r,flags 24
	.db 1,3,17,33,24,26,0,0 ; u,d,l,r,flags 25
	.db 2,3,18,34,25,27,0,0 ; u,d,l,r,flags 26
	.db 3,3,19,35,26,28,0,0 ; u,d,l,r,flags 27
	.db 4,3,20,36,27,29,0,0 ; u,d,l,r,flags 28
	.db 5,3,21,37,28,30,0,0 ; u,d,l,r,flags 29
	.db 6,3,22,38,29,31,0,0 ; u,d,l,r,flags 30
	.db 7,3,23,39,30,24,0,0 ; u,d,l,r,flags 31

	.db 0,4,24,40,39,33,0,0 ; u,d,l,r,flags 32
	.db 1,4,25,41,32,34,0,0 ; u,d,l,r,flags 33
	.db 2,4,26,42,33,35,0,0 ; u,d,l,r,flags 34
	.db 3,4,27,43,34,36,0,0 ; u,d,l,r,flags 35
	.db 4,4,28,44,35,37,0,0 ; u,d,l,r,flags 36
	.db 5,4,29,45,36,38,0,0 ; u,d,l,r,flags 37
	.db 6,4,30,46,37,39,0,0 ; u,d,l,r,flags 38
	.db 7,4,31,47,38,32,0,0 ; u,d,l,r,flags 39

	.db 0,5,32,48,47,41,0,0 ; u,d,l,r,flags 40
	.db 1,5,33,49,40,42,0,0 ; u,d,l,r,flags 41
	.db 2,5,34,50,41,43,0,0 ; u,d,l,r,flags 42
	.db 3,5,35,51,42,44,0,0 ; u,d,l,r,flags 43
	.db 4,5,36,52,43,45,0,0 ; u,d,l,r,flags 44
	.db 5,5,37,53,44,46,0,0 ; u,d,l,r,flags 45
	.db 6,5,38,54,45,47,0,0 ; u,d,l,r,flags 46
	.db 7,5,39,55,46,40,0,0 ; u,d,l,r,flags 47

	.db 0,6,40,56,55,49,0,0 ; u,d,l,r,flags 48
	.db 1,6,41,57,48,50,0,0 ; u,d,l,r,flags 49
	.db 2,6,42,58,49,51,0,0 ; u,d,l,r,flags 50
	.db 3,6,43,59,50,52,0,0 ; u,d,l,r,flags 51
	.db 4,6,44,60,51,53,0,0 ; u,d,l,r,flags 52
	.db 5,6,45,61,52,54,0,0 ; u,d,l,r,flags 53
	.db 6,6,46,62,53,55,0,0 ; u,d,l,r,flags 54
	.db 7,6,47,63,54,48,0,0 ; u,d,l,r,flags 55

	.db 0,7,48,0,63,57,0,0 ; u,d,l,r,flags 56
	.db 1,7,49,1,56,58,0,0 ; u,d,l,r,flags 57
	.db 2,7,50,2,57,59,0,0 ; u,d,l,r,flags 58
	.db 3,7,51,3,58,60,0,0 ; u,d,l,r,flags 59
	.db 4,7,52,4,59,61,0,0 ; u,d,l,r,flags 60
	.db 5,7,53,5,60,62,0,0 ; u,d,l,r,flags 61
	.db 6,7,54,6,61,63,0,0 ; u,d,l,r,flags 62
	.db 7,7,55,7,62,56,0,0 ; u,d,l,r,flags 63
;extra (for tunnels)
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	

initial_room_cfg
	.db 0,0,56,8,7,1,0,0 ; x,y,u,d,l,r,flags 0
	.db 1,0,57,9,0,2,0,0 ; x,y,u,d,l,r,flags 1
	.db 2,0,58,10,1,3,0,0 ; x,y,u,d,l,r,flags 2
	.db 3,0,59,11,2,4,0,0 ; x,y,u,d,l,r,flags 3
	.db 4,0,60,12,3,5,0,0 ; x,y,u,d,l,r,flags 4
	.db 5,0,61,13,4,6,0,0 ; x,y,u,d,l,r,flags 5
	.db 6,0,62,14,5,7,0,0 ; x,y,u,d,l,r,flags 6
	.db 7,0,63,15,6,0,0,0 ; x,y,u,d,l,r,flags 7
	
	.db 0,1,0,16,15,9,0,0 ; x,y,u,d,l,r,flags 8
	.db 1,1,1,17,8,10,0,0 ; x,y,u,d,l,r,flags 9
	.db 2,1,2,18,9,11,0,0 ; x,y,u,d,l,r,flags 10
	.db 3,1,3,19,10,12,0,0 ; x,y,u,d,l,r,flags 11
	.db 4,1,4,20,11,13,0,0 ; x,y,u,d,l,r,flags 12
	.db 5,1,5,21,12,14,0,0 ; x,y,u,d,l,r,flags 13
	.db 6,1,6,22,13,15,0,0 ; x,y,u,d,l,r,flags 14
	.db 7,1,7,23,14,8,0,0 ; x,y,u,d,l,r,flags 15

	.db 0,2,8,24,23,17,0,0 ; x,y,u,d,l,r,flags 16
	.db 1,2,9,25,16,18,0,0 ; u,d,l,r,flags 17
	.db 2,2,10,26,17,19,0,0 ; u,d,l,r,flags 18
	.db 3,2,11,27,18,20,0,0 ; u,d,l,r,flags 19
	.db 4,2,12,28,19,21,0,0 ; u,d,l,r,flags 20
	.db 5,2,13,29,20,22,0,0 ; u,d,l,r,flags 21
	.db 6,2,14,30,21,23,0,0 ; u,d,l,r,flags 22
	.db 7,2,15,31,22,16,0,0 ; u,d,l,r,flags 23

	.db 0,3,16,32,31,25,0,0 ; x,y,u,d,l,r,flags 24
	.db 1,3,17,33,24,26,0,0 ; u,d,l,r,flags 25
	.db 2,3,18,34,25,27,0,0 ; u,d,l,r,flags 26
	.db 3,3,19,35,26,28,0,0 ; u,d,l,r,flags 27
	.db 4,3,20,36,27,29,0,0 ; u,d,l,r,flags 28
	.db 5,3,21,37,28,30,0,0 ; u,d,l,r,flags 29
	.db 6,3,22,38,29,31,0,0 ; u,d,l,r,flags 30
	.db 7,3,23,39,30,24,0,0 ; u,d,l,r,flags 31

	.db 0,4,24,40,39,33,0,0 ; u,d,l,r,flags 32
	.db 1,4,25,41,32,34,0,0 ; u,d,l,r,flags 33
	.db 2,4,26,42,33,35,0,0 ; u,d,l,r,flags 34
	.db 3,4,27,43,34,36,0,0 ; u,d,l,r,flags 35
	.db 4,4,28,44,35,37,0,0 ; u,d,l,r,flags 36
	.db 5,4,29,45,36,38,0,0 ; u,d,l,r,flags 37
	.db 6,4,30,46,37,39,0,0 ; u,d,l,r,flags 38
	.db 7,4,31,47,38,32,0,0 ; u,d,l,r,flags 39

	.db 0,5,32,48,47,41,0,0 ; u,d,l,r,flags 40
	.db 1,5,33,49,40,42,0,0 ; u,d,l,r,flags 41
	.db 2,5,34,50,41,43,0,0 ; u,d,l,r,flags 42
	.db 3,5,35,51,42,44,0,0 ; u,d,l,r,flags 43
	.db 4,5,36,52,43,45,0,0 ; u,d,l,r,flags 44
	.db 5,5,37,53,44,46,0,0 ; u,d,l,r,flags 45
	.db 6,5,38,54,45,47,0,0 ; u,d,l,r,flags 46
	.db 7,5,39,55,46,40,0,0 ; u,d,l,r,flags 47

	.db 0,6,40,56,55,49,0,0 ; u,d,l,r,flags 48
	.db 1,6,41,57,48,50,0,0 ; u,d,l,r,flags 49
	.db 2,6,42,58,49,51,0,0 ; u,d,l,r,flags 50
	.db 3,6,43,59,50,52,0,0 ; u,d,l,r,flags 51
	.db 4,6,44,60,51,53,0,0 ; u,d,l,r,flags 52
	.db 5,6,45,61,52,54,0,0 ; u,d,l,r,flags 53
	.db 6,6,46,62,53,55,0,0 ; u,d,l,r,flags 54
	.db 7,6,47,63,54,48,0,0 ; u,d,l,r,flags 55

	.db 0,7,48,0,63,57,0,0 ; u,d,l,r,flags 56
	.db 1,7,49,1,56,58,0,0 ; u,d,l,r,flags 57
	.db 2,7,50,2,57,59,0,0 ; u,d,l,r,flags 58
	.db 3,7,51,3,58,60,0,0 ; u,d,l,r,flags 59
	.db 4,7,52,4,59,61,0,0 ; u,d,l,r,flags 60
	.db 5,7,53,5,60,62,0,0 ; u,d,l,r,flags 61
	.db 6,7,54,6,61,63,0,0 ; u,d,l,r,flags 62
	.db 7,7,55,7,62,56,0,0 ; u,d,l,r,flags 63
	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64
	.db 0,0,0,0,0,0,0,0 ; u,d,l,r,flags 64	

end_cfg_data
	
	
	
	include sprites.asm
	include tile_maps.asm
	include calibration.asm
	include sound.asm
	
player_room .db 9
move_dir .db 0 ; direction offset for move/shoot
shooting .db 0
last_room .db 63
transparent .db 0,0,0,0 ; address of mask
white_mask .db $C0,$30,12,3
orange_mask .db 80h,20h,8,2
temp_lower .dw 0
temp_upper .dw 0
wumpus_wins .db 0
player_wins .db 0
pit_wins .db 0
skill_level .db 1 ; 0,1, or 2
color .db $E4 ; 11100100	
dividend 	.db 0x00
divisor 	.db 0x00
quotient_16 .db 0x00 ; padding (for loading it into y)
quotient  	.db 0x00
temp_word 	.dw 0
;1st byte is number of chars
;each byte is a base 10 digit
pit_score .db 3,0,0,0
wump_score .db 3,0,0,0
player_score .db 3,0,0,0

sstack_save .dw 0
ustack_save .dw 0
rv_save .dw 0 ; reset vector save

	END START

	; Full graphic 3-C  11001100 128x96x4   $C00(3072