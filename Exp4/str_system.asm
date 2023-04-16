stack1 segment para stack
    stack_area   dw  200h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    IN_BUF db 34, ?, 34 dup('$')
    ; 直接函数跳转表的话，就没法适配不同的输入参数了
    func_table dw getInput, findChar, strCmp, strCopy, printStr
    new_line db 0dh, 0ah, '$'
    string1 db "I'm origin string, I will concate: ", '$'
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

    exit:
        mov ax, 4c00h
        int 21h
main endp

; function 1
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

; function 2
; find(addr, c) 在addr处的串中查找字符c
; 返回字符c的个数
findChar proc

findChar endp

; function 3
; strCmp(s1, s2) 比较s1和s2的大小
; 
strCmp proc

strCmp endp

; function 4
; strCopy(s1, s2) 将s1处的串复制到s2处
strCopy proc

strCopy endp

; function 5
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