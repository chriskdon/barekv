%macro invoke 1
	call	%1
%endmacro

%macro invoke 2
	mov 	rdx, %2
	call	%1
%endmacro

%macro invoke 3
	mov	rdx, %2
	mov	rsi, %3
	call 	%1
%endmacro

%macro invoke 4
	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	call 	%1
%endmacro

%macro invoke 5
	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	mov     r8, %5
	call 	%1
%endmacro

%macro invoke 6
	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	mov     r8, %5
	mov	r9, %6
	call 	%1
%endmacro

%macro invoke 7
	mov	rdx, %2
	mov	rsi, %3
	mov	rdi, %4
	mov     r8, %5
	mov	r9, %6
	mov	r10, %7
	call 	%1
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


