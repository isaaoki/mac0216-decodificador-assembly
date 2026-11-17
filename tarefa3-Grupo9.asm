
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
    push buffer_hex
    push rax
    call gera_string_hexadecimal
    add rsp, 16 ; Libera os argumentos da pilha

    ; TODO: fechar os arquivos e encerrar com sys_exit
    jmp fim_programa

gera_string_hexadecimal:
    ; Recupera parametros e preparar registradores
    push rbp ; Recupera o endereço da função
    mov rbp, rsp ; Salva endereço em RSP
    push rbx ; Preserva RBX 

    mov rax, [rbp+16] ; Recupera o valor
    mov rcx, [rbp+24] ; Recupera o buffer 
    xor r8, r8 ; Guarda contador de divisoes
    xor r9, r9 ; Guarda o indice do buffer

.loop_divisao:
    ; 1. Divide o valor em RAX por 16 repetidamente e extrai os restos
    xor rdx, rdx ; Parte alta do dividendo fica zero (conterá o resto depois)
    mov rbx, 16 ; Guarda o divisor 

    div rbx ; Divide o valor em RAX por 16 (quociente em RAX e resto em RDX)

    push rdx ; Guarda o resto na pilha
    inc r8 ; Incrementa quantidade de divisoes

    cmp rax, 0 ; Verifica se terminou a divisão
    jnz .loop_divisao

    ; 2. Coloca 0x no buffer
    mov byte [rcx+r9], '0'
    inc r9 
    mov byte [rcx+r9], 'x'
    inc r9 

.loop_escrita:
    ; 3. Tira da pilha o valor e converte para dígitos
    cmp r8, 0 ; Verifica se terminou de verificar divisoes
    je .fim_escrita

    pop rdx ; Tira o resto (0 a 15) da pilha

    cmp dl, 9 ; Verifica se número é menor ou igual a 9
    jbe .opcao_numero
    jmp .opcao_digito 

.escreve_buffer:
    ; Escreve o digito no buffer
    mov byte [rcx+r9], dl
    inc r9

    dec r8 
    jmp .loop_escrita 

.opcao_numero:
    add dl, 48 ; Converte para 0 a 9
    jmp .escreve_buffer

.opcao_digito: 
    add dl, 55 ; Converte para A a F
    jmp .escreve_buffer 

.fim_escrita:
    ; Escreve LF e NUL no buffer
    mov byte [rcx+r9], 10 ; Adiciona LF
    inc r9
    mov byte [rcx+r9], 0 ; Adiciona NUL 

    pop rbx
    mov rsp, rbp
    pop rbp 
    ret ; Retorna a função principal start