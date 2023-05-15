STACK1          SEGMENT     PARA STACK
STACK_AREA      DW          100H DUP(?)
STACK_BOTTOM    EQU         $ - STACK_AREA
STACK1          ENDS


DATA1           SEGMENT     PARA
NUMBER1         DD          12345678H
NUMBER2         DD          6543ABCDH
ANSWER          DW          4 DUP(0)
DIVIDENT        DW          4 DUP(0)
DEC_STR         DB          19 DUP(0), '$'
NEW_LINE        DB          0DH, 0AH, '$'
DATA1           ENDS


CODE1           SEGMENT     PARA
                ASSUME      CS:CODE1, DS:DATA1, SS:STACK1

MAIN            PROC        FAR
                MOV         AX, STACK1
                MOV         SS, AX
                MOV         SP, STACK_BOTTOM
                MOV         AX, DATA1
                MOV         DS, AX  ; INIT SS SP DS

                MOV         AX, WORD PTR NUMBER1
                MOV         BX, WORD PTR NUMBER2
                MUL         BX
                MOV         ANSWER, AX
                MOV         SI, DX  ; SI 暂存

                MOV         AX, WORD PTR NUMBER1+2
                MUL         BX
                ADD         AX, SI
                ADC         DX, 0
                MOV         ANSWER+2, AX
                MOV         ANSWER+4, DX

                MOV         AX, WORD PTR NUMBER1
                MOV         BX, WORD PTR NUMBER2+2
                MUL         BX 
                ADD         ANSWER+2, AX
                ADC         DX, 0
                XOR         CX, CX  ; CLEAR CX
                ADC         CX, 0   ; 记录CF
                MOV         SI, DX
                
                MOV         AX, WORD PTR NUMBER1+2
                MUL         BX  ; 会影响CF，所以前面的CF得存
                ADD         AX, SI
                ADC         DX, 0   ; 补上进位
                ADD         ANSWER+4, AX
                ADC         DX, 0   ; 再次补上进位
                ADD         DX, CX
                MOV         ANSWER+6, DX

                ; 用十六进制打印
                MOV         CX, 4
                MOV         DI, OFFSET ANSWER+6
LP1:            MOV         BX, [DI]
                CALL        PRINT_HEX
                DEC         DI
                DEC         DI
                LOOP        LP1

                ; 换行
                MOV         DX, OFFSET NEW_LINE
                MOV         AH, 09H
                INT         21H

                ; 用十进制打印（内存中操作）
                MOV         DI, OFFSET DIVIDENT
                MOV         SI, OFFSET ANSWER
                MOV         CX, 4
LP_MOVE:        MOV         AX, [SI]
                MOV         [DI], AX
                INC         DI
                INC         DI
                INC         SI
                INC         SI
                LOOP        LP_MOVE
                CALL        PRINT_DEC
                
EXIT:           MOV         AX, 4C00H
                INT         21H
MAIN            ENDP

; PRINT_HEX(BX) 将BX中的值以十六进制打出
PRINT_HEX       PROC
                PUSH        AX
                PUSH        CX
                PUSH        DX

                MOV         CX, 4
LP2:            PUSH        CX
                MOV         CL, 4
                ROL         BX, CL
                MOV         AL, BL
                AND         AL, 0FH
                ADD         AL, 30H
                CMP         AL, 39H
                JBE         DISPLAY1
                ADD         AL, 'A'-'9'-1 ; 'A'~'F'
DISPLAY1:       MOV         DL, AL
                MOV         AH, 2
                INT         21H
                POP         CX
                LOOP        LP2

                POP         DX
                POP         CX
                POP         AX
                RET
PRINT_HEX       ENDP

; PRINT_DEC() 将DIVIDENT中内容转换为十进制并存入DEC_STR中,然后打印
PRINT_DEC       PROC
                PUSH        AX
                PUSH        BX
                PUSH        CX
                PUSH        DX
                PUSH        SI
                PUSH        DI

                MOV         BX, 10
                MOV         CX, 19
                MOV         SI, OFFSET DEC_STR+18

LP_DIV:         PUSH        CX
                MOV         CX, 4
                MOV         DI, OFFSET DIVIDENT+6
                XOR         DX, DX
LP_PART_DIV:    MOV         AX, [DI]
                DIV         BX  ; DX:AX / src(BX) = AX ... DX
                MOV         [DI], AX ; quotient
                ; DX can be directly used in next DIV
                DEC         DI  
                DEC         DI 
                LOOP        LP_PART_DIV
                ; now DL is the final quotient of a full div
                OR          DL, 30H ; change to '0'-'9', also ADD 30H 
                MOV         [SI], DL
                DEC         SI
                POP         CX
                LOOP        LP_DIV

                MOV         DX, OFFSET DEC_STR
                MOV         AH, 09H
                INT         21H

                POP         DI
                POP         SI
                POP         DX
                POP         CX
                POP         BX
                POP         AX
                RET
PRINT_DEC       ENDP

CODE1           ENDS

                END         MAIN