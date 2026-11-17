
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
    ; TODO: solicitar e ler nome do arquivo de saída
    ; TODO: abrir arquivos usando abre_arquivo
    ; TODO: loop de leitura byte a byte
    ; TODO: determinar se a sequência UTF-8 possui 1, 2, 3 ou 4 bytes
    ; TODO: combinar bits para reconstruir o code point
    ; TODO: chamar gera_string_hexadecimal e grava_string_arquivo
    ; TODO: fechar os arquivos e encerrar com sys_exit
    jmp fim_programa

bits 64
global le_byte_arquivo
global grava_string_arquivo

section .text

; le_byte_arquivo(int descritor_arquivo, char* byte_arq)
; Empilhar byte_arq e depois descritor_arquivo antes do call.
; Retorno: RAX = bytes lidos (1), EOF (0) ou erro (valor negativo).
le_byte_arquivo:
    push rbp
    mov rbp, rsp

    mov rdi, [rbp + 16] ; parâmetro descritor_arquivo
    ; assume que foi armazenado em rdp +16 o código de descritor.
    mov rsi, [rbp + 24] ; parâmetro endereço de byte_arq
    ; assume que foi armazenado o endereço de byte_arq em rdp+24.
    mov edx, 1 ; ler exatamente um byte
    mov eax, 0 ; sys_read = 0
    syscall

    pop rbp
    ret ; o chamador remove os parâmetros da pilha

grava_string_arquivo:
    push rbp ;
    mov rbp, rsp;
    mov rdi, [rbp + 16] ; parâmetro descritor_arquivo
    mov rsi, [rbp + 24] ; parâmetro endereço do buffer
    mov rdx, 0 ; Começar a contagem com 0 obviamente
.verifica:
    cmp byte [rsi + rdx], 0 ; Verifica se estamos no NUL,
    ; rsi é o endereço inicial do buffer, ele vai verificando um por um com rdx até chegar em nul.
    je .escreve ; Se sim, pula para .esvreve
    add rdx, 1 ; Aumenta contagem, pois não é NUL
    jmp .verifica ; Vai voltar para verifica, que aumenta a contagem.
.escreve:
    mov eax, 1; Para syscall write
    syscall ;
    pop rbp ; rbp toma de volta seu valor
    ret