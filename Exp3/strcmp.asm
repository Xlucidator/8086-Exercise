stack1 segment para stack
    stack_area   dw  100h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    string1   db  "XiabinRui", '$'
    strlen    equ $ - string1 - 1
    string2   db  20, ?, 20 dup('$') ; '$' 比大小写字母、数字都小，所以不会影响比较
    new_line  db  0dh, 0ah, '$'
data1 ends


GET_STR macro   ; 字符串offset存在dx中
    mov ah, 0ah
    int 21h
endm

PRINT_STR macro ; 字符串offset存在dx中
    mov ah, 09h
    int 21h
endm

PRINT_CHAR macro ; 字符存在dl中
    mov ah, 02h
    int 21h
endm


code1 segment para
    assume cs:code1, ds:data1, es:data1, ss:stack1

Main proc far
    mov ax, data1
    mov ds, ax
    mov es, ax
    mov ax, stack1
    mov ss, ax
    mov sp, stack_bottom

    ; 读入string2
    lea dx, string2
    GET_STR

    ; 打印string1
    lea dx, string1
    PRINT_STR

    ; string1和string2比较
    lea si, string1
    lea di, string2+2
    mov cx, strlen
    cld
    repz cmpsb  ; 当前字符相等时，继续比较（cx≠0前）
        ; 比较结束
    jb smaller
    ja larger
        ; 有可能输入string2比string1长
    xor ah, ah
    mov al, byte ptr string2+1 ; 注意是byte
    cmp ax, strlen
    ja smaller ; string2比string1长，最终string1<string2
    jmp equal ; 只有相等的情况了

    smaller:
        mov dl, '<'
        jmp print_result
    larger:
        mov dl, '>'
        jmp print_result
    equal:
        mov dl, '='
    
    print_result:
    PRINT_CHAR

    ; 打印string2
    lea dx, string2+2
    PRINT_STR

    exit:
    mov ax, 4c00h
    int 21h
Main endp


code1 ends

end Main
