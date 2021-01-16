%macro invoke 1
	call	%1
%endmacro

%macro invoke 2
	push	rdx
	
	mov 	rdx, %2
	call	%1
	
	pop	rdx
%endmacro

%macro invoke 3
	push	rdx
	push	rsi

	mov	rdx, %2
	mov	rsi, %3
	call 	%1

	pop	rsi
	pop	rdx
%endmacro

%macro invoke 4
	push	rdx
	push	rsi
	push	rdi

	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	call 	%1

	pop	rdi
	pop	rsi
	pop	rdx
%endmacro

%macro invoke 5
	push	rdx
	push	rsi
	push	rdi
	push	r8

	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	mov     r8, %5
	call 	%1

	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
%endmacro

%macro invoke 6
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9

	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	mov     r8, %5
	mov	r9, %6
	call 	%1

	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
%endmacro

%macro invoke 7
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10

	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	mov     r8, %5
	mov	r9, %6
	mov	r10, %7
	call 	%1
	
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
%endmacro

;; Function setup
%macro fpre 0
	push rdi
	push rsi
	push rdx
	push r8
	push r9
	push r10
	push rbx
	push rcx
%endmacro

;; Function teardown
%macro fpost 0
	pop rcx
	pop rbx
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rsi
	pop rdi
%endmacro


