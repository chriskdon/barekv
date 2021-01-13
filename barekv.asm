%include "macros.asm"
%include "string.asm"

global _start

;; Strings are represented with the first byte as the length
;; String can have max length of 256

;; Register order
;; ARGS: RDX, RSI, RDI, R8, R9, R10
;; RETURN: RAX, R11

%define SUCCESS 0
%define ERROR   1

section .data

ptr_sz: equ 8

struc KVNode 
  .key      	resb ptr_sz,
  .value    	resb ptr_sz,
  .value_size 	resb 4
  .is_free  	resb 1,
  .next     	resb ptr_sz
endstruc

msg: db 18, 'Hello World, Test', 0xA

key_1: db 5, 'key_1'
key_2: db 5, 'key_2'
key_3: db 5, 'key_3'

val_1: db 'val_1'
val_1_size: equ $ - val_1

test_str: db 4,'test'

section .bss

kv_pool_size: equ 5
kv_pool: resb kv_pool_size * KVNode_size

kv_array_size: equ 100
kv_array: resb kv_array_size * ptr_sz  ;; Array of pointers to KVNodes

section .text

_start:
	invoke 	kvpool_init

	; invoke 	kv_set_index, key_1, val_1, val_1_size, 0

	; cmp	rax, 0 ; Check if there was an error setting the key

	invoke str_equal, key_1, key_2
	
	invoke  str_print, key_1
	invoke 	exit_success

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
	mov	dword [rdx + KVNode.value_size], 0
	mov 	byte  [rdx + KVNode.is_free], 1	
	mov 	qword [rdx + KVNode.next], 0

	fpost
	ret
	
;; Set a key-value pair in the hashmap
;;   @[I] key        <RDX: ptr>     Pointer to a string to use as a key.
;;   @[I] value      <RSI: ptr>     Pointer to bytes.
;;   @[I] value_size <RDI: uint32>  Length of the value bytes.
;;   @[O] success    <RAX: byte>    0 for success, error otherwise
kv_set:
	fpre

	;; Get the index for the key 
	invoke 	kv__get_index, rdx

	;; Set the node in the hashmap
	invoke 	kv__set_index, rdx, rsi, rdi, rax

	;; Check for an error
	cmp	rax, -1
	jne	.success

.error:
	mov 	rax, ERROR	
	jmp     .end

.success:
	mov	rax, SUCCESS

.end:
	fpost
	ret

;; Get the index in the hashmap for a key
;; 	@[I] key	<RDX: ptr> Pointer to a string key.
;;	@[O] index	<RAX: uint32> Index for a key or -1 (error)
kv__get_index:
	fpre

	invoke 	str_hashcode
	
	mov	rdx, kv_array_size 
	div 	rdx
	mov	rax, rdx ;; rax = hashcode % kv_array_size

	fpost
	ret

;; Set a KVNode at an index in the hashmap.
;;	@[I] key	<RDX: ptr>    Pointer to a string to use as a key.
;; 	@[I] value	<RSI: ptr>    Pointer to bytes.
;; 	@[I] value_size <RDI: uint32> Length of the value bytes.
;;      @[I] index      <R8: uint32>  Index the hashmap to set.
;;      @[O] node       <RAX: ptr>    If a node was replaced on insert then the
;;                                    old KVNode will be returned; 0 otherwise.
kv__set_index:
	fpre

	;; Get the address of the KVNode @ index
	mov 	r9, [kv_array + r8]

	;; Check if the key is already set
	lea	r9, [r9 + KVNode.key]
	invoke 	str_equal, r9, rdx
	cmp	rax, 1
	je	.key_exists

.key_exists:
	mov	[r9 + KVNode.value], rsi
	mov	[r9 + KVNode.value_size], rdi

	jmp 	.end
.new_key:

.end:
	fpost
	ret

;; Get a value from the hashmap using a key.
;;   @[I] key          <RDX: ptr>     Pointer to a string to use as a key.
;;   @[O] value        <RSI: ptr>     Pointer to the value bytes or 0 if not found.
;;   @[O] value_length <RDI: uint32>  Length of the value if it was found.
kv_get:
	fpre
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

