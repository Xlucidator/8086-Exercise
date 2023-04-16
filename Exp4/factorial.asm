stack1 segment para stack
    stack_area   dw  200h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    new_line db 0dh, 0ah, '$'
    result   db 5 dup(?), '$'
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
PRINT_STR macro
    mov ah, 09h
    int 21h
endm


code1 segment para
    assume cs:code1, ds:data1, es:data1, ss:stack1

; 主函数
main proc far
    INIT_REG

    mov ax, 6
    push ax
    call factorial

    call printReg ; 上次在Exp3:strsearch中写的

    exit:
        mov ax, 4c00h
        int 21h
main endp

; factorial(n) 求n的阶乘
; 参数 - n, 存于栈中
; 返回 - n!, 存于ax中
factorial proc
    push bp
    mov bp, sp
    push bx
    push dx

    mov bx, [bp + 4]

    terminate:
        cmp bx, 0
        jnz recursion
        mov ax, 1
        jmp return1

    recursion:
        dec bx ; bx为n-1，为了压栈
        push bx
        call factorial
        inc bx ; 将bx还原为n
    
    mul bx ; ax * src = dx:ax

    return1:
    pop dx
    pop bx
    pop bp
    ret 2
factorial endp

; printReg(ax) 将ax以十进制打印出，忽略前导零
; 参数 - 存在ax中的值
printReg proc
    push bx
    push cx
    push dx
    push di

    mov cx, 5
    lea di, result+4
    mov bx, 10
    lp_div:
        xor dx, dx
        div bx
        or dl, 30h
        mov [di], dl
        dec di
    loop lp_div

    lea di, result
    ; 去除前导零 clz
    mov cx, 4  ; 前导零不能去完，所以最多去4次
    clear_leading_zero:
        cmp byte ptr [di], '0'  ; 注意byte ptr不要忘记加
        jnz clz_end
        inc di
    loop clear_leading_zero
    clz_end:
        mov dx, di
        PRINT_STR

    pop di
    pop dx
    pop cx
    pop bx
    ret
printReg endp

code1 ends

end main