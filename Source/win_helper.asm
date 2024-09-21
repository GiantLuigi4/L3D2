       section .data ; sys_stor
sOut:       dq 0
bytes_read: dd 0

    section .bss
term_data: resb 22

extern ExitProcess

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
extern GetStdHandle
%macro PREP_WINDOWS 0
    push rcx
    	sub rsp, 32

        mov rcx, -11                ; STD_OUTPUT_HANDLE
        call GetStdHandle           ; get std out handle
        mov qword [rel sOut], rax   ; store the handle for later use

        add rsp, 32
    pop rcx
%endmacro

extern GetConsoleScreenBufferInfo
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

extern VirtualAlloc
%macro ALLOC_MEMORY 1
    sub rsp, 32                          ; Allocate 32 bytes of shadow space
    xor rcx, rcx                         ; allow system to choose address
    mov rdx, %1                          ; size to allocate
    mov r8,  0x3000                      ; Set flAllocationType = MEM_COMMIT | MEM_RESERVE (r8)
    mov r9,  0x40                        ; Set flProtect = PAGE_READWRITE (r9)
    call VirtualAlloc

;    %define flAllocationType 0x3000      ; Set flAllocationType = MEM_COMMIT | MEM_RESERVE
;    %define flProtect 0x3000             ; Set flProtect = PAGE_READWRITE
;    ABI VirtualAlloc, xor, rcx, mov, %1, mov, flAllocationType, mov, flProtect

    add rsp, 32                          ; Reset stack
%endmacro


; CreateFileA avoids needing to convert to LPCWSTR
; the C++ code for that conversion alone is intimidating, this file does not need that much complexity if it can be avoided
extern CreateFileA
%macro OPEN_FILE 1
    sub rsp, 32                          ; Allocate 32 bytes of shadow space
    lea rcx, %1
    mov rdx, 0x80000000 ; read mode (generic read)
    xor r8, r8
    mov r9, 0                         ; optional; don't care

sub rsp, 24                          ; Allocate 32 bytes of shadow space
mov qword [rsp+32   ], 4              ; creation_disposition (always open; creates and open if not exist, elsewise open)
mov qword [rsp+32+ 8], 0              ; don't care
mov qword [rsp+32+16], 0              ; don't care
    call CreateFileA
add rsp, 24                          ; Reset stack

    add rsp, 32                          ; Reset stack
%endmacro


extern GetFileSize
%macro FILE_SIZE 1
    sub rsp, 32                          ; Allocate 32 bytes of shadow space
    lea rcx, %1
    xor rdx, rdx
    call GetFileSize
    add rsp, 32                          ; Reset stack
%endmacro


extern ReadFile
; file handle is %1
;   file data is %2
;   read size is %3
%macro READ_FILE 3
    sub rsp, 32                          ; Allocate 32 bytes of shadow space

    lea rcx, %1 ; handle
    lea rdx, %2 ; buffer
    mov  r8, %3 ; size
    lea  r9, [rel bytes_read]
sub rsp, 48                          ; Reset stack
mov qword [rsp+ 0], 0              ; ensure stack is clear
mov qword [rsp+ 8], 0              ; ensure stack is clear
mov qword [rsp+16], 0              ; ensure stack is clear
mov qword [rsp+24], 0              ; ensure stack is clear
mov qword [rsp+32], 0              ; lpOverlapped; don't care
call ReadFile
add rsp, 48                          ; Reset stack
    add rsp, 32                          ; Reset stack
%endmacro

extern CloseHandle
%macro CLOSE_FILE 1
    sub rsp, 32                          ; Allocate 32 bytes of shadow space
    lea rcx, %1 ; handle
    call CloseHandle
    add rsp, 32                          ; Reset stack
%endmacro

extern WriteConsoleA
%macro PRINT 2 ; str, len
    ; save reg state
    push rcx
    push r8
    push r9
        sub rsp, 32          ; adjust stack ptr
        mov qword rax, [rel sOut]   ; load sout handle

        ; print to console
        mov r9, 0                   ; no pointer to store the number of characters written
        mov rdx, %1                 ; load string
        mov r8, %2                  ; load str length
        mov rcx, rax                ; move stdout handle to rcx
        call WriteConsoleA
        add rsp, 32          ; correct stack ptr (program segfaults on even numbers of prints elsewise)
    ; load reg state
    pop r9
    pop r8
    pop rcx
%endmacro
