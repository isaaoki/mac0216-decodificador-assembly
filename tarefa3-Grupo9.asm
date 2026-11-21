; Esqueleto NASM x86-64 Linux

global _start
global escreve_string
global le_string
global abre_arquivo
global fecha_arquivo
global le_byte_arquivo
global grava_string_arquivo
global gera_string_hexadecimal
global erro

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
    ; 1. Solicitar o nome do arquivo de entrada
    push msg_entrada ; 1o parametro (8 bytes)
    call escreve_string
    add rsp, 8 ; Retira parametro da pilha (1 param = 8 bytes)

    ; Ler o nome do arquivo de entrada
    push 256 ; 2o parametro (8 bytes)
    push nome_entrada ; 1o parametro (8 bytes)
    call le_string
    add rsp, 16 ; Retira parametro da pilha (2 param = 16 bytes)

    ; 2. Solicitar o nome do arquivo de saída
    push msg_saida ; 1o parametro (8 bytes)
    call escreve_string
    add rsp, 8 ; Retira parametro da pilha (1 param = 8 bytes)

    ; Ler o nome do arquivo de saída
    push 256 ; 2o parametro (8 bytes)
    push nome_saida ; 1o parametro (8 bytes)
    call le_string
    add rsp, 16 ; Retira parametros da pilha (2 param = 16 bytes)

    ; 3. Abrir os arquivos 
    push 0 ; 2o parametro (abrindo arquivo para leitura)
    push nome_entrada ; 1o parametro (8 bytes)
    call abre_arquivo
    add rsp, 16 ; Retira parametros da pilha (2 param = 16 bytes)
    cmp rax, -1 ; Verifica se houve erro
    je erro
    mov [descr_entrada], rax

    push 577 ; 2o parametro (abrindo arquivo com flag de criação, escrita e truncamento)
    push nome_saida ; 1o parametro (8 bytes)
    call abre_arquivo
    add rsp, 16 ; Retira parametros da pilha (2 param = 16 bytes)
    cmp rax, -1 ; Verifica se houve erro
    je erro
    mov [descr_saida], rax

.proximo_caractere:
    ; 4. Loop de leitura byte a byte do arquivo
    push byte_arq ; 2o parametro (8 bytes)
    push qword [descr_entrada] ; 1o parametro (8 bytes)
    call le_byte_arquivo
    add rsp, 16
    cmp rax, 0 ; Verifica se houve erro ou o arquivo está vazio
    jle fim_programa

    ; 5. Determinar se a sequência UTF-8 possui 1, 2, 3 ou 4 bytes
    mov al, [byte_arq]
    mov bl, al 
    and bl, 10000000b 
    cmp bl, 00000000b
    je .sequencia_possui_1_byte

    mov bl, al 
    and bl, 11100000b 
    cmp bl, 11000000b
    je .sequencia_possui_2_bytes

    mov bl, al 
    and bl, 11110000b 
    cmp bl, 11100000b
    je .sequencia_possui_3_bytes
    jmp .sequencia_possui_4_bytes

; R13: número de bytes - 1 (byte que indica tamanho)
; AL: byte original retirando os primeiros bytes (que indicam tamanho)
.sequencia_possui_1_byte:
    mov r13, 0 
    and al, 01111111b
    jmp .inicio_reconstruir

.sequencia_possui_2_bytes:
    mov r13, 1
    and al, 00011111b 
    jmp .inicio_reconstruir

.sequencia_possui_3_bytes:
    mov r13, 2
    and al, 00001111b
    jmp .inicio_reconstruir

.sequencia_possui_4_bytes:
    mov r13, 3
    and al, 00000111b 
    jmp .inicio_reconstruir

.inicio_reconstruir:
    ; R12 = acumula todos os bits de informação
    movzx r12, al ; Copia valor de AL (8 bits) para R12 (64 bits) preenchendo bits superiores com 0

.reconstruir:
    cmp r13, 0 ; Verifica se terminou de ler bytes
    je .fim_reconstruir
    
    ; Lê próximo byte
    push byte_arq ; 2o parametro (8 bytes)
    push qword [descr_entrada] ; 1o parametro (8 bytes)
    call le_byte_arquivo
    add rsp, 16 ; Retira parametros da pilha

    ; 6. Combinar bits para reconstruir o code point
    movzx rax, byte [byte_arq] ; Coloca byte do arquivo no RAX  preenchendo bits superiores com 0
    and al, 00111111b ; Extrai 6 ultimos bits dos ultimos 8 bits de RAX
    shl r12, 6 ; Abre posições em R12, liberando 6 bits à esquerda
    or r12, rax ; Junta os valores de R12 e RAX
    dec r13 ; Diminui quantidade de bits
    jmp .reconstruir

.fim_reconstruir:
    mov [code_point], r12 ; Salva R12 no code_point

    ; 7. Chama gera_string_hexadecimal e grava_string_arquivo
    push buffer_hex ; 2o parametro (8 bytes)
    push r12 ; 1o parametro (8 bytes)
    call gera_string_hexadecimal
    add rsp, 16 ; Libera os argumentos da pilha

    push buffer_hex ; 2o parametro (8 bytes)
    push qword [descr_saida] ; 1o parametro (8 bytes)
    call grava_string_arquivo
    add rsp, 16 ; Libera os argumentos da pilha

    ; Vai para o próximo caractere do arquivo
    jmp .proximo_caractere

fim_programa:
    ; 8. Fechar os arquivos e encerrar com sys_exit
    push qword [descr_entrada] ; 1o parametro (8 bytes)
    call fecha_arquivo 
    add rsp, 8 ; Retira parametro da pilha
    cmp rax, -1 ; Verifica se houve erros
    je erro
 
    push qword [descr_saida] ; 1o parametro (8 bytes)
    call fecha_arquivo 
    add rsp, 8 ; Retira parametro da pilha
    cmp rax, -1 ; Verifica se houve erros
    je erro

    mov rax, 60 ; sys_exit
    xor rdi, rdi
    syscall

erro:
    mov rax, 60
    mov rdi, 1 ; função erro genérica
    syscall ; sem mensagens específicas (por enquanto)

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
; abre_arquivo(char* nome_arquivo, int modo_abertura)
; ---------------------------------------------------------------
abre_arquivo:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r13, [rbp + 16] ; modo de modo_abertura (2o parametro)
    mov r12, [rbp + 24] ; nome do arquivo (1o parametro)

    cmp r12, 0
    je .abrir
    cmp r12, 577
    je .abrir 
    jmp .fim_erro ; vai para o fim erro já que modo de abertura não está de acordo com o esperado

.abrir:
    mov rax, 2
    mov rdi, r13
    mov rsi, r12
    mov rdx, 438
    syscall
    test rax, rax
    js .fim_erro
    jmp .fim

.fim_erro:
    mov rax, -1

.fim:
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret

; ---------------------------------------------------------------
; fecha_arquivo(int descritor_arquivo)
; ---------------------------------------------------------------
fecha_arquivo:
    push rbp
    mov rbp, rsp
    mov rdi, [rbp+16] ; Descritor do arquivo

    mov rax, 3
    mov rdi, r12
    syscall
    test rax, rax
    js .erro
    xor rax, rax
    jmp .fim

.erro:
    mov rax, -1
.fim:
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
