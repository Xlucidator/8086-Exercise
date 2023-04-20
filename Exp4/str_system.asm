stack1 segment para stack
    stack_area   dw  200h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    input_buf db 30, ?, 30 dup('$')
    ; 直接函数跳转表的话，就没法适配不同的输入参数了
    func_table dw getInput, findChar, strCmp, strCopy, printStr
    
    new_line db 0dh, 0ah, '$'
    start_str db "Enter operate code:", '$'
    end_str   db "Exit system", '$'
    result    db  5 dup(?), '$'
    
    compr_str db 9, "xiaruibin", '$'
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

; 获得的字符串目的位置offset存在dx中
GET_STR macro   
    mov ah, 0ah
    int 21h
endm

; 字符存在dl中
PRINT_CHAR macro
    mov ah, 02h
    int 21h
endm

; 获得的字符放在al中
GET_CHAR macro
    mov ah, 01h
    int 21h
endm


code1 segment para
    assume cs:code1, ds:data1, es:data1, ss:stack1

; 主函数
main proc far
    INIT_REG

    cld

    lp_system:
        ; 获取输入
        lea dx, start_str ; 打印输入提示
        PRINT_STR
        GET_CHAR ; 获取输入字符，写入al
        push ax
        lea dx, new_line ; 打印换行
        PRINT_STR ; 还会影响al，所以要push ax暂存
        pop ax
        ; 处理输入
        and al, 0fh
        cmp al, 0
        je system_out ; =0：退出
        cmp al, 5
        ja lp_system  ; >5: 忽略
        xor ah, ah
        dec ax
        shl ax, 1   ; ×2
        lea bx, func_table
        add bx, ax
        call [bx] ; 跳转到相应函数
    jmp lp_system

    system_out:
        lea dx, end_str
        PRINT_STR

    exit:
        mov ax, 4c00h
        int 21h
main endp

; function 1
; getInput(input_buf) 从键盘输入字符串
; 参数 - input_buf首地址 写死
; 返回 - 无
getInput proc 
    push dx
    push si
    push cx

    lea dx, input_buf
    GET_STR

    ; 处理输入最后多出的\0d回车符问题
    lea si, input_buf + 2
    xor ch, ch
    mov cl, byte ptr input_buf + 1
    add si, cx ; 移到字符串后多出的 \0d回车 处
    ; 1.可以选择再在下一个地方加一个\0a构成回车换行，直接打出
    ; 2.或者此处将\0d改为$结束，打印后在添加换行
    ; 为了可能的鲁棒性和通用性，就选第2种了
    mov byte ptr [si], '$'

    ; 换个行，使得输入部分不被覆盖
    lea dx, new_line
    PRINT_STR

    pop cx
    pop si
    pop dx
    ret
getInput endp

; function 2
; find(addr, c) 在addr处的串中查找字符c
; 写死 c = '#'
; 返回字符c的个数
findChar proc
    push bx

    lea di, input_buf + 2 ; 字符串位置
    xor ch, ch
    mov cl, byte ptr input_buf + 1 ; 字符串长度
    mov al, '#'

    xor bx, bx
    lp_count:
        scasb
        jnz continue
        inc bx
        continue:
    loop lp_count

    mov ax, bx
    call printReg

    mov dl, "#"
    PRINT_CHAR

    lea dx, new_line
    PRINT_STR

    pop bx
    ret
findChar endp

; function 3
; strCmp(s1, s2) 比较s1和s2的大小
; s1 写死 input_buf, s2 写死 compr_str (都得舍去开头的标识符)
strCmp proc
    push cx
    push dx
    push si
    push di

    lea dx, input_buf + 2
    PRINT_STR

    lea si, input_buf + 2
    lea di, compr_str + 1
    xor ch, ch ; 获得conpr_str的长度cx，作为比较的初始长度
    mov cl, byte ptr compr_str 
    push cx
    repz cmpsb ; 相等则继续比较
    pop cx
    jb smaller
    ja bigger
    xor ah, ah ; 获得conpr_str的长度ax
    mov al, byte ptr input_buf + 1
    cmp ax, cx
    ja bigger
    jmp equal
    smaller:
        mov dl, '<'
        jmp print_result
    bigger:
        mov dl, '>'
        jmp print_result
    equal:
        mov dl, '='
    print_result:
        PRINT_CHAR

    lea dx, compr_str + 1
    PRINT_STR

    lea dx, new_line
    PRINT_STR

    pop di
    pop si
    pop dx
    pop cx
    ret
strCmp endp

; function 4
; strCopy(s1, s2) 将s1处的串复制到s2处
; s1写死为input_buf的字符串处，s2写死为compr_str
strCopy proc
    push cx
    push si
    push di

    lea si, input_buf + 1
    lea di, compr_str
    xor ch, ch
    mov cl, byte ptr input_buf + 1
    inc cx ; 带上'$'
    inc cx ; 带上开头的strlen
    rep movsb

    pop di
    pop si
    pop cx
    ret
strCopy endp

; function 5
; printStr(s) 打印s地址上的字符串，'$'终结
; 参数 - s 地址 写死input_buf
printStr proc
    push dx

    lea dx, input_buf + 2 
    PRINT_STR

    lea dx, new_line
    PRINT_STR

    pop dx
    ret
printStr endp

; tool function
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

end main