_load_l3d:
	;----------------------------------------
	;OPEN FILE AND GET UNPACKED + PACKED SIZE
	OPEN_FILE [rel rax]
	mov	r14, rax	;save fd to r14
	READ_FILE [rel r14], [rel file.size], 8

	;----------------------------------------
	;ALLOCATE MEMORY FOR FILE DATA
	mov	eax, dword[rel file.size+4]	;load the unpacked data into rax
	call	_alloc	;then allocate that amount
	mov r15, rax
	xor rax, rax
	READ_FILE [rel r14], [rel r15], [rel file.size]

    lea r15, [r15]

	;----------------------------------------
	;GO TO END OF FILE DATA AND INSERT TERMINATORS
	mov	edi, dword[rel file.size+4]	;load unpacked size here into destination
	mov	esi, dword[rel file.size]	;and packed size here for source
	sub	edi, 8	;subtract 8 here, go to last face position
	sub	esi, 6	;subtract 6 here (3x word) bc no terminating word
	mov	word[r15+rdi+6], 65535	;insert terminating word into end of data
	cmp	word[r15+rsi+4], 65535	;now check if no face data
	jz	.finish_faces	;if yes, finish reading face data
.loop_faces:
	;----------------------------------------
	;MOVE FACE DATA TO END
	mov	rax, qword[r15+rsi-2]	;now, load 1 face (+word) into rax
	mov	qword[r15+rdi-2], rax	;insert it word before it should to not overwrite data
	cmp	word[r15+rsi-2], 65535	;check if finished writing faces
	jz	.finish_faces	;if yes, finish!
	sub	rsi, 6	;otherwise, go to previous face
	sub	rdi, 6	;by decreasing source and destination index
	jmp	.loop_faces	;loop over
.finish_faces:
	sub	rdi, 20	;when finished, decrease by vertex length +dword here
	sub	rsi, 14	;and vertex length -dword +word here
	mov	dword[r15+rdi+16], MATRIX_DELIMITER	;move a -1 into end of vertex to show endd
.loop_vertices:
	;----------------------------------------
	;UNPACK AND MOVE VERTEX DATA TO END
	movups	xmm0, [r15+rsi]	;load xyz into xmm0
	movups	[r15+rdi], xmm0	;and insert them into the position at end
	mov	dword[r15+rdi+12], FLOAT_ONE	;then insert the 1.0 at end there
	cmp	rsi, 0	;check if source index counter is at 0 (finished everything)
	jz	.finish_load	;if yes, finish loading
	sub	rsi, 12	;otherwise, go to previous face
	sub	rdi, 16
	jmp	.loop_vertices	;loop over
.finish_load:
	CLOSE_FILE [rel r14]
	ret	;finished!

_load_ltx:
	;----------------------------------------
	;OPEN FILE AND GET UNPACKED + PACKED SIZE
	OPEN_FILE [rel rax]
	mov	r14, rax	;save fd to r14
	READ_FILE [rel r14], [rel file.size], 4

	;----------------------------------------
	;CORRECT FILESIZE AND ALLOC SPACE
	mov	eax, dword[rel file.size]	;then save into rax
	sub	rax, 4	;subtract dimension size from rax
	imul	rax, 3	;multiply length by 3 (bytes to unpacked size)
	add	rax, 4	;add back on dimension size
	lea	rdi, [rax-3]	;then load this (addr to start putting data at)
	push	rdi	;and push it for later
	call	_alloc	;allocate size in rax
	mov	r13, rax
	;----------------------------------------
	;READ REST OF FILE WITH CORRECT FILESIZE
	mov	r15, rax	;save addr to r15
	xor	rax, rax	;then sys_read again
	mov	edx, dword[rel file.size]	;use filesize as length
	sub	rdx, 4	;but expand it to be 2 bytes per pixel
	shl	rdx, 1	;because old file used to be 1 per pixel
	add	rdx, 4	;but then transparency bytes added
	mov r9, rdx
    READ_FILE [rel r14], [rel r15], r9
    mov rdx, r9

	pop	rdi	;get back end addr of unpacked pixel data
	add	rdi, r15	;add on allocated data addr
	lea	rsi, [r15+rax-2]	;use data read in rax to find end of pixel data
	inc	r15	;increase r15 so can be used as stopping point for loop
.loop_convert:
	;----------------------------------------
	;LOOP CONVERT INT TO BCD STRING
	cmp	rdi, r15	;check if rdi is finished unpacking
	jz	.finish_convert	;if yes finish conversion
	xor	rdx, rdx	;otherwise clear rdx so it doesnt fuck idiv
	movzx	rax, byte[rsi]	;move colour byte into rax
	mov	cl, byte[rsi+1]	;and save transparency byte to rcx
	mov	rbx, 10	;move 10 into rbx
	idiv	rbx	;and then div int col by 10
	add	rdx, "0"	;add 48 to remainder to conv to ansi
	mov	byte[rdi+2], dl	;then save as last digit in ansi col string
	xor	rdx, rdx	;reset rdx again
	idiv	rbx	;divide answer from previous div by 10 again
	add	rax, "0"	;then convert to ansi
	mov	byte[rdi], al	;and store answer as first digit
	add	rdx, "0"	;and then remainder
	mov	byte[rdi+1], dl	;stored as second digit (BCD string)
	;----------------------------------------
	;PROCESS TRANSPARENCY IF PRESENT
	cmp	cl, -1	;check if transparency byte is -1
	jz	.skip_transparency	;if yes its not transparent
	sub	byte[rdi], "0"	;otherwise convert first digit of col to int
	shl	cl, 4	;then shift transparency over 4 bytes
	or	cl, 0b10000000	;then set msb as a 1 to indicate transparency
	or	byte[rdi], cl	;then combine transparency with int colour
.skip_transparency:
	sub	rdi, 3	;go to previous unpacked pixel
	sub	rsi, 2	;and previous packed pixel
	jmp	.loop_convert	;loop over
.finish_convert:
	;----------------------------------------
	;CLOSE FILE
	CLOSE_FILE [rel r14]
	ret	;and finished!

_load_luv:
	;----------------------------------------
	;OPEN FILE AND GET FILE LENGTH
	OPEN_FILE [rel rax]
	mov	r14, rax	;save fd to r14
	READ_FILE [rel r14], [rel file.size], 4
	;----------------------------------------
	;ALLOCATE SPACE FOR FILE AND READ
	mov	eax, dword[rel file.size]	;load length into rax
	call	_alloc	;and then allocate that amount of data
	mov	rsi, rax	;read all data into this addr now
	xor	rax, rax	;then sys_read
	READ_FILE [rel r14], [rel rsi], [rel file.size]

	CLOSE_FILE [rel r14]
	ret	;and done!
