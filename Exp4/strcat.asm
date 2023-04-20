stack1 segment para stack
    stack_area   dw  100h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    new_line db 0dh, 0ah, '$'
    IN_BUF   db 14, ?, 14 dup('$')
    string1  db "I'm origin string, I will concate: ", '$'
data1 ends


; 初始化 cs, ds, es, ss
INIT_REG macro
    mov ax, data1
    mov ds, ax
    mov es, ax
    mov ax, stack1
    mov ss, ax
    mov sp, stack_bottom
endm

; 字符串offset存在dx中
GET_STR macro   
    mov ah, 0ah
    int 21h
endm

; 字符串offset存在dx中
PRINT_STR macro
    mov ah, 09h
    int 21h
endm


code1 segment para
    assume cs:code1, ds:data1, es:data1, ss:stack1

; 主函数
main proc far
    INIT_REG

    lea si, IN_BUF
    push si
    call getInput

    lea si, IN_BUF  ;参数列表：从右往左压栈
    inc si
    inc si
    push si
    lea si, string1
    push si
    call strConcat

    lea si, string1
    push si
    call printStr

    exit:
        mov ax, 4c00h
        int 21h
main endp

; getInput(IN_BUF) 从键盘输入字符串
; 参数 - IN_BUF首地址
; 返回 - 无
getInput proc 
    push bp
    mov bp, sp
    push dx
                     ; +0   +2   +4
    mov dx, [bp + 4] ; BP | IP | argument
    GET_STR

    ; 换个行，使得输入部分不被覆盖
    lea dx, new_line
    PRINT_STR

    pop dx
    pop bp
    ret 2
getInput endp

; strConcat(s1, s2) 将s2字符串拼接到s1字符串后
; 参数 - s1, s2 地址
; 返回 - 无
strConcat proc
    push bp
    mov bp, sp
    push cx
    push si
    push di

    mov di, [bp + 4] ; 参数s1，基准
    mov si, [bp + 6] ; 参数s2，拼接到基准后

    cld
    ; 找到s1的尾部
    mov cx, 03fh
    mov al, '$'
    repne scasb 
    dec di
    ; 将s2移至s1的尾部（确保无冲突）
    mov cl, byte ptr [si - 1]
    xor ch, ch
    rep movsb
    ; 结尾加上 '$'
    mov byte ptr [di], '$'

    pop di
    pop si
    pop cx
    pop bp
    ret 4
strConcat endp

; printStr(s) 打印s地址上的字符串，'$'终结
; 参数 - s 地址
printStr proc
    push bp
    mov bp, sp
    push dx

    mov dx, [bp + 4] ; 取出s
    PRINT_STR

    pop dx
    pop bp
    ret 2
printStr endp

code1 ends

end main