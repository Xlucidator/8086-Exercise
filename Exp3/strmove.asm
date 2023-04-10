stack1 segment para stack
    stack_area   dw  100h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    null_str1 db  16 dup("0")
    string1   db  "XiaRuibin"
    strlen    equ $ - string1
    null_str2 db  16 dup('0')
    new_line  db  0dh, 0ah, '$'
data1 ends


PRINT_CHAR macro ; 字符存在dl中
    mov ah, 02h
    int 21h
endm

PRINT_STR  macro ; offset存在dx中
    mov ah, 09h
    int 21h
endm

TEST_ONE_ROUND macro addrOff ; 进行一次操作
    mov si, offset string1 ; 打印string1
    mov cx, strlen
    call PrintStr

    mov dl, ':' ; 打印 ":"
    PRINT_CHAR

    mov si, offset string1 ; 进行MemMove
    mov di, offset string1 + addrOff
    mov cx, strlen
    call MemMove

    mov si, offset string1 ; 打印操作后string1
    mov cx, strlen
    call PrintStr

    mov dl, ',' ; 打印 ","
    PRINT_CHAR
    
    mov si, offset string1 + addrOff ; 打印操作后string2
    mov cx, strlen
    call PrintStr

    lea dx, new_line
    PRINT_STR
endm


code1 segment para
    assume cs:code1, ds:data1, es:data1, ss:stack1

; 主函数
Main proc far
    mov ax, data1
    mov ds, ax
    mov es, ax
    mov ax, stack1
    mov ss, ax
    mov sp, stack_bottom

    TEST_ONE_ROUND strlen+2     ; 第1次: string2和string1不重合
    TEST_ONE_ROUND -strlen+3    ; 第2次: string2在string1前，部分重合
    TEST_ONE_ROUND strlen-4     ; 第3次: string2在string1后，部分重合

    exit:
    mov ax, 4c00h
    int 21h
Main endp

; PrintStr(si, cx) 打印从si开始的cx个字符
PrintStr proc
    push ax
    push dx
    
    lp_print:
    mov dl, [si]
    PRINT_CHAR
    inc si
    loop lp_print

    pop dx
    pop ax
    ret
PrintStr endp

; MemMove(si, di, cx) 将si处的cx个字符移动到di处
MemMove proc
    cld
    rep movsb
    ret
MemMove endp

code1 ends

end Main
