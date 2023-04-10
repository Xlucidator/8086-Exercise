stack1 segment para stack
    stack_area   dw  100h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    input_str db  30, ?, 30 dup('$')
    tar_char  db  '#'   ; 待查找字符，放入al
    next_line db  0dh, 0ah, '$'
    result    db  5 dup(?), '$'
data1 ends


GET_STR macro   ; 字符串offset存在dx中
    mov ah, 0ah
    int 21h
endm

PRINT_STR macro ; 字符串offset存在dx中
    mov ah, 09h
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

    ; 读入input_str
    lea dx, input_str
    GET_STR

    ; 换行
    lea dx, next_line
    PRINT_STR
    
    ; 查找al中字符出现的次数
    lea di, input_str+2
    xor ch, ch
    mov cl, byte ptr input_str+1
    mov al, byte ptr tar_char
    call Find

    ; 打印次数
    call PrintReg

    exit:
    mov ax, 4c00h
    int 21h
Main endp

; Find(di, cx, al) 从di开始的长为cx的字符串中，查找al字符出现的次数，由ax返回
Find proc
    push bx
    
    xor bx, bx
lp_cmp:
    scasb
    jnz continue ; 不等于al：跳走，bx不加1
    add bx, 1
continue:
    loop lp_cmp

    mov ax, bx
    pop bx
    ret
Find endp

; PrintReg(ax) 将ax以十进制打印出，忽略前导零
PrintReg proc
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
PrintReg endp

code1 ends

end Main
