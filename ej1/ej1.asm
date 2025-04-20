; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

%define offset_next 0
%define offset_previous 8
%define offset_type 16
%define offset_hash 24
%define offset_first 0
%define offset_last 8

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:

    mov rdi, 16
    call malloc
    test rax, rax
    je .fin

    mov qword [rax], 0
    mov qword [rax + 8], 0
.fin:
    ret



string_proc_node_create_asm:
    push rbp
    push rbx
    ;rdi = type
    ;rsi = *hash
    mov rbp, rsp
    mov rbx, rdi;rbx = type
    mov rdi, 32;string_proc_node tiene tamaño de 8*4
    call malloc
    test rax, rax
    je .fin

    mov qword [rax], 0
    mov qword [rax+offset_previous], 0
    mov qword [rax+offset_type], rbx;
    mov qword [rax+offset_hash], rsi

.fin:
    pop rbx
    pop rbp
    ret



string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    mov rbx, rdi; rbx = list
    mov r12, rsi; r12 = type
    mov r13, rdx; r13 = hash
    
    mov rdi, r12; type
    mov rsi, r13; hash
    call string_proc_node_create_asm
    
    test rax, rax
    jz .fin
    
    cmp qword [rbx + offset_first], 0
    jne .not_empty
    mov [rbx + offset_first], rax
    mov [rbx + offset_last], rax
    jmp .fin
    
.not_empty:
    mov rcx, [rbx + offset_last];rcx = old last node
    mov [rax + offset_previous], rcx ;new->prev = old last
    mov [rcx + offset_next], rax;old last->next = new
    mov [rbx + offset_last], rax
    
.fin:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret


string_proc_list_concat_asm:
string_proc_list_concat_asm:
    ; Prologue
    push rbp
    mov rbp, rsp
    push rbx                ; Guardar registros callee-saved
    push r12
    push r13
    push r14

    ; Guardar argumentos en registros preservados
    mov r12, rsi            ; r12 = type
    mov r14, rdx            ; r14 = hash
    xor rbx, rbx            ; rbx = string = NULL
    mov r13, [rdi + offset_first] ; r13 = current_node = list->first

.ciclo:
    test r13, r13           ; ¿current_node == NULL?
    je .fin_ciclo           ; Si es NULL, salir del ciclo

    ; Verificar si current_node->type == type
    cmp byte [r13 + offset_type], r12b
    jne .next_node          ; Si no coincide, pasar al siguiente nodo

    ; Procesar nodo con type coincidente
    test rbx, rbx           ; ¿string == NULL?
    jnz .concatenar         ; Si no es NULL, concatenar

    ; Caso: string == NULL -> asignar nuevo string
    mov rdi, [r13 + offset_hash] ; rdi = current_node->hash
    call my_strlen          ; rax = strlen(hash)
    lea rdi, [rax + 1]      ; rdi = strlen(hash) + 1
    call malloc             ; rax = nuevo string
    test rax, rax           ; ¿malloc falló?
    jz .error               ; Si es NULL, salir con error
    mov rbx, rax            ; rbx = string nuevo
    mov rdi, rax            ; rdi = destino (string)
    mov rsi, [r13 + offset_hash] ; rsi = origen (current_node->hash)
    call my_strcpy          ; Copiar hash al nuevo string
    jmp .next_node          ; Pasar al siguiente nodo

.concatenar:
    ; Caso: string != NULL -> concatenar con current_node->hash
    mov rdi, rbx            ; rdi = string actual
    mov rsi, [r13 + offset_hash] ; rsi = current_node->hash
    call str_concat         ; rax = nuevo string concatenado
    test rax, rax           ; ¿str_concat falló?
    jz .free_and_error      ; Si es NULL, liberar y salir con error
    mov rdi, rbx            ; rdi = string viejo (para free)
    mov rbx, rax            ; rbx = nuevo string
    call free               ; Liberar string viejo

.next_node:
    mov r13, [r13 + offset_next] ; current_node = current_node->next
    jmp .ciclo              ; Continuar ciclo

.fin_ciclo:
    ; Al salir del ciclo, verificar si string sigue siendo NULL
    test rbx, rbx           ; ¿string == NULL?
    jne .chequear_hash      ; Si no es NULL, verificar hash

    ; Caso: string == NULL -> usar hash si no es NULL
    test r14, r14           ; ¿hash == NULL?
    jz .error               ; Si es NULL, retornar NULL

    mov rdi, r14            ; rdi = hash
    call my_strlen          ; rax = strlen(hash)
    lea rdi, [rax + 1]      ; rdi = strlen(hash) + 1
    call malloc             ; rax = nuevo string
    test rax, rax           ; ¿malloc falló?
    jz .error               ; Si es NULL, salir con error
    mov rdi, rax            ; rdi = destino
    mov rsi, r14            ; rsi = origen (hash)
    call my_strcpy          ; Copiar hash al nuevo string
    mov rbx, rax            ; rbx = string nuevo
    jmp .fin                ; Saltar al final

.chequear_hash:
    ; Verificar si hash != NULL para concatenar al inicio
    test r14, r14           ; ¿hash == NULL?
    jz .fin                 ; Si es NULL, no hacer nada

    ; Concatenar hash al inicio del string existente
    mov rdi, r14            ; rdi = hash
    mov rsi, rbx            ; rsi = string actual
    call str_concat         ; rax = nuevo string (hash + string)
    test rax, rax           ; ¿str_concat falló?
    jz .free_and_error      ; Si es NULL, liberar y salir con error
    mov rdi, rbx            ; rdi = string viejo (para free)
    mov rbx, rax            ; rbx = nuevo string
    call free               ; Liberar string viejo
    jmp .fin                ; Saltar al final

.free_and_error:
    ; Liberar string actual y retornar NULL
    mov rdi, rbx
    call free
.error:
    xor rax, rax            ; rax = NULL
.fin:
    ; Epilogue
    mov rax, rbx            ; Devolver string (o NULL)
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret



my_strlen:
    push rbp ; Guardo el viejo RBP
    mov rbp, rsp ; Apuntó el tope de la pila a este nuevo contexto
    xor rax, rax ; Inicializar contador (RAX = 0)
.contar:
    cmp byte [rdi + rax ], 0 ; ¿Es el carácter nulo?
    je .fin ; Si es nulo, terminar
    inc rax
    jmp .contar ; Repetir
.fin:
    pop rbp ; Restauro viejo RBP
    ret



my_strcpy:
    mov rax, rdi      ; Save original dest for return value
    
.copy_loop:
    mov dl, [rsi]     ; Load byte from src
    mov [rdi], dl     ; Store byte to dest
    inc rsi           ; Move to next src byte
    inc rdi           ; Move to next dest byte
    test dl, dl       ; Check for null terminator
    jnz .copy_loop    ; Continue if not null
    
    ret


