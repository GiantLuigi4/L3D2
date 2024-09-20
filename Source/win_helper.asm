      section .data ; sys_stor
sOut:      dq 0

    section .bss
term_data: resb 22

extern GetStdHandle
extern ExitProcess
extern VirtualAlloc
extern GetConsoleScreenBufferInfo
extern WriteConsoleA

; more graceful than using call directly
; TODO: there is something VERY wrong with this macro
%macro ABI 1-*
    %if %0>1
        %2 rcx, %3
    %endif
    %if %0>3
        %4 rdx, %5
    %endif
    %if %0>5
        %6 r8, %7
    %endif
    %if %0>7
        %8 r9, %9
    %endif
    %if %0>9
        %rotate -1
        %rep %0 - 8
            %rotate -1
            push %1
        %endrep
        %rotate -8
    %endif
    call %1
%endmacro

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
;    ABI GetConsoleScreenBufferInfo, mov, [rel sOut], lea, [rel term_data]
    add rsp, 32

    ; copy important information to %1
    mov ax, word[rel term_data]
    mov word[rel %1.x], ax
    mov ax, word[rel term_data+2]
    mov word[rel %1.y], ax
%endmacro

%macro ALLOC_MEMORY 1
.b:
    sub rsp, 32                          ; Allocate 32 bytes of shadow space
    xor rcx, rcx                         ; allow system to choose address
    mov rdx, %1                          ; size to allocate
    mov r8,  0x3000                      ; Set flAllocationType = MEM_COMMIT | MEM_RESERVE (r8)
    mov r9,  0x40                        ; Set flProtect = PAGE_READWRITE (r9)
    call VirtualAlloc

;    %define flAllocationType 0x3000      ; Set flAllocationType = MEM_COMMIT | MEM_RESERVE
;    %define flProtect 0x3000             ; Set flProtect = PAGE_READWRITE
;    ABI VirtualAlloc, xor, rcx, mov, %1, mov, flAllocationType, mov, flProtect

    add rsp, 32                          ; Allocate 32 bytes of shadow space
%endmacro


extern CreateFile2
%macro OPEN_FILE 1
    sub rsp, 40                          ; Allocate 32 bytes of shadow space
    lea rcx, %1
    mov rdx, 0x80000000 ; read mode (generic read)
.a:
    xor r8, r8
    mov r9, 4 ; creation_disposition (always open; creates and open if not exist, elsewise open)
mov qword [rsp+32], 0              ; Optional fifth argument: extended parameters (NULL)
    call CreateFile2
    add rsp, 40                          ; Allocate 32 bytes of shadow space
.b:
%endmacro
