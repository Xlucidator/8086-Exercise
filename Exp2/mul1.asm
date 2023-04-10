STACK1          SEGMENT     PARA STACK
STACK_AREA      DW          100H DUP(?)
STACK_BOTTOM    EQU         $ - STACK_AREA
STACK1          ENDS


DATA1           SEGMENT     PARA
NUMBER          DW          ?, ?, 0, 0
RESULT          DB          0DH, 0AH, 5 DUP(?), 20H, '$'
DATA1           ENDS


CODE1           SEGMENT     PARA
                ASSUME      CS:CODE1, DS:DATA1, SS:STACK1
; 主程序
MAIN            PROC        FAR
                MOV         AX, STACK1
                MOV         SS, AX
                MOV         SP, STACK_BOTTOM
                MOV         AX, DATA1
                MOV         DS, AX  ; INIT SS SP DS
                
                MOV         SI, OFFSET NUMBER
                MOV         CX, 2
                CALL        GETNUM
                MOV         [SI], AX
                MOV         BX, AX
                MOV         CX, 3
                CALL        GETNUM
                MOV         [SI+2], AX

                MUL         BX  ; 结果已经在AX中了
                CALL        PRINTNUM

EXIT:           MOV         AX, 4C00H
                INT         21H
MAIN            ENDP

; GETNUM(CX) 获取输入的一个数, CX为输入数字长度
GETNUM          PROC
                PUSH        SI
                PUSH        DX
                PUSH        BX

                MOV         SI, 0   ; 初值
                MOV         BX, 10  ; 乘数

INPUT_1:        MOV         AH, 1
                INT         21H
                CMP         AL, 0DH ; 回车
                JE          RETURN
                CMP         AL, 30H
                JB          INPUT_1 ; < '0', IGNORED
                CMP         AL, 39H
                JA          INPUT_1 ; > '9', IGNORED
                AND         AL, 0FH ; CHANGE TO REAL NUMBER
                XOR         AH, AH
                PUSH        AX
                MOV         AX, SI
                MUL         BX
                MOV         SI, AX
                POP         AX
                ADD         SI, AX
                LOOP        INPUT_1

RETURN:         MOV         AX, SI
                POP         BX
                POP         DX
                POP         SI
                RET
GETNUM          ENDP

; PRINTNUM(AX) 打印一个数的十进制形式, 该数在AX中
PRINTNUM        PROC
                PUSH        BX
                PUSH        CX
                PUSH        DX
                PUSH        DI

                MOV         CX, 5
                MOV         DI, OFFSET RESULT+6
                MOV         BX, 10
LP1:            XOR         DX, DX
                DIV         BX
                OR          DL, 30H
                MOV         [DI], DL
                DEC         DI
                LOOP        LP1

PRINT_RES:      MOV         DX, OFFSET RESULT
                MOV         AH, 9   ; 用完后AX会变
                INT         21H

RETURN2:        POP         DI
                POP         DX
                POP         CX
                POP         BX
                RET
PRINTNUM        ENDP

CODE1           ENDS

                END         MAIN