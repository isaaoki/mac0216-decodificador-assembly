
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
    push 256
    push nome_entrada
    call le_string
    add rsp, 16 ; 2 parametros= 16bytes

    ; (Usando para abrir arquivo de saida)
    push 256
    push nome_saida
    call le_string
    add rsp, 16

    ; Abrir os arquivos com função abre_arquivo(nome_entrada, modo_abertura)
    push 0 ; Abrindo arquivo para leitura
    push nome_entrada
    call abre_arquivo
    add rsp, 16

    cmp rax, -1
    je erro ;função global para tratamento de erros 

    

    push 577 ; Abrindo arquivo com flag de criação, escrita e truncamento
    push nome_saida 
    call abre_arquivo
    add rsp, 16

    cmp rax, -1
    je erro




    ; TODO: solicitar e ler nome do arquivo de saída
    ; TODO: abrir arquivos usando abre_arquivo
    ; TODO: loop de leitura byte a byte
    ; TODO: determinar se a sequência UTF-8 possui 1, 2, 3 ou 4 bytes
    ; TODO: combinar bits para reconstruir o code point
    ; TODO: chamar gera_string_hexadecimal e grava_string_arquivo
    ; TODO: fechar os arquivos e encerrar com sys_exit
    jmp fim_programa

    ;Teste
    ; push nome_entrada
    ; call escreve_string
    ; add rsp, 8

    ; mov rax, 60
    ; xor rdi, rdi
    ; syscall

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

global le_string    

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

global abre_arquivo

abre_arquivo:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, [rbp + 16] ; modo de modo_abertura
    mov r13, [rbp + 24] ; nome do arquivo


    cmp r12, 0
    je .abrir

    cmp r12, 577
    je .abrir ; cet = criação, leitura e truncamento
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
        jmp .fim

    .fim:
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        ret

global erro

erro:
    mov rax, 60
    mov rdi, 1 ; função erro genérica
    syscall ; sem mensagens específicas (por enquanto)

        