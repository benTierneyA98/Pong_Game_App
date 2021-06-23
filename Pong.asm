STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	BALL_X DW 0Ah ;X position (column) of the ball
	BALL_Y DW 0Ah ;Y position (line) of the ball
	BALL_SIZE DW 04h	;siize of the ball (how many pixels does ball have in width and height)

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK	;assume as code, data and stack segments the respective registers
	PUSH DS							;push to the stack the DS segments
	SUB AX,AX						;clean the AX register
	PUSH AX							;push AX to the stack
	MOV AX,DATA						;save on the AX register the contents of the DATA segment
	MOV DS,AX						;save on the DS segment the contents of AX
	POP AX							;release the top item of the stack to the AX register
	POP AX							;release the top item of the stack to the AX register
	
		MOV AH,00h 	;set configuration to video mode
		MOV AL,13h 	;choose video mode
		INT 10h		;execute configuration
		
		MOV AH,0Bh	;set configuration
		MOV BH,00h	;to background colour
		MOV BL,00h 	;choose black as background
		INT 10h		;execute the configuration
		
		CALL DRAW_BALL
	
		RET
	MAIN ENDP
	
	DRAW_BALL PROC NEAR
	
		MOV CX,BALL_X	;set the initial column (X)
		MOV DX,BALL_Y	;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch				;set configuration to writing a pixel
			MOV AL,0Fh				;choose white as colour
			MOV BH,00h				;set page number
			INT 10h					;execute the configuration
			
			INC CX					;CX = CX +1
			MOV AX,CX				;CX - BALL_X ? BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column)
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X			;the CX register goes back to the initial column
			INC DX					;we advance one line
			
			MOV AX,DX				;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line)
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
	
		RET
	DRAW_BALL ENDP

CODE ENDS
END