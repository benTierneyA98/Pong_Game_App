;PONG Game Application
;Written by Ben Tierney, last update 06/07/2021

;Assembler used:
;DOSBox 0.74-3

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

	WINDOW_WIDTH DW 140h						;width of window (320 pixels)
	WINDOW_HEIGHT DW 0C8h						;height of window (200 pixels)
	WINDOW_BOUNDS DW 6							;variable used to check collisions early

	TIME_AUX DB 0								;variable used when checking if time has changed

	BALL_ORIGINAL_X DW 0A0h						;X position (column) of the ball at beginning of the game
	BALL_ORIGINAL_Y DW 64h						;Y position (line) of the ball at beginning of the game
	BALL_X DW 0A0h 								;current X position (column) of the ball
	BALL_Y DW 64h 								;current Y position (line) of the ball
	BALL_SIZE DW 04h							;siize of the ball (how many pixels does ball have in width and height)
	BALL_VELOCITY_X DW 05h						;X (horizontal) velocity of the ball
	BALL_VELOCITY_Y DW 02h						;Y (vertical) velocity of the ball
	
	PADDLE_LEFT_X DW 0Ah						;current X position of the left paddle
	PADDLE_LEFT_Y DW 0Ah						;current Y position of the left paddle
	
	PADDLE_RIGHT_X DW 130h						;current X position of the right paddle
	PADDLE_RIGHT_Y DW 0Ah						;current Y position of the right paddle
	
	PADDLE_WIDTH DW 05h							;default paddle width
	PADDLE_HEIGHT DW 1Fh						;default paddle height
	PADDLE_VELOCITY DW 05h						;default paddle velocity

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK				;assume as code, data and stack segments the respective registers
	PUSH DS										;push to the stack the DS segments
	SUB AX,AX									;clean the AX register
	PUSH AX										;push AX to the stack
	MOV AX,DATA									;save on the AX register the contents of the DATA segment
	MOV DS,AX									;save on the DS segment the contents of AX
	POP AX										;release the top item of the stack to the AX register
	POP AX										;release the top item of the stack to the AX register
	
		CALL CLEAR_SCREEN						; set initial video mode configuration
		
		CHECK_TIME:								;time checking loop
		
			MOV AH,2Ch							;get the system time
			INT 21h								;CH = hour CL = minute DH = second DL = 1/100 seconds

			CMP DL,TIME_AUX						;is the current time equal to the previous one(TIME_AUX)?
			JE CHECK_TIME						;if it is the same, check again
			
			;If it reaches this point, it's because the time has passed
			
			MOV TIME_AUX,DL						;if not, update time
			
			CALL CLEAR_SCREEN					;clear screen by restarting the video mode
			
			CALL MOVE_BALL						;move the ball
			CALL DRAW_BALL						;draw the ball
			
			CALL MOVE_PADDLES					;move the two paddles (check for pressing of keys)
			CALL DRAW_PADDLES					;draw the two paddles with the updated positions
			
			JMP CHECK_TIME						;after everything checks time again
	
		RET
	MAIN ENDP
	
	MOVE_BALL PROC NEAR							;process the ball movement
	
		;Move ball horizontally
		MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX							;move ball horizontal
		
		;Check if ball has passed the left boundary (BALL_X < 0 + WINDOW_BOUNDS)
		;If it is colliding, restart its position
		MOV AX, WINDOW_BOUNDS
		CMP BALL_X,AX							;BALL_X is compared with the left boundary of the screen (0 + WINDOW_BOUNDS)
		JL RESET_POSITION						;if it is less, reset the position
		
		;Check if ball has passed the right boundary (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
		;If it is colliding, restart its position
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_X,AX							;BALL_X is compared with the left boundary of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
		JG RESET_POSITION						;if it is greater, reset the position
		
		;Move the ball vertically
		MOV AX,BALL_VELOCITY_Y
		ADD BALL_Y,AX							;move ball vertically
		
		;Check if ball has passed the top boundary (BALL_Y < 0 + WINDOW_BOUNDS)
		;If it is colliding, reverse the velocity in Y
		MOV AX, WINDOW_BOUNDS
		CMP BALL_Y,AX							;BALL_Y is compared with the top boundary of the screen (BALL_Y < 0 + WINDOW_BOUNDS)
		JL NEG_VELOCITY_Y						;if it is less, rse the velocity in Y
		
		;Check if ball has passed the bottom boundary (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
		;If it is colliding, reverse the velocity in Y
		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX, WINDOW_BOUNDS
		CMP BALL_Y,AX							;BALL_Y is compared with the bottom boundary of the screen (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
		JG NEG_VELOCITY_Y						;if it is greater, rse the velocity in Y
			
		RET
		
		RESET_POSITION:
			CALL RESET_BALL_POSITION			;reset ball position to the center of the screen
			RET
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y					;reverse the velocity in Y of the ball (BALL_VELOCITY_Y = - BALL_VELOCITY_Y)
			RET
		
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR						;process movement of the paddles
	
		MOV AH,01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT	;ZF = 1, JZ -> Jump If Zero
		
		MOV AH,00h
		INT 16h
		
		;W key moves paddle up
		CMP AL,77h					;'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h					;'W'
		JE MOVE_LEFT_PADDLE_UP
		
		;S key moves paddle down
		CMP AL,73h					;'s'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h					;'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		;Right paddle movement
		CHECK_RIGHT_PADDLE_MOVEMENT:	
			
			;O key moves paddle up
			CMP AL,6Fh					;'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4Fh					;'O'
			JE MOVE_RIGHT_PADDLE_UP
			
			;L key moves paddle down
			CMP AL,6Ch					;'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4Ch					;'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_LEFT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
			EXIT_PADDLE_MOVEMENT:
			
	
		RET
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR				;restart ball position to center of the screen
	
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
	
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_BALL PROC NEAR
	
		MOV CX,BALL_X							;set the initial column (X)
		MOV DX,BALL_Y							;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch							;set configuration to writing a pixel
			MOV AL,0Fh							;choose white as colour
			MOV BH,00h							;set page number
			INT 10h								;execute the configuration
			
			INC CX								;CX = CX +1
			MOV AX,CX							;CX - BALL_X > BALL_SIZE (Y -> We go to the next line,N -> We continue to the next column)
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X						;the CX register goes back to the initial column
			INC DX								;we advance one line
			
			MOV AX,DX							;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure,N -> we continue to the next line)
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
	
		RET
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
	
		MOV CX,PADDLE_LEFT_X					;set the initial column (X)
		MOV DX,PADDLE_LEFT_Y					;set the initial line (Y)
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
		
			MOV AH,0Ch							;set configuration to writing a pixel
			MOV AL,0Fh							;choose white as colour
			MOV BH,00h							;set page number
			INT 10h								;execute the configuration
			
			INC CX								;CX = CX +1
			MOV AX,CX							;CX - PADDLE_LEFT_X  PADDLE_WIDTH(Y -> We go to the next line,N -> We continue to the next column)
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			MOV CX,PADDLE_LEFT_X				;the CX register goes back to the initial column
			INC DX								;we advance one line
			
			MOV AX,DX							;DX - PADDLE_LEFT_Y > PADDLE_HEIGHT (Y -> we exit this procedure,N -> we continue to the next line)
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
		MOV CX,PADDLE_RIGHT_X					;set the initial column (X)
		MOV DX,PADDLE_RIGHT_Y					;set the initial line (Y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
		
			MOV AH,0Ch							;set configuration to writing a pixel
			MOV AL,0Fh							;choose white as colour
			MOV BH,00h							;set page number
			INT 10h								;execute the configuration
			
			INC CX								;CX = CX +1
			MOV AX,CX							;CX - PADDLE_RIGHT_X  PADDLE_WIDTH(Y -> We go to the next line,N -> We continue to the next column)
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX,PADDLE_RIGHT_X				;the CX register goes back to the initial column
			INC DX								;we advance one line
			
			MOV AX,DX							;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Y -> we exit this procedure,N -> we continue to the next line)
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
	
		RET
	DRAW_PADDLES ENDP
	
	CLEAR_SCREEN PROC NEAR						;clear screen by restarting video mode
	
		MOV AH,00h 								;set configuration to video mode
		MOV AL,13h 								;choose video mode
		INT 10h									;execute configuration
			
		MOV AH,0Bh								;set configuration
		MOV BH,00h								;to background colour
		MOV BL,00h 								;choose black as background
		INT 10h									;execute the configuration
		RET
	CLEAR_SCREEN ENDP

CODE ENDS
END