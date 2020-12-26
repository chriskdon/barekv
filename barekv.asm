format ELF64 executable 3

segment readable executable

entry $

	;; EXIT
	xor edi, edi ;; Return 0
	mov eax, 60
	syscall
