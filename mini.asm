; =====================================================================
; MINI CALCULADORA EM ASSEMBLY  (x86-64, Linux, NASM, sem libc)
; Menu: 1) Tabuada  2) Fatorial  3) Fibonacci  0) Sair
; Monta com:  nasm -f elf64 mini.asm -o mini.o && ld mini.o -o mini
; =====================================================================
global _start

%macro imprime 2                ; imprime <rotulo>, <tamanho>
    lea  rsi, [%1]
    mov  edx, %2
    call print
%endmacro

section .data
menu:       db 10, "=== MINI CALCULADORA EM ASSEMBLY ===", 10
            db "1) Tabuada", 10
            db "2) Fatorial (ate 20)", 10
            db "3) Fibonacci (ate 90 termos)", 10
            db "0) Sair", 10
            db "Opcao: "
menu_len    equ $ - menu
pedido:     db "Numero: "
pedido_len  equ $ - pedido
invalido:   db "Entrada invalida.", 10
invalido_len equ $ - invalido
tchau:      db "Ate logo!", 10
tchau_len   equ $ - tchau
xis:        db " x "
igual:      db " = "
bang:       db "! = "
virg:       db ", "
nl:         db 10

section .bss
inbuf:      resb 32
outbuf:     resb 24

section .text

; ---- print: escreve rdx bytes de [rsi] na saida padrao -----------------
print:
    mov  eax, 1                 ; sys_write
    mov  edi, 1                 ; stdout
    syscall
    ret

; ---- print_uint: imprime o inteiro sem sinal em RAX --------------------
print_uint:
    mov  r8d, 10
    lea  rsi, [outbuf + 24]     ; preenche de tras para frente
.loop:
    xor  edx, edx
    div  r8                     ; rax = rax / 10, rdx = resto
    add  dl, '0'
    dec  rsi
    mov  [rsi], dl
    test rax, rax
    jnz  .loop
    lea  rdx, [outbuf + 24]
    sub  rdx, rsi               ; tamanho = fim - inicio
    call print
    ret

; ---- read_uint: le uma linha (byte a byte) e converte para RAX --------
; CF = 1 se a entrada for invalida (vazia, nao numerica ou > 9 digitos)
; EOF sem digitos retorna 0 sem erro (assim o menu encerra com Ctrl+D)
read_uint:
    xor  r9d, r9d               ; acumulador
    xor  r8d, r8d               ; quantidade de digitos
.le:
    xor  eax, eax               ; sys_read de 1 byte
    xor  edi, edi
    lea  rsi, [inbuf]
    mov  edx, 1
    syscall
    test rax, rax
    js   .erro
    jz   .eof
    movzx edx, byte [inbuf]
    cmp  dl, 10                 ; fim da linha
    je   .fim
    sub  dl, '0'
    cmp  dl, 9
    ja   .drena                 ; nao e digito
    imul r9, r9, 10
    add  r9, rdx
    inc  r8d
    cmp  r8d, 9
    ja   .drena
    jmp  .le
.drena:                         ; descarta o resto da linha invalida
    xor  eax, eax
    xor  edi, edi
    lea  rsi, [inbuf]
    mov  edx, 1
    syscall
    test rax, rax
    jle  .erro
    cmp  byte [inbuf], 10
    jne  .drena
.erro:
    stc
    ret
.eof:
    test r8d, r8d
    jnz  .fim
    xor  eax, eax
    clc
    ret
.fim:
    test r8d, r8d
    jz   .erro
    mov  rax, r9
    clc
    ret

; ---- pedir: mostra "Numero: " e le a resposta -------------------------
pedir:
    imprime pedido, pedido_len
    call read_uint
    ret

; =====================================================================
_start:
.menu:
    imprime menu, menu_len
    call read_uint
    jc   .inv
    cmp  rax, 0
    je   .sair
    cmp  rax, 1
    je   .tab
    cmp  rax, 2
    je   .fat
    cmp  rax, 3
    je   .fib
.inv:
    imprime invalido, invalido_len
    jmp  .menu

; ---- 1) Tabuada --------------------------------------------------------
.tab:
    call pedir
    jc   .inv
    mov  r12, rax               ; n
    mov  r13d, 1                ; i
.tl:
    mov  rax, r12
    call print_uint
    imprime xis, 3
    mov  rax, r13
    call print_uint
    imprime igual, 3
    mov  rax, r12
    imul rax, r13
    call print_uint
    imprime nl, 1
    inc  r13
    cmp  r13, 10
    jbe  .tl
    jmp  .menu

; ---- 2) Fatorial -------------------------------------------------------
.fat:
    call pedir
    jc   .inv
    cmp  rax, 20                ; 21! estoura 64 bits
    ja   .inv
    mov  r12, rax               ; guarda n para exibir
    mov  rcx, rax
    mov  eax, 1
.fl:
    cmp  rcx, 1
    jbe  .fd
    imul rax, rcx
    dec  rcx
    jmp  .fl
.fd:
    mov  r13, rax
    mov  rax, r12
    call print_uint
    imprime bang, 4
    mov  rax, r13
    call print_uint
    imprime nl, 1
    jmp  .menu

; ---- 3) Fibonacci ------------------------------------------------------
.fib:
    call pedir
    jc   .inv
    cmp  rax, 90                ; fib(90) ainda cabe em 64 bits
    ja   .inv
    test rax, rax
    jz   .menu
    mov  r12, rax               ; termos restantes
    xor  r13d, r13d             ; a = 0
    mov  r14d, 1                ; b = 1
.fbl:
    mov  rax, r13
    call print_uint
    dec  r12
    jz   .fbend
    imprime virg, 2
    mov  rax, r13
    add  rax, r14
    mov  r13, r14
    mov  r14, rax
    jmp  .fbl
.fbend:
    imprime nl, 1
    jmp  .menu

; ---- 0) Sair -----------------------------------------------------------
.sair:
    imprime tchau, tchau_len
    mov  eax, 60                ; sys_exit
    xor  edi, edi
    syscall
