
; Esqueleto NASM x86-64 Linux

global _start

section .data
    msg_entrada db "Digite o nome do arquivo de entrada: ", 0
    msg_saida   db "Digite o nome do arquivo de saída: ", 0

section .bss
    nome_entrada resb 256
    nome_saida   resb 256
    byte_arq     resb 1
    buffer_hex   resb 16
    descr_entrada resq 1
    descr_saida   resq 1
    code_point    resq 1

section .text

_start:
    ; TODO: solicitar e ler nome do arquivo de entrada
    ; Solicitar o nome do arquivo, chamando escreve_string(msg_entrada)
    push msg_entrada
    call escreve_string
    add rsp, 8 ; 1 parametro = 8byte

    ; Ler o nome do arquivo, chamando le_string(nome_entrada, 256)
    ; push 256
    ; push nome_entrada
    ; call le_string
    ; add rsp, 16 ; 2 parametros= 16bytes


    ; TODO: solicitar e ler nome do arquivo de saída
    ; TODO: abrir arquivos usando abre_arquivo
    ; TODO: loop de leitura byte a byte
    ; TODO: determinar se a sequência UTF-8 possui 1, 2, 3 ou 4 bytes
    ; TODO: combinar bits para reconstruir o code point
    ; TODO: chamar gera_string_hexadecimal e grava_string_arquivo
    ; TODO: fechar os arquivos e encerrar com sys_exit
    ; Colocar de volta dps jmp fim_programa

    ;Teste
    ; push nome_entrada
    ; call escreve_string
    ; add rsp, 8

    mov rax, 60
    xor rdi, rdi
    syscall

global escreve_string

escreve_string:
    push rbp
    mov rbp, rsp
    mov rsi, [rbp + 16]       
    mov rdi, rsi ;auxiliar para contar os caracteres
    ;Contagem de caracteres ate null
    xor rdx, rdx
.conta:
    mov al, byte [rdi + rdx]
    cmp al, 0
    je .escreve
    inc rdx
    jmp .conta

.escreve:
    cmp rdx, 0
    je .fim

    mov rax, 1
    mov rdi, 1
    syscall
.fim:
    mov rsp, rbp
    pop rbp
    ret
