;PONG Game Application
;Written by Ben Tierney, last update 23/06/2021

;Introduction:
;The purpose of this code is to run a PONG game

;Methodology:
;The code is broken down into the following sections

;Variables:
;

STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h	;width of window (320 pixels)
	WINDOW_HEIGHT DW 0C8h	;height of window (200 pixels)
	WINDOW_BOUNDS DW 6		;variable used to check collisions early

	TIME_AUX DB 0	;variable used when checking if time has changed

	BALL_ORIGINAL_X DW 0A0h	;
	BALL_ORIGINAL_Y DW 64h	;
	BALL_X DW 0A0h 			;X position (column) of the ball
	BALL_Y DW 64h 			;Y position (line) of the ball
	BALL_SIZE DW 04h		;siize of the ball (how many pixels does ball have in width and height)
	BALL_VELOCITY_X DW 05h	;X (horizontal) velocity of the ball
	BALL_VELOCITY_Y DW 02h	;Y (vertical) velocity of the ball

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
	
		CALL CLEAR_SCREEN
		
		CHECK_TIME:
		
			MOV AH,2Ch	;get the system time
			INT 21h		;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL,TIME_AUX		;is the current time equal to the previous one(TIME_AUX)?
			JE CHECK_TIME		;if it is the same, check again
			;if it's different, then draw, move, etc.
			
			MOV TIME_AUX,DL	;update time
			
			CALL CLEAR_SCREEN
			
			CALL MOVE_BALL
			CALL DRAW_BALL
			
			JMP CHECK_TIME	;after everything checks time again
	
		RET
	MAIN ENDP
	
	MOVE_BALL PROC NEAR
	
		MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX				;move ball horizontal
		
		MOV AX, WINDOW_BOUNDS
		CMP BALL_X,AX
		JL RESET_POSITION			;BALL_X < 0 + WINDOW_BOUNDS (Y -> collided)
		
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_X,AX				;BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS(Y -> collided)
		JG RESET_POSITION
		
		MOV AX,BALL_VELOCITY_Y
		ADD BALL_Y,AX				;move ball vertically
		
		MOV AX, WINDOW_BOUNDS
		CMP BALL_Y,AX
		JL NEG_VELOCITY_Y			;BALL_Y < 0 + WINDOW_BOUNDS (Y -> collided)
		
		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_Y,AX				;BALL_Y > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS(Y -> collided)
		JG NEG_VELOCITY_Y
			
		RET
		
		RESET_POSITION:
			CALL RESET_BALL_POSITION		;BALL_VELOCITY_X = - BALL_VELOCITY_X
			RET
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y		;BALL_VELOCITY_Y = - BALL_VELOCITY_Y
			RET
		
	MOVE_BALL ENDP
	
	RESET_BALL_POSITION PROC NEAR
	
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
	
		RET
	RESET_BALL_POSITION ENDP
	
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
	
	CLEAR_SCREEN PROC NEAR
		MOV AH,00h 	;set configuration to video mode
		MOV AL,13h 	;choose video mode
		INT 10h		;execute configuration
			
		MOV AH,0Bh	;set configuration
		MOV BH,00h	;to background colour
		MOV BL,00h 	;choose black as background
		INT 10h		;execute the configuration
		RET
	CLEAR_SCREEN ENDP

CODE ENDS
END