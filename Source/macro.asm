;-----------------------------------------------
;MACROS
%define	LOOK_UP	byte[rel scratchpad+2], "A"
%define	F1	word[rel scratchpad+1], "OP"
%define	F2	word[rel scratchpad+1], "OQ"
%define	LOOK_DOWN	byte[rel scratchpad+2], "B"
%define	LOOK_LEFT	byte[rel scratchpad+2], "C"
%define	LOOK_RIGHT	byte[rel scratchpad+2], "D"
%define	MOVE_F	byte[rel scratchpad], "w"
%define	MOVE_B	byte[rel scratchpad], "s"
%define	MOVE_R	byte[rel scratchpad], "d"
%define	MOVE_L	byte[rel scratchpad], "a"
%define	MOVE_U	byte[rel scratchpad], "q"
%define	MOVE_D	byte[rel scratchpad], "e"
%define	ARROW_
%define	FRAMEBUFFER	alloc_data.addr
%define	DEPTHBUFFER	alloc_data.addr+12
%define	MATRIX_DELIMITER	0x7fffffff
%define	MAX_ALLOC	100
%define	HEADER_LEN	3
%define	UNIT_LEN	26
%define	HALF_UNIT	11
%define	FLOAT_ONE	0x3F800000

%macro lea_offset 2
    push r9

    mov r9, %1
    lea %1, %2
    add %1, r9

    pop r9
%endmacro
