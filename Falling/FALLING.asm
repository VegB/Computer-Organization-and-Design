; =======================
; FALLING
; VERSION 4.0
; CREDIT TO VegB
; EECS, PKU
; 2017/5/27
; =======================

DATA SEGMENT
        SCORE DB 0
        STATUS DB 0 ; 1-> WIN, 2-> LOSE, 3->QUIT
        MY_X DW 40
        MY_Y DW 10
        MY_POS DW ?
        BOARD_NUM DW 5
        BOARD_Y DW 10, 12, 17, 23, 30
        BOARD_X DW 20, 10, 17, 40, 55
        BOARD_L DW 10, 10, 25, 29,  8
        ON_BOARD DW 0
        TOP DW 9
        BOTTOM DW 24
        LEFT_WALL DW 8
        RIGHT_WALL DW 71
        STEP_LEN DW 4
        HEART_NUM DB 13
        HEART_POS DW 1480, 1488
                  DW 1784, 1792
                  DW 2608, 2616, 2624, 2600
                  DW 3600, 3608, 3616, 3624, 3632
        SCR_UPPER DB ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
        SCR_LOWER DB ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
        FACE_UPPER DB 03H, 0CH, 10H, 26H, 46H, 40H, 80H, 80H
                    DB 80H, 80H, 40H, 46H, 26H, 10H, 0CH, 03H
        SMILE_LOWER DB 0C0H, 30H, 08H, 04H, 02H, 22H, 11H, 09H
                    DB 09H, 11H, 22H,02H, 04H, 08H, 30H, 0C0H
        CRY_LOWER DB 0C0H, 30H, 08H, 04H, 02H, 0AH, 11H, 21H
                  DB 21H, 11H, 0AH, 02H, 04H, 08H, 30H, 0C0H
        STARTING_POS DW ?
        INDEX DB 0
        DATA1   DB 80H,96H,0AEH,0C5H,0D8H,0E9H,0F5H,0FDH ; USED BY 8253
                DB 0FFH,0FDH,0F5H,0E9H,0D8H,0C5H,0AEH,96H
                DB 80H,66H,4EH,38H,25H,15H,09H,04H
                DB 00H,04H,09H,15H,25H,38H,4EH,66H
        TIME    DB 120,106,94,89,79,70,63,59    
        NUM        DB   ?        ; INIT VALUE FOR 8253 COUNTER
        MSG_WIN DB "CONGRATULATIONS!", '$'
        MSG_WIN1 DB "YOU WON!", '$'
        MSG_LOSE DB "YOU LOSE! LOSER!", '$'
        MSG_NAME DB "FALLING", '$'
        MSG_VERSION DB "VERSION 4.0", '$'
        MSG_AUTHOR DB "CREDIT TO VegB", '$'
        MSG_SCHOOL DB "EECS, PKU", '$'
        MSG_SCORE DB "SCORE: ", '$'
        MSG_FINALSCORE DB "YOUR FINAL SCORE IS: ", '$'
        MSG_WELCOME DB "WELCOME TO 'FALLING'!", '$'
        MSG_INSTRUCTIONS DB "          INSTRUCTIONS: ", 0DH, 0AH, "          (1)PRESS 'D' TO GO RIGHT", 0DH, 0AH, "          (2)PRESS 'A' TO GO LEFT", 0DH, 0AH
                        DB "          (3)PRESS 'Q' TO QUIT", 0DH, 0AH, "          (4)FELL TO THE GROUND OR SQUASHED BY THE FLOOR AND YOU WILL...DIE", 0DH, 0AH
                        DB "          (5)COLLECT ALL THE HEART AND YOU ARE THE WINNER!", 0DH, 0AH, "          (6)PRESS SPACE TO START 'FALLING'!", '$'
        MSG_GOAL DB "TRY YOUR BEST TO COLLECT ALL THE ", '$'
        RAND_POS_NUM DW 10
        RAND_POS_Y DB 10, 17, 12, 23, 19, 11, 15, 16, 22, 14
        RAND_POS_X DB 20, 10, 17, 40, 23, 0, 60, 33, 7, 39
        MOUSE_POS DW ?
        SCREEN DW 25*80 DUP(?)
DATA ENDS

CODE SEGMENT
        ASSUME CS:CODE, DS: DATA
START:
        MOV AX, DATA                    ; ONCE SET, NO CHANGE!
        MOV DS, AX
        MOV AX, 0B800H
        MOV ES, AX    
        CALL STORE_SCREEN
        
        CALL WELCOME
        CMP STATUS, 3
        JE PRE_EXIT

        CALL DRAW_BOARD
        CALL DRAW_ME
        CALL DRAW_HEART
        CALL DRAW_FRAME
        CALL DRAW_LED
        CALL SHOW_MSG
        CALL DRAW_SMILE
        JMP DRAW

    PRE_EXIT:
        JMP EXIT

    DRAW:
        MOV AH, 06                            ; INPUT KEY
        MOV DL, 0FFH
        INT 21H
        CMP AL, 'A'                        ; MOV LEFT
        JE MOVL
        CMP AL, 'a'
        JE MOVL
        CMP AL, 'D'                        ; MOV RIGHT
        JE MOVR
        CMP AL, 'd'
        JE MOVR
        CMP AL, 'Q'                            ; QUIT
        JE EXIT
        CMP AL, 'q'
        JE EXIT
        JMP CONT
    MOVL:
        CALL MOVE_LEFT
        JMP CONT
    MOVR:
        CALL MOVE_RIGHT
        JMP CONT
    CONT:
;        CALL PAUSE
        CALL CLEAR_SCREEN
        CALL UPDATE_BOARD
        CALL UPDATE_ME
        
        CMP STATUS, 0
        JE CALL_CONT
        CMP STATUS, 1
        JNE CALL_LOSE
        CALL WIN
        JMP EXIT
    CALL_LOSE:
        CALL LOSE
        JMP EXIT
        
    CALL_CONT:
        CALL UPDATE_HEART
        CALL JUDGE_POS
        CALL EAT_HEART
        CALL DRAW_BOARD
        CALL DRAW_ME
        CALL DRAW_HEART
        CALL DRAW_FRAME
        CALL SHOW_MSG
        CALL DRAW_LED
        JMP DRAW

    EXIT:
        CALL RECOVER_SCREEN
        MOV AX, 4C00H
        INT 21H

PAUSE PROC NEAR
        PUSH CX
        PUSH DX
        PUSH AX

        MOV AH, 86H
        MOV CX, 05H               ; HIGH
        MOV DX, 0H            ; LOW
        INT 15H

        POP AX
        POP DX
        POP CX
        RET
PAUSE ENDP

STORE_SCREEN PROC NEAR
        PUSH AX
        PUSH SI
        PUSH CX
        PUSH DI
        PUSH ES
        PUSH DS

        MOV AH, 03H                ; STORE MOUSE POSITION
        INT 10H
        MOV MOUSE_POS, DX
        
        MOV AX, DATA
        MOV ES, AX
        MOV AX, 0B800H
        MOV DS, AX
        XOR SI, SI
        MOV AX, OFFSET SCREEN
        MOV DI, AX
        MOV CX, 25*80
        REP MOVSW

        POP DS
        POP ES
        POP DI
        POP CX
        POP SI
        POP AX
        RET
STORE_SCREEN ENDP

CLEAR_SCREEN PROC NEAR
        PUSH AX
        PUSH SI
        PUSH CX
        PUSH DI
                
        MOV CX, 25*80
        XOR DI, DI
        MOV AH, 0FH
        MOV AL, ' '
        REP STOSW

        POP DI
        POP CX
        POP SI
        POP AX
        RET
CLEAR_SCREEN ENDP

RECOVER_SCREEN PROC NEAR
        PUSH AX
        PUSH SI
        PUSH CX
        PUSH DI
                
        MOV AX, OFFSET SCREEN
        MOV SI, AX
        XOR DI, DI
        MOV CX, 25*80
        REP MOVSW
        
        MOV DX, MOUSE_POS            ; RECOVER MOUSE POSITION
        MOV AH, 02H
        INT 10H
                
        POP DI
        POP CX
        POP SI
        POP AX
        RET
RECOVER_SCREEN ENDP

DRAW_ME PROC NEAR
        PUSH AX
        PUSH BX
        PUSH SI
        PUSH CX
        PUSH DI
                
        MOV AX, MY_Y                                    ; CALCULATE MY OFFSET
        MOV BX, 160
        MUL BX
        MOV CX, MY_X
        SHL CX, 1
        ADD AX, CX  
        MOV DI, AX
        MOV BYTE PTR ES:[DI], 1                                  ; SMILING FACE
        ADD DI, 1
        MOV BYTE PTR ES:[DI], 0FH
        
        POP DI
        POP CX
        POP SI
        POP BX
        POP AX
                RET
DRAW_ME ENDP

MOVE_LEFT PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        
        MOV BX, STEP_LEN
        XOR CX, CX
        MOV AX, MY_X
    ML_LP:
        CMP AX, LEFT_WALL
        JE QL                                 
        SUB AX, 1
        CMP AX, LEFT_WALL
        JGE ML_CONT
        MOV AX, LEFT_WALL
    ML_CONT:
        MOV MY_X, AX
        CALL EAT_HEART
        ADD CX, 1
        CMP CX, BX
        JNE ML_LP
    QL:
        POP CX
        POP BX
        POP AX
        RET
MOVE_LEFT ENDP

MOVE_RIGHT PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        
        MOV BX, STEP_LEN
        XOR CX, CX
        MOV AX, MY_X
    MR_LP:
        CMP AX, RIGHT_WALL
        JE QR                                    ; ALREADY REACHED THE RIGHT SIDE
        ADD AX, 1
        CMP AX, RIGHT_WALL
        JLE MR_CONT
        MOV AX, RIGHT_WALL
    MR_CONT:
        MOV MY_X, AX
        CALL EAT_HEART
        ADD CX, 1
        CMP CX, BX
        JNE MR_LP
    QR:
        POP CX
        POP BX
        POP AX
        RET
MOVE_RIGHT ENDP

DRAW_BOARD PROC NEAR
        PUSH AX
        PUSH BX                    ; STORE BOARD_NUM
        PUSH CX                    ; USED AS COUNTER
        PUSH DX                    
        PUSH DI
        PUSH SI
                
        XOR CX, CX
        MOV BX, BOARD_NUM
        SHL BX, 1
    DB_LP:        
        MOV AX, OFFSET BOARD_Y; CALCULATE THE FIRST OFFSET OF EACH BOARD
        ADD AX, CX                ; CX = CNT   
        MOV SI, AX            
        MOV AX, DS:[SI]            ; AX = BOARD_Y[CNT]
        MOV DX, 160
        MUL DX
        MOV DI, AX
        
        MOV AX, OFFSET BOARD_X
        ADD AX, CX
        MOV SI, AX
        MOV AX, DS:[SI]            ; AX = BOARD_X[CNT]
        SHL AX, 1                    ; MULTIPLY 2
        MOV DX, DI
        ADD DX, AX
        MOV DI, DX                ; DI STORES THE OFFSET
        
        MOV AX, OFFSET BOARD_L
        ADD AX, CX
        MOV SI, AX
        PUSH CX
        MOV CX, DS:[SI]            ; CX = BOARD_L[CNT]
        XOR DX, DX                ; DX: INNER LOOP'S COUNTER
        
    DB_LP_IN:
        MOV BYTE PTR ES:[DI], ' '
        ADD DI, 1
        MOV BYTE PTR ES:[DI],00111000B
        ADD DI, 1
        ADD DX, 1
        CMP DX, CX                ; INNER LOOP
        JNE DB_LP_IN
        
        POP CX
        ADD CX, 2
        CMP CX, BX                ; OUTER LOOP
        JNE DB_LP
                
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DRAW_BOARD ENDP

UPDATE_BOARD PROC NEAR
        PUSH AX
        PUSH BX                    ; STORE BOARD_NUM
        PUSH CX                    ; USED AS COUNTER
        PUSH DX                    ; STORE BOARD_Y[COUNTER]
        PUSH SI
        
        MOV BX, BOARD_NUM
        XOR CX, CX
        MOV AX, OFFSET BOARD_Y
        MOV SI, AX
    UB_LP:
        MOV DX, DS:[SI]
        CMP DX, TOP
        JNE UB_CONT
        MOV DX, BOTTOM                ; ALREADY REACHED THE TOP -> START FROM BOTTOM AGAIN
    UB_CONT:
        SUB DX, 1                ; UPDATE
        MOV DS:[SI], DX
        ADD CX, 1
        ADD SI, 2
        CMP CX, BX
        JNE UB_LP
        
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
UPDATE_BOARD ENDP

CALC_OFFSET PROC NEAR            ; AX: Y, BX: X; RETURN VALUE IN AX
        PUSH AX
        PUSH BX
        MOV BX, 160
        MUL BX
        POP BX
        ADD AX, BX
        POP AX
        RET
CALC_OFFSET ENDP

UPDATE_ME PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        
        MOV AL, SCORE
        CMP AL, HEART_NUM
        JNE UM_START
        MOV STATUS, 1                    ; ALL HEARTS EATEN->WIN
        
    UM_START:
        MOV BX, MY_Y
        CMP BX, TOP
        JE UM_LOSE
        CMP BX, BOTTOM
        JNE UM_NORM
    UM_LOSE:                                ; REACHED THE BOTTOM OR TOP -> LOSE
        MOV STATUS, 2
        ; PRINT "YOU LOSE, LOSER."
        JMP UM_UPDATE
    UM_NORM:        
        MOV DX, ON_BOARD
        CMP DX, 0
        JE UM_FALL
        SUB BX, 1            ; ON BOARD -> GOES UP WITH THE BOARD
        JMP UM_UPDATE
    UM_FALL:
        ADD BX, 1            ; NOT ON BOARD -> FALLS DOWN
    UM_UPDATE:
        MOV MY_Y, BX
        
        POP DX
        POP CX
        POP BX
        POP AX
        RET
UPDATE_ME ENDP

JUDGE_POS PROC NEAR            ; ANY OVERLAPS?
        PUSH AX
        PUSH BX                ; BOARD_NUM
        PUSH CX                ; CNT
        PUSH DX                
        PUSH DI                    ; USED AS TAG
        PUSH SI
        
        MOV BX, BOARD_NUM
        SHL BX, 1
        XOR CX, CX
        XOR DI, DI
    JP_Y:
        MOV AX, OFFSET BOARD_Y
        ADD AX, CX
        MOV SI, AX
        MOV DX, DS:[SI]        ; DX = BOARD_Y[CNT]
        SUB DX, 1
        CMP DX, MY_Y        ; BOARD_Y[CNT] - 1 = MY_Y? ON THE BOARD
        JE JP_X
        ADD DX, 1
        CMP DX, MY_Y        ; BOARD_Y[CNT] = MY_Y? ACTUALLY IN THE BOARD... SHOULD ADJUST IT
        JNE JP_CONT
        MOV DI, 1
    JP_X:
        MOV AX, OFFSET BOARD_X
        ADD AX, CX
        MOV SI, AX
        MOV DX, DS:[SI]        ; DX = BOARD_X_START[CNT]
        CMP DX, MY_X        ; CALCULATE DX - MY_X
        JG JP_CONT            ; MY_X < THE START OF BOARD[CNT]
        MOV AX, OFFSET BOARD_L
        ADD AX, CX
        MOV SI, AX
        MOV AX, DS:[SI]        ; AX = BOARD_L[CNT]
        ADD DX, AX            ; DX = BOARD_X_END[CNT]
        CMP DX, MY_X
        JL JP_CONT            ; MY_X > THE END OF BOARD[CNT]
        MOV AX, 1
        MOV ON_BOARD, AX    ; ON_BOARD = TRUE!
        CMP DI, 1
        JNE JP_END
        MOV AX, MY_Y        ; IN THE BOARD
        SUB AX, 1
        MOV MY_Y, AX
        JMP JP_END

    JP_CONT:
        MOV AX, 0
        MOV ON_BOARD, AX
        ADD CX, 2
        CMP CX, BX
        JNE JP_Y
        
    JP_END:
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
JUDGE_POS ENDP

DRAW_HEART PROC NEAR
        PUSH AX
        PUSH BX                
        PUSH CX                ; CNT
        PUSH DX                
        PUSH DI                
        PUSH SI
        
        XOR CL, CL
        MOV AX, OFFSET HEART_POS
        MOV SI, AX
    DH_LP:
        MOV AX, DS:[SI]
        CMP AX, 1                ; ALREADY BE EATEN
        JE DH_LP_1
        MOV DI, AX
        MOV BYTE PTR ES:[DI], 3
        ADD DI, 1
        MOV BYTE PTR ES:[DI], 00000100B
        ADD DI, 1
    DH_LP_1:
        ADD SI, 2
        ADD CL, 1
        CMP CL, HEART_NUM
        JNE DH_LP
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DRAW_HEART ENDP

UPDATE_HEART PROC NEAR
        PUSH AX
        PUSH BX                ; HEART_NUM
        PUSH CX                ; CNT
        PUSH DX                
        PUSH DI                
        PUSH SI
        
        XOR CL, CL
        MOV AX, OFFSET HEART_POS
        MOV SI, AX
    UH_LP:
        MOV AX, DS:[SI]
        CMP AX, 1
        JE UH_CONT
        SUB AX, 160
        CMP AX, 8*160                   ; THE TOP HAS CHANGED
        JGE UH_CONT
        ADD AX, 15*160
    UH_CONT:
        MOV DS:[SI], AX
        ADD SI, 2
        ADD CL, 1
        CMP CL, HEART_NUM
        JNE UH_LP
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
UPDATE_HEART ENDP

EAT_HEART PROC NEAR
        PUSH AX
        PUSH BX                ; HEART_NUM
        PUSH CX                ; CNT
        PUSH DX                
        PUSH DI                
        PUSH SI
        
        MOV AX, MY_Y                                    ; CALCULATE MY OFFSET
        MOV BX, 160
        MUL BX
        MOV CX, MY_X
        SHL CX, 1
        ADD AX, CX  
        MOV MY_POS, AX
        
        XOR CL, CL
        MOV AX, OFFSET HEART_POS
        MOV SI, AX
    EH_LP:
        MOV AX, DS:[SI]
        CMP AX, MY_POS
        JNE EH_CONT
        ADD SCORE, 1
        CALL SOUND                      ; MAKE SOUND HERE
        MOV AX, 1
        MOV DS:[SI], AX                ; MARKED AS BEEN EATEN
        JMP EH_END
    EH_CONT:
        ADD SI, 2
        ADD CL, 1
        CMP CL, HEART_NUM
        JNE EH_LP
    
    EH_END:
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET    
EAT_HEART ENDP        

DRAW_FRAME PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI

        XOR CX, CX              ; DRAW FRAME ON TOP
        MOV AX, TOP
        SUB AX, 1
        MOV DX, 160
        MUL DX
        MOV DI, AX              ; THE STARING OFFSET
    DF_LP:
        MOV BYTE PTR ES:[DI],'#'
        ADD DI, 1
        MOV BYTE PTR ES:[DI], 0FH
        ADD DI, 1
        ADD CX, 1
        CMP CX, 80
        JNE DF_LP
        
        MOV CX, 25                ; DRAW LEFT FRAME
        SUB CX, TOP
        PUSH CX                    ; STORE LOOP TIME IN STACK
        MOV AX, TOP
        SUB AX, 1
        MOV BX, 160
        MUL BX
        PUSH AX                    ; STORE THE VALUE IN STACK
        MOV BX, LEFT_WALL
        SUB BX, 1
        SHL BX, 1
        ADD AX, BX
    DF_LP_L:
        MOV DI, AX
        MOV BYTE PTR ES:[DI],'#'
        ADD DI, 1
        MOV BYTE PTR ES:[DI], 0FH
        ADD AX, 160
        LOOP DF_LP_L
        
        POP AX                    ; DRAW RIGHT WALL
        POP CX
        MOV BX, RIGHT_WALL
        ADD BX, 1
        SHL BX, 1
        ADD AX, BX
    DF_LP_R:
        MOV DI, AX
        MOV BYTE PTR ES:[DI],'#'
        ADD DI, 1
        MOV BYTE PTR ES:[DI], 0FH
        ADD AX, 160
        LOOP DF_LP_R
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DRAW_FRAME ENDP

DRAW_LED PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        
        ; UPPER HALF
        XOR CX, CX                      ; CNT
        MOV AX, TOP
        SUB AX, 1
        MOV BX, 160
        MUL BX
        MOV BX, LEFT_WALL
        SHL BX, 1
        ADD AX, BX
        MOV STARTING_POS, AX             ; DI STORES THE STARTING OFFSET
    DL_LP:
        XOR DX, DX                      ; DL STORE THE RESULT, DH IS THE COUNTER IN THE INNER LOOP
        MOV AX, STARTING_POS
        MOV BX, CX
        PUSH CX
        MOV CL, 3
        SHL BX, CL                        ; CHOOSE A COLUMN EVERY 4 COL, EACH COL 2 BYTES
        POP CX
        ADD AX, BX
        MOV DI, AX                      ; DI IS THE OFFSET OF THE COLUMN THIS TIME
    DL_IN_LP:
        MOV AL, ES:[DI]
        CMP AL, 3
        JE DL_UPDATE
        CMP AL, 1
        JNE DL_IN_CONT
    DL_UPDATE:
        PUSH CX
        MOV AH, 0
        MOV AL, DH
        MOV CX, 7
        SUB CX, AX
        MOV AX, 1
        SHL AX, CL
        OR DL, AL
        POP CX
    DL_IN_CONT:
        ADD DI, 160
        ADD DH, 1
        CMP DH, 8
        JNE DL_IN_LP
        MOV AX, OFFSET SCR_UPPER        ; STORE DL TO MEMORY  
        ADD AX, CX
        MOV SI, AX
        MOV DS:[SI], DL
    DL_CONT:
        ADD CX, 1
        CMP CX, 16
        JNE DL_LP
        
        ; LOWER HALF
        XOR CX, CX                      ; CNT
        ADD STARTING_POS, 8*160
    DL_H_LP:
        XOR DX, DX                      ; DL STORE THE RESULT, DH IS THE COUNTER IN THE INNER LOOP
        MOV AX, STARTING_POS
        MOV BX, CX
        PUSH CX
        MOV CL, 3
        SHL BX, CL                        ; CHOOSE A COLUMN EVERY 4 COL, EACH COL 2 BYTES
        POP CX
        ADD AX, BX
        MOV DI, AX                      ; DI IS THE OFFSET OF THE COLUMN THIS TIME
    DL_H_IN_LP:
        MOV AL, ES:[DI]
        CMP AL, 3
        JE DL_H_UPDATE
        CMP AL, 1
        JNE DL_H_IN_CONT
    DL_H_UPDATE:
        PUSH CX
        MOV AH, 0
        MOV AL, DH              ; SHOULD USE DH AS COUNTER
        MOV CX, 7
        SUB CX, AX
        MOV AX, 1
        SHL AX, CL
        OR DL, AL
        POP CX
    DL_H_IN_CONT:
        ADD DI, 160
        ADD DH, 1
        CMP DH, 8
        JNE DL_H_IN_LP
        MOV AX, OFFSET SCR_LOWER        ; STORE DL TO MEMORY  
        ADD AX, CX
        MOV SI, AX
        MOV DS:[SI], DL
    DL_H_CONT:
        ADD CX, 1
        CMP CX, 16
        JNE DL_H_LP

        MOV DX, 0E4BBH
        MOV AL, 80H
        OUT DX, AL
        MOV BX, 0H
        XOR CX, CX
    DL_S0:
        MOV DX, 0E4B8H
        MOV AX, OFFSET SCR_LOWER
        ADD AX, BX
        MOV SI, AX
        MOV AL, DS:[SI]
        OUT DX, AL

        MOV DX, 0E4B9H
        MOV AX, OFFSET SCR_UPPER
        ADD AX, BX
        MOV SI, AX
        MOV AL, DS:[SI]
        OUT DX, AL

        MOV DX, 0E4BAH
        MOV AL, BL
        OUT DX, AL                      ; CHOOSE COLUMN

        MOV AH, 86H                     ; PAUSE TO LIT UP
        PUSH CX
        MOV CX, 0
        MOV DX, 90H
        INT 15H
        POP CX

        ADD BL, 1
        CMP BL, 16
        JNZ DL_S0_CONT
        MOV BL, 0

    DL_S0_CONT:
        ADD CX, 1
        CMP CX, 2000
        JNE DL_S0

        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DRAW_LED ENDP

DRAW_SMILE PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI

        MOV DX, 0E4BBH
        MOV AL, 80H
        OUT DX, AL
        MOV BX, 0H
        XOR CX, CX
    DS_LP:
        MOV DX, 0E4B8H
        MOV AX, OFFSET SMILE_LOWER
        ADD AX, BX
        MOV SI, AX
        MOV AL, DS:[SI]
        OUT DX, AL

        MOV DX, 0E4B9H
        MOV AX, OFFSET FACE_UPPER
        ADD AX, BX
        MOV SI, AX
        MOV AL, DS:[SI]
        OUT DX, AL

        MOV DX, 0E4BAH
        MOV AL, BL
        OUT DX, AL                      ; CHOOSE COLUMN

        MOV AH, 86H                     ; PAUSE TO LIT UP
        PUSH CX
        MOV CX, 0
        MOV DX, 90H
        INT 15H
        POP CX

        ADD BL, 1
        CMP BL, 16
        JNZ DS_CONT ; DS_KEY
        MOV BL, 0

    ;DS_KEY:
        ;MOV AH, 1
        ;INT 16H
        ;JZ DS_LP
    DS_CONT:
        ADD CX, 1
        CMP CX, 4000
        JNE DS_LP

        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DRAW_SMILE ENDP

DRAW_CRY PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI

        MOV DX, 0E4BBH
        MOV AL, 80H
        OUT DX, AL
        MOV BX, 0H
        XOR CX, CX
    DC_LP:
        MOV DX, 0E4B8H
        MOV AX, OFFSET CRY_LOWER
        ADD AX, BX
        MOV SI, AX
        MOV AL, DS:[SI]
        OUT DX, AL

        MOV DX, 0E4B9H
        MOV AX, OFFSET FACE_UPPER
        ADD AX, BX
        MOV SI, AX
        MOV AL, DS:[SI]
        OUT DX, AL

        MOV DX, 0E4BAH
        MOV AL, BL
        OUT DX, AL                      ; CHOOSE COLUMN

        MOV AH, 86H                     ; PAUSE TO LIT UP
        PUSH CX
        MOV CX, 0
        MOV DX, 90H
        INT 15H
        POP CX

        ADD BL, 1
        CMP BL, 16
        JNZ DC_CONT
        MOV BL, 0

    ;DS_KEY:
        ;MOV AH, 1
        ;INT 16H
        ;JZ DC_LP
    DC_CONT:
        ADD CX, 1
        CMP CX, 4000
        JNE DC_LP

        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DRAW_CRY ENDP

SOUND PROC NEAR  
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV NUM,0          
        MOV CX,15             
L1:        MOV SI,0
L2:        MOV AL,DATA1[SI]     ; GET SIN()
        MOV DX,0E490H
        OUT DX,AL            
        CALL DELAY           
        INC SI
        CMP SI,32           ; ALL 32 NUMBERS FETCHED?
        JL L2              
        LOOP L1            ; LOOP FOR 60 TIMES
		
		POP SI
		POP DI
		POP DX
		POP CX
        POP BX
        POP AX
        RET
    
SOUND ENDP

DELAY PROC NEAR 
CCC:    MOV BX,OFFSET TIME
        MOV DX,0E483H          ; SET 8253 TUNNEL0 TO WORK IN WAY0
        MOV AL,10H
        OUT DX,AL
        MOV DX,04E8BH          ; INPUT FOR 8255A
        MOV AL,9BH
        OUT DX,AL
        MOV AL,NUM          
        XLAT
        MOV DX,0E480H
        OUT DX,AL            ; OUTPUT FOR 8253 TUNNEL0
KKK:    MOV DX,0E488H
        IN  AL,DX            ; READ FROM 8255A
        TEST AL,01           ; PA1 PORT == 1?
        JZ  KKK              
        RET                  
DELAY  ENDP

SHOW_MSG PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        
        MOV DH, 2
        MOV DL, 10
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_NAME
        MOV AH, 09H
        INT 21H

        MOV DH, 3
        MOV DL, 10
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_VERSION
        MOV AH, 09H
        INT 21H

        MOV DH, 4H
        MOV DL, 10
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_AUTHOR
        MOV AH, 09H
        INT 21H

        MOV DH, 5H
        MOV DL, 10
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_SCHOOL
        MOV AH, 09H
        INT 21H

        MOV DH, 4
        MOV DL, 40
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_SCORE
        MOV AH, 09H
        INT 21H
        
        MOV DH, 4
        MOV DL, 50
        MOV AH, 02H
        INT 10H
        CALL DISP
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
SHOW_MSG ENDP

DISP PROC
        PUSH AX
        PUSH DX
        PUSH CX
        
        MOV CH, SCORE
        CMP CH, 9
        JG D1
        MOV AL, 0
        JMP NUMH
    D1:
        MOV AL, 1
        SUB CH, 10
    NUMH:
        MOV DL, AL
        ADD DL, 30H
        MOV AH, 02H
        INT 21H

    NUML:
        MOV DL, CH
        ADD DL, 30H
        MOV AH, 02H
        INT 21H

        POP CX
        POP DX
        POP AX
        RET
DISP ENDP

LOSE PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI

        CALL CLEAR_SCREEN
        XOR SI, SI
    L_LP:
        CALL CLEAR_SCREEN

        MOV DH, 4
        MOV DL, 20
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_FINALSCORE
        MOV AH, 09H
        INT 21H

        MOV DH, 4
        MOV DL, 46
        MOV AH, 02H
        INT 10H
        CALL DISP

        MOV DH, RAND_POS_Y[SI]
        MOV DL, RAND_POS_X[SI]
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_LOSE
        MOV AH, 09H
        INT 21H
        
        CALL DRAW_CRY
       ; CALL PAUSE
        INC SI
        CMP SI, RAND_POS_NUM
        JNE L_KEY
        MOV SI, 0
        
    L_KEY:                                        ; QUIT WHEN KEY PRESSED
        MOV AH, 1
        INT 16H
        JZ L_LP
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
LOSE ENDP

WIN PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI

        CALL CLEAR_SCREEN
        XOR SI, SI
    W_LP:
        CALL CLEAR_SCREEN

        MOV DH, 4
        MOV DL, 20
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_FINALSCORE
        MOV AH, 09H
        INT 21H

        MOV DH, 4
        MOV DL, 46
        MOV AH, 02H
        INT 10H
        CALL DISP
        MOV DH, RAND_POS_Y[SI]
        MOV DL, RAND_POS_X[SI]
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_WIN
        MOV AH, 09H
        INT 21H

        MOV DH, RAND_POS_Y[SI]
        MOV DL, RAND_POS_X[SI]
        ADD DH, 1
        ADD DL, 3
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_WIN1
        MOV AH, 09H
        INT 21H

        CALL DRAW_SMILE
       ; CALL PAUSE
        INC SI
        CMP SI, RAND_POS_NUM
        JNE W_KEY
        MOV SI, 0
        
    W_KEY:                                        ; QUIT WHEN KEY PRESSED
        MOV AH, 1
        INT 16H
        JZ W_LP
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
WIN ENDP

WELCOME PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI

        CALL CLEAR_SCREEN
        MOV DH, 5
        MOV DL, 26
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_WELCOME
        MOV AH, 09H
        INT 21H

        MOV DH, 8
        MOV DL, 20
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_GOAL
        MOV AH, 09H
        INT 21H

        MOV DL, 3
        MOV AH, 02H
        INT 21H

        MOV DH, 12
        MOV DL, 0
        MOV AH, 02H
        INT 10H
        MOV DX, OFFSET MSG_INSTRUCTIONS
        MOV AH, 09H
        INT 21H
        
    WC_LP: 
        CALL DRAW_SMILE
       ;CALL PAUSE                                ; START GAME WHEN KEY PRESSED
        MOV AH, 06                            ; INPUT KEY
        MOV DL, 0FFH
        INT 21H
        CMP AL, ' '                        ; MOV LEFT
        JE WC_CONT
        CMP AL, 'Q'
        JE WC_Q
        JMP WC_LP
    WC_Q:
        MOV STATUS, 3
    WC_CONT:   
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
WELCOME ENDP

CODE ENDS
END START
                
