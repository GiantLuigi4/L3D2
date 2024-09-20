      section .data ; sys_stor
sOut:      dq 0

    section .bss
term_data: resb 22

extern GetStdHandle
extern ExitProcess

; cache information required for program to function
%macro PREP_WINDOWS 0
    push rcx
    	sub rsp, 32

        mov rcx, -11                ; STD_OUTPUT_HANDLE
        call GetStdHandle           ; get std out handle
        mov qword [rel sOut], rax   ; store the handle for later use

        add rsp, 32
    pop rcx
%endmacro

%macro TERM_SIZE 1
    sub rsp, 32
    mov rcx, [rel sOut]                 ; load sout handle
	lea	rdx, [rel term_data]	        ; return to this struct
	call GetConsoleScreenBufferInfo
    add rsp, 32

    ; copy important information to %1
    mov ax, word[rel term_data]
    mov word[rel %1.x], ax
    mov ax, word[rel term_data+2]
    mov word[rel %1.y], ax
%endmacro

%macro ALLOC_MEMORY 1
    sub rsp, 32                          ; Allocate 32 bytes of shadow space
    xor rcx, rcx                         ; allow system to choose address
    mov rdx, %1                          ; size to allocate
    mov r8,  0x3000                      ; Set flAllocationType = MEM_COMMIT | MEM_RESERVE (r8)
    mov r9,  0x40                        ; Set flProtect = PAGE_READWRITE (r9)
    call VirtualAlloc
    add rsp, 32                          ; Allocate 32 bytes of shadow space
%endmacro
