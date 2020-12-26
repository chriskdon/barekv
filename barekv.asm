format ELF64 executable 3

segment readable writeable

msg db 'Hello World, Test', 0xA
msg_size = $ - msg

segment readable executable

entry $
	lea 	rsi, [msg]
	mov 	edx, msg_size
	call 	print_str
	
	call 	exit_success


;; Print a string;
;;   @str  EDX <ptr> Pointer to string to be printed.
;;   @size RSI <b32> Length of @str.
print_str:
	mov 	edi, 1 ; STDOUT
	mov 	eax, 1 ; sys_write
	syscall

;; Exit the process with the success (0) return code.
exit_success:
	xor 	edi, edi ;; Return 0
	mov 	eax, 60
	syscall


