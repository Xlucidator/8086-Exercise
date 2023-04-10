STACK           SEGMENT     PARA STACK
STACK_AREA      DW          100H DUP(?)
STACK_BOTTOM    EQU         $ - STACK_AREA
STACK           ENDS


DATA            SEGMENT     PARA
TABLE_LEN       DW          16
TABLE           DW          200, 300, 400, 10, 20, 0, 1, 8
                DW          41H, 40, 2037H, 3585H, 60, 0FFFFH, 2, 3
RESULT          DB          5 DUP(?), 20H, '$'
NEW_LINE        DB          0DH, 0AH, '$'
DATA            ENDS


PRINT_STR       MACRO
                MOV         AH, 09H
                INT         21H
ENDM


CODE            SEGMENT     PARA
                ASSUME      CS:CODE, DS:DATA, SS:STACK


MAIN            PROC        FAR
                MOV         AX, STACK
                MOV         SS, AX
                MOV         SP, STACK_BOTTOM
                MOV         AX, DATA
                MOV         DS, AX  ; init SS SP DS

                CALL        PRINT_TABLE
                CALL        BUBLE_SORT
                CALL        PRINT_TABLE

EXIT:           MOV         AX, 4C00H
                INT         21H
MAIN            ENDP


; 打印TABLE
PRINT_TABLE     PROC        FAR
                PUSH        AX
                PUSH        BX
                PUSH        CX
                PUSH        DX
                PUSH        SI
                PUSH        DI

                MOV         CX, TABLE_LEN
                MOV         SI, OFFSET TABLE

LP_OUT:         PUSH        CX
                MOV         CX, 5   ; 16bit -> max 65536 -> 5 times
                MOV         DI, OFFSET RESULT+4
                MOV         AX, [SI]
                MOV         BX, 10  ; /10

LP_IN_DIV:      XOR         DX, DX  ; clear DX
                DIV         BX
                OR          DL, 30H
                MOV         [DI], DL
                DEC         DI
                LOOP        LP_IN_DIV

                MOV         DX, OFFSET RESULT
                PRINT_STR
                
                INC         SI
                INC         SI
                POP         CX
                LOOP        LP_OUT

                MOV         DX, OFFSET NEW_LINE
                PRINT_STR

                POP         DI
                POP         SI
                POP         DX
                POP         CX
                POP         BX
                POP         AX
                RET
PRINT_TABLE     ENDP


; 冒泡排序
BUBLE_SORT      PROC
                PUSH        AX
                PUSH        BX
                PUSH        CX
                PUSH        SI

                MOV         CX, TABLE_LEN
                DEC         CX

LP_BUBLE_OUT:   MOV         BX, 1   ; FLAG
                MOV         SI, OFFSET TABLE
                PUSH        CX

LP_BUBLE_IN:    MOV         AX, [SI]
                CMP         AX, [SI+2]
                JBE         CONTINUE
                XCHG        AX, [SI+2]
                MOV         [SI], AX
                MOV         BX, 0   ; MARK FLAG
CONTINUE:       ADD         SI, 2
                LOOP        LP_BUBLE_IN

                POP         CX
                DEC         CX
                CMP         BX, 1   ; COMPARE FLAG
                JZ          GO_OUT  ; BX=1 (CMP:ZF=1) means no change applied, so end sort
                JMP         SHORT LP_BUBLE_OUT ; 用了JMP，外层的CX就没啥用了其实
GO_OUT:         NOP

                POP         SI
                POP         CX
                POP         BX
                POP         AX
                RET
BUBLE_SORT      ENDP


CODE            ENDS

                END         MAIN