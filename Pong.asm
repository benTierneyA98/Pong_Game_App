STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	
		MOV AH,00h 	;set configuration to video mode
		MOV AL,13h 	;choose video mode
		INT 10h		;execute configuration
		
		MOV AH,0Bh	;set configuration
		MOV BH,00h	;to background colour
		MOV BL,00h 	;choose black as background
		INT 10h		;execute the configuration
		
		MOV AH,0Ch	;set configuration to writing a pixel
		MOV AL,0Fh	;choose white as colour
		MOV BH,00h	;set page number
		MOV CX,0Ah	;set the column (X)
		MOV DX,0Ah	;set the line (Y)
		INT 10h		;execute the configuration
		
	
		RET
	MAIN ENDP

CODE ENDS
END