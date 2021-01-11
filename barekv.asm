global _start

;; Strings are represented with the first byte as the length
;; String can have max length of 256

;; Register order
;; ARGS: RDX, RSI, RDI, R8, R9, R10
;; RETURN: RAX

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

section .data

ptr_sz: equ 8

struc KVNode 
  .key      resb ptr_sz,
  .value    resb ptr_sz,
  .is_free  resb 1,
  .next     resb ptr_sz
endstruc

msg: db 18, 'Hello World, Test', 0xA

key_1: db 5, 'key_1'
key_2: db 5, 'key_2'
key_3: db 5, 'key_3'

val_1: db 'val_1'
val_2_size: equ $ - val_1

test_str: db 4,'test'

section .bss

kv_pool_size: equ 5
kv_pool: resb kv_pool_size * KVNode_size

kv_array_size: equ 100
kv_array: resb kv_array * ptr_sz  ;; Array of pointers to KVNodes

section .text

_start:
	call 	kvpool_init

	call 	kvpool_get
	call	kvpool_get
	call 	kvpool_get

	lea 	rdx, [msg]
	call 	print_str

	call 	exit_success

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

;; Initialize the KV pool.
kvpool_init:
	fpre

	mov 	rcx, kv_pool_size
	
.init_loop:
	dec 	rcx

	;; rax = Node offset
	mov 	rax, KVNode_size
	mov 	rdx, rcx
	mul 	rdx

	;; Set all the nodes in the pool to free
	mov 	qword [kv_pool + rax + KVNode.is_free], 1
	
	test 	rcx, rcx
	jnz	.init_loop	

.end:
	fpost
	ret

;; Get a KVNode from the pool.
;;   @[O] node <RAX: ptr> Pointer to a free KVNode or 0 for not found.
kvpool_get:
	fpre

	mov 	rcx, kv_pool_size

.find_loop:
	dec 	rcx
	jl 	.not_found

	;; rax = Node offset
	mov 	rax, KVNode_size
	mov 	rdx, rcx
	mul 	rdx

	;; Find the first free node
	lea 	rax, [kv_pool + rax]
	cmp 	byte [rax + KVNode.is_free], 1
	jnz 	.find_loop
	
	mov 	byte [rax + KVNode.is_free], 0
	jmp 	.end

.not_found:
	mov 	rax, 0 
.end:
	fpost
	ret

;; Free/return a KVNode to the pool.
;;   @[I] node <RDX: ptr> Pointer to the node to be returned.
kvpool_free:
	fpre

	mov 	qword [rdx + KVNode.key], 0
	mov 	qword [rdx + KVNode.value], 0
	mov 	byte  [rdx + KVNode.is_free], 1	
	mov 	qword [rdx + KVNode.next], 0

	fpost
	ret

;; Debug function that prints out the hashmap.
;;   @[I] hashmap <RDX: ptr> Pointer to a hashmap data structure.
kv_print:
	fpre	
	fpost
	ret
	
;; Set a key-value pair in a hashmap
;;   @[I] hashmap    <RDX: ptr>     Pointer to hashmap data structure.
;;   @[I] key        <RSI: ptr>     Pointer to a string to use as a key.
;;   @[I] value      <RDI: ptr>     Pointer to bytes.
;;   @[I] value_size <R8: uint32>   Length of the value bytes.
kv_set:
	fpre
	fpost
	ret

;; Get a value from a hashmap using a key.
;;   @[I] hashmap      <RDX: ptr>    Pointer to a hashmap data structure.
;;   @[I] key          <RSI: ptr>    Pointer to a string to use as a key.
;;   @[O] value        <RDI: ptr>    Pointer to the value bytes or 0 if not found.
;;   @[O] value_length <R8: uint32>  Length of the value if it was found.
kv_get:
	fpre
	fpost
	ret

;; Print a string;
;;   @[I] str  <RSI: ptr>    Pointer to string to be printed.
print_str:
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

;; Exit the process with the success (0) return code.
exit_success:
	fpre

	xor 	edi, edi ;; Return 0
	mov 	eax, 60
	syscall

	fpost
	ret

