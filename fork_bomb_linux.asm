global main

section .data
	HeapStart dd 0               ; Heap Start Address
	HeapStop dd 0                ; First Address After Heap
	HeapSize dd 0                ; Heap Size
	HeapInit db 0                ; Flag indicates whether a heap has been created

section .rodata
	HEAPMAX dd 0xFA0

section .text
; reduced malloc version with no error checks (unsafe)
; allocate a block of memory capable of holding size
; bytes of user specified data. If size is zero, a pointer
; to zero bytes of memory should be returned
; returns NULL on failure or pointer to new block on success
l_malloc:
	push ebp
	mov ebp, esp
	push ebx
	push edi
	push esi
	mov edi, [ebp+8]             ; edi contains user requested size
	
	cmp edi, 4                   ; checks user input >= 4
	jge .BigEnough
	;cmp edi, 0
	;je .error
	mov edi, 4
	.BigEnough:
	cmp byte [HeapInit], 0	   	 ; check if heap is created
	jne .skipCreateHeap
	call .CreateHeap 
	.skipCreateHeap:	
	add edi, 4                   ; adds header space to requested user size
	mov eax, edi		
	and eax, 0x03                ; mask out last two bits
	cmp eax, 0                   ; do they have a value?
	je .MultipleOfFour
	mov eax, edi		
	and eax, 0xFFFFFFFC          ; mask out last two bits
	add eax, 4                   ; add 4
	mov edi, eax                 ; replace in edi
	.MultipleOfFour:
	mov esi, [HeapStart]         ; CurrentAddress
	mov ebx, 0                   ; BestFit Address 0=No fit found
	.loop:
		mov eax, [HeapStop]
		sub eax, 4               ; Ensures last 4 bytes are not allocated
		cmp esi, eax
		jg .FixHeaders
		
	; FindFreeBlock
		mov eax, [esi]
		and eax, 0x01
		cmp eax, 0
		jne .NextBlock
		
	; BlockBigEnough
		cmp [esi], edi
		jl .NextBlock
	; BestFit
		cmp ebx, 0               ; is there a prev best fit?
		je .NewBestFit
		mov eax, [ebx]           ; is current location a better
		cmp eax, [esi]           ; fit than prev best fit?
		jl .NewBestFit
		jmp .NextBlock		
		.NewBestFit:		
		mov ebx, esi             ; make current location best fit
	.NextBlock:
		mov eax, [esi]           ; saves Current Block Size in eax
		and eax, 0xFFFFFFFE      ; mask out the inuse Bit
		add esi, eax             ; CurrentAddress + CurrentBlockSize = NextBlockAdd
		jmp .loop
	
	.GrowHeap:
		mov ecx, [HeapStop]
		mov	ebx, ecx
		add	ebx, edi
		mov eax, 45
		int	80h
		;cmp eax, 0
		;jl .error
		mov	[HeapStop], eax
		sub	eax, [HeapStart]
		mov [HeapSize], eax
		mov eax, [HeapStart]
		mov ebx, ecx
		mov [ebx], edi           ; mov req size into ebx
		add dword [ebx], 1       ; tags block as in use
		mov eax, ebx
		jmp .SendPointerToUser	

	.FixHeaders:
		cmp ebx, 0               ; was a best fit found in heap
		je .GrowHeap
		mov eax, [ebx]
                                 ; what is This	add eax, 8	;If current block size is <= 8 bytes 
                                 ; bigger than required block size
		cmp eax, edi             ; compare cur size + 8 to req size
		jle .KeepBlockSize       ; keep block size
		mov eax, ebx
		mov ecx, [eax]           ; copy old current block size
		add eax, edi             ; create new header for next blk
		sub ecx, edi             ; calculate remaining block size
		mov [eax], ecx           ; fills header for trailing block
		mov dword [ebx], edi     ; moves req size into user header
		.KeepBlockSize:
			add dword [ebx], 1   ; tags user block as in use
			mov eax, ebx
			jmp .SendPointerToUser
		
	.SendPointerToUser:
		add eax, 4               ; adjusts eax so it holds users pointer
	pop esi
	pop edi
	pop ebx
	mov esp, ebp
	pop ebp
	ret

	;.error:
	;	xor eax, eax
	;	pop esi
	;	pop edi
	;	pop ebx
	;	mov esp, ebp
	;	pop ebp
	;	ret

	.CreateHeap:
		xor ebx, ebx
		mov	eax, 45			     ; system call #45 sys_brk
		int	80h                  ; checks initial break
		;cmp eax, 0
		;jl .error               ; exit, if error
		mov	[HeapStart], eax
		mov ebx, [HEAPMAX]
		add	ebx, eax
		mov eax, 45
		int	80h
		mov	[HeapStop], eax
		;cmp	eax, 0
		;jl .error
		sub	eax, [HeapStart]
		mov [HeapSize], eax
		mov byte [HeapInit], 1
		mov eax, [HeapStart]
		mov ebx, [HeapSize]
		mov [eax], ebx
		ret
		
main:
    while_begin:
        mov eax, 2               ; system call #2 sys_fork
        int 80h                  ; in C declared as fork()
        push 1000000             ; memory allocation in bytes
        call l_malloc
        jmp while_begin
		
