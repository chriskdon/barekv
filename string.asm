;; Check if two strings are equal.
;; @[I] str_1 <RDX: ptr>   String pointer to compare.
;; @[I] str_2 <RSI: ptr>   String pointer to compare.
;; @[O] equal <RAX: byte>  1 if they are equal, 0 if not.
str_equal:
	fpre

	;; Check if the string lengths are not equal
	;; If the lengths aren't equal the strings can't be equal
	mov	al, byte [rdx]
	mov	ah, byte [rsi]
	cmp 	al, ah
	jne	.not_equal

	;; Get to the begining of the strings
	
	;; Compare the characters in the strings
	mov	ch, 0
.cmp_char_loop:
	;; Have we reached the end of the string
	cmp	al, ch
	je	.equal

	inc	ch

	inc	rdx
	inc	rsi

	mov	ah, byte [rdx]
	cmp 	ah, byte [rsi]
	je	.cmp_char_loop

.not_equal:
	mov	rax, 0
	jmp	.end
.equal:
	mov	rax, 1
.end:
	fpost
	ret

;; Get the hashcode for a string.
;; (Taken from java.lang.String)
;; The hash code for a string is computed as
;;   s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
;; using int arithmetic, where s[i] is the
;; `i`'th character of the string, `n` is the length of
;; the string, and ^ indicates exponentiation.
;; https://cs.gmu.edu/~kauffman/cs310/w06-1.pdf (page 7)
;; (The hash value of the empty string is	 zero.)
;;   @[I] str      <RDX: ptr>    Pointer to a null terminated string
;;   @[O] hashcode <RAX: uint64> Hashcode for the string.
str_hashcode:
	fpre

	mov	rax, 0 ; h = 0
	mov 	rcx, 0 ; i = 0
	movzx   r9, byte [rdx] ; length of the string
	inc 	rdx ; rdx += 1 to skip length byte
	mov	r8, rdx ; s = string
.hash_loop:
	cmp 	rcx, r9
	je 	.end

	;; h = h * 31
	mov	rdx, 31
	mul	rdx

	;; h = h + str[i + 1] 
	add	rax, [r8 + rcx]
	
	inc 	rcx
	jmp 	.hash_loop

.end:
	fpost
	ret

;; Print a string;
;;   @[I] str  <RDX: ptr>    Pointer to string to be printed.
str_print:
	fpre

	push 	rdx

	movzx	rdx, byte [rdx]

	pop 	rsi
	inc	rsi

	mov 	edi, 1 ; STDOUT
	mov 	eax, 1 ; sys_write
	syscall

	fpost
	ret
