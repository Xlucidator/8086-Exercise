stack1 segment para stack
    stack_area   dw  100h dup(?)
    stack_bottom equ $ - stack_area
stack1 ends


data1 segment para
    buffer     db 16 dup(0)
    si_store   dw ?
    di_store   dw ?
    new_line   db 0dh, 0ah, '$'
    sentence1  db '[before sort]', 0dh, 0ah, '$'
    sentence2  db '[after sort]', 0dh, 0ah, '$'
    sentence3  db '[after insert]', 0dh, 0ah, '$'

    my_word    db 16, ?, 16 dup('$'), 12 dup(0)

    list_len   dw 6
    words_list db 9, 'crescent','$'
               db 12, 'attenuation', '$'
               db 8, 'persona','$'
               db 4, 'ebb','$'
               db 9, 'yachting','$'
               db 9, 'paradigm','$'
    next_word_off  equ $ - words_list
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

; cx = addrReg所指处1byte的单词长度
CX_WORDLEN macro addrReg ; 仅影响cx
    mov cl, [addrReg]
    xor ch, ch ;清理除高位
endm

; MOVE_WORDS(src, dst) 将src处的单词移至dst处
MOVE_WORDS macro src, dst ; 影响si,di,cx
    mov si, src
    mov di, dst
    CX_WORDLEN si
    inc cx  ; 还有 单词长度 1byte
    rep movsb
endm

; 主程序
Main proc far
    mov ax, data1
    mov ds, ax
    mov es, ax
    mov ax, stack1
    mov ss, ax
    mov sp, stack_bottom

    ; == 排序前打印 ==
    lea dx, sentence1
    PRINT_STR
    call PrintWordsList

    ; 单词表排序
    call SortWordsList

    ; == 排序后打印 ==
    lea dx, sentence2
    PRINT_STR
    call PrintWordsList

    ; 输入自定义单词，并修改为单词格式
    lea dx, my_word
    GET_STR
    mov cl, my_word + 1
    inc cl
    mov my_word + 1, cl   ; 修改输入长度，使其包括'\n'
    xor ch, ch
    lea si, my_word + 1
    add si, cx
    mov [si], '$'   ; 将'\n'替换未'$'

    ; 将自定义单词添加到单词表末尾
    lea si, my_word + 1
    lea di, words_list + next_word_off
    MOVE_WORDS si, di
    mov ax, list_len ; list_len增加1
    inc ax
    mov list_len, ax

    ; 单词表再次排序
    call SortWordsList

    ; == 插入后打印 ==
    lea dx, sentence3
    PRINT_STR
    call PrintWordsList

    exit:
    mov ax, 4c00h
    int 21h
Main endp

; CompareAndExchange(si, di) 按字典序比较si和di处的单词串，若反序则交换位置，并修改bx=1表明发生交换
CompareAndExchage proc
    push cx

    mov si_store, si
    mov di_store, di
    CX_WORDLEN si ; 任意均可，本身长度就包含'$'结尾，先遇到结尾'$'的必定小
    inc si
    inc di
    repz cmpsb

    jna exchange_end ; ≤，不用交换，跳出

    or bx, 1h ; 标志：发生交换
    
    ; 1.将前（原si处）单词串移至buffer中
    lea di, buffer
    MOVE_WORDS si_store, di
    
    ; 2.将后（原di处）单词串移至前单词串处（原si处）
    MOVE_WORDS di_store, si_store
    
    ; 3.将前（原si处）单词串紧跟到其后
    mov dx, di       ; 标志：下一轮次比较的位置
    lea si, buffer
    MOVE_WORDS si, di
    jmp return1

    exchange_end:
    mov dx, di_store ; 标志：下一轮次比较的位置
    jmp return1

    return1:
    pop cx
    ret
CompareAndExchage endp

; SortWordList() 单词表排序。由于单词开头不好定位，使用了包含冗余轮次的冒泡（每次从头开始直到没有交换）
SortWordsList proc
    push bx
    push cx
    push si
    push di

lp_sort:
    lea si, words_list
    and bx, 0h ; 标志，若该轮未发生交换，则排序完成
    
    mov cx, list_len
    dec cx  ; 小轮次: list_len-1
lp_buble:
    push cx ; 保存循环变量
    mov di, si
    CX_WORDLEN di
    add di, cx ; 根据 单词长度 进行偏移
    inc di     ; 找到下一个单词的位置
    call CompareAndExchage ; (si, di) -> bx, dx
    mov si, dx ; 下一轮次的si
    pop cx  ; 弹出循环变量
    loop lp_buble

    cmp bx, 1 ; 小轮次中，若发生交换，bx=1 -> zf = 1
    jz lp_sort

    pop di
    pop si
    pop cx
    pop bx
    ret
SortWordsList endp

; PrintWordsList() 打印
PrintWordsList proc ; 还会影响ax
    push cx
    push dx
    push si

    lea si, words_list
    mov cx, list_len
lp_browse:
    push cx
    CX_WORDLEN si ; cx 获得 单词长度
    inc si  ; 略过 单词长度
    mov dx, si
    PRINT_STR
    mov dl, ' ' ; 单词间隔
    PRINT_CHAR
    add si, cx ; 移到下一个单词处
    pop cx
    loop lp_browse

    ; 换行
    lea dx, new_line
    PRINT_STR

    pop si
    pop dx
    pop cx
    ret
PrintWordsList endp

code1 ends

end Main


    ; ; 1.将前（原si处）单词串移至buffer中
    ; mov si, si_store
    ; mov di, offset buffer
    ; CX_WORDLEN si
    ; inc cx  ; 还有 单词长度 1byte
    ; rep movsb
    ; ; 2.将后（原di处）单词串移至前单词串处（原si处）
    ; mov si, di_store
    ; mov di, si_store
    ; CX_WORDLEN si
    ; inc cx  ; 还有 单词长度 1byte
    ; rep movsb
    ; ; 3.将前（原si处）单词串紧跟到其后
    ; mov si, offset buffer
    ; mov di, di
    ; CX_WORDLEN si
    ; inc cx  ; 还有 单词长度 1byte
    ; rep movsb
