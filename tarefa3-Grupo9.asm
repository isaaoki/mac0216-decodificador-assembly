; Esqueleto NASM x86-64 Linux

global _start
global escreve_string
global le_string    
global le_byte_arquivo
global grava_string_arquivo
global gera_string_hexadecimal

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
    ; Solicitar o nome do arquivo, chamando escreve_string(msg_entrada)
    push msg_entrada
    call escreve_string
    add rsp, 8 ; 1 parametro = 8byte

    ; Ler o nome do arquivo, chamando le_string(nome_entrada, 256)
    push 256
    push nome_entrada
    call le_string
    add rsp, 16 ; 2 parametros= 16bytes

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
    
; Fim provisório
fim_programa:
    mov rax, 60
    xor rdi, rdi
    syscall

; ---------------------------------------------------------------
; escreve_string(char* buffer)
; ---------------------------------------------------------------
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

; ---------------------------------------------------------------
; le_string(char* buffer, int tam_max)
; ---------------------------------------------------------------
le_string:
    push rbp
    mov rbp, rsp
    ;Salvando valores antigos
    push rbx 
    push r12
    push r13

    mov r12, [rbp + 16] ;nome_entrada
    mov r13, [rbp + 24] ;tam_max

    xor rbx, rbx ;Contador de caracteres lidos
.leitura:
    mov rax, r13
    dec rax
    cmp rbx, rax ;tamanho maior que o limite do buffer
    jge .fim

    ;Leitura
    mov rax, 0  
    xor rdi, rdi 
    lea rsi, [r12+rbx] 
    mov rdx, 1
    syscall 

    cmp rax,0 ;fim de arquivo ou erro
    jle .fim

    mov al, byte [r12 + rbx]
    cmp al, 0x0A ;Enter
    je .fim

    inc rbx
    jmp .leitura
    
.fim:
    mov byte [r12+rbx], 0 ;Null no final
    mov rax, rbx ;Retorno da qnt de caracteres

    ;Restaurar as pilhas
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret 

; ---------------------------------------------------------------
; le_byte_arquivo(int descritor_arquivo, char* byte_arq)
; Empilhar byte_arq e depois descritor_arquivo antes do call.
; Retorno: RAX = bytes lidos (1), EOF (0) ou erro (valor negativo).
; ---------------------------------------------------------------
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

; ---------------------------------------------------------------
; grava_string_arquivo(int descritor_arquivo, char* buffer)
; Grava a string (com LF) sem o NUL.
; ---------------------------------------------------------------
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
