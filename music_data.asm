;music data

start_music
	.db 11
	.db 0
	.db $70  ; C
	.dw 50	
	.db $35  ; C
	.dw 200	
	.db 0  ; pause
	.dw 0
	.db $35  ; C
	.dw 100	
	.db $48  ; g
	.dw 100
	.db 0  ; pause
	.dw 0
	.db $48  ; g
	.dw 75
	.db $57 ;e 
	.dw 90
	.db 0  ; pause
	.dw 0
	.db $57 ;e 
	.dw 65
	.db $70  ; C
	.dw 100	
	
	
win_music
	.db 9  ; notes cur note
	.db 0
	.db $70  ; C
	.dw 50	
	.db $52
	.dw 60
	.db $3f
	.dw 80
	.db $70
	.dw 50
	.db $52
	.dw 60
	.db $3F
	.dw 80
	.db $70
	.dw 50
	.db $52
	.dw 60
	.db $3F
	.dw 80
	
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
	.db $cb  ; g#
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
	.dw 50  
	.db $77  ; B
	.dw 65  
	.db $70  ; C
	.dw 70  
	.db $64  ; D
	.dw 70  	
	.db $57  ; E
	.dw 70  		
	.db $70  ; C
	.dw 70  
	.db $57  ; E
	.dw 130  		
	.db $5E  ; e flat
	.dw 75
	.db $77  ; B
	.dw 70  
	.db $5e  ; e flat
	.dw 130
	.db $64  ; D
	.dw 65  
	.db $7E  ; B flat
	.dw 70 
	.db $64  ; D
	.dw 125 
	.db $86  ; A
	.dw 50  
	.db $77  ; B
	.dw 65  
	.db $70  ; C
	.dw 65  
	.db $64  ; D
	.dw 70  	
	.db $57  ; E
	.dw 70  		
	.db $70  ; C
	.dw 70
	.db $86  ; A low
	.dw 60 
	.db $40  ; A high
	.dw 100  
	.db $48  ; G high
	.dw 90  		
	.db $57  ; E
	.dw 75  		
	.db $70  ; C
	.dw 70	
	.db $57  ; E
	.dw 75  
	.db $48  ; G high
	.dw 150 