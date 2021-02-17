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

val_1: db 5,'val_1'
val_1_size: equ $ - val_1

val_2: db 5,'val_2'
val_2_size: equ $ - val_2

test_str: db 4,'test'

ex_msg_no_free_nodes: db 27,'Pool is out of free nodes.',0xA

section .bss

kv_pool_size: equ 5
kv_pool: resb kv_pool_size * KVNode_size

kv_array_size: equ 5
kv_array: resb kv_array_size * ptr_sz  ;; Array of pointers to KVNodes

section .text

_start:	
	invoke 	kvpool_init

	invoke 	kv_set, key_1, val_1, val_1_size
	invoke 	kv_get, key_1
	invoke	str_print, rax

	invoke 	kv_set, key_2, val_2, val_2_size
	invoke	kv_get, key_2
	invoke	str_print, rax

	invoke 	kv_set, key_3, val_2, val_2_size
	invoke	kv_get, key_3
	invoke	str_print, rax 

	invoke 	exit_success

;; Throw an exception
;;   @[I] msg <RDX: ptr> String to the exception message.
throw_ex:
	invoke	str_print, rdx
	invoke 	exit_success ;; FIXME 
	ret;

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
	
	mov	rdx, 0
	mov	rcx, kv_array_size
	div 	rcx

	mov	rax, rdx ;; rax = hashcode % kv_array_size

	fpost
	ret

;; Set a KVNode at an index in the hashmap.
;;	@[I] key	<RDX: ptr>    Pointer to a string to use as a key.
;; 	@[I] value	<RSI: ptr>    Pointer to bytes.
;; 	@[I] value_size <RDI: uint32> Length of the value bytes.
;;      @[I] index      <R8: uint32>  Index the hashmap to set.
;;      @[O] node       <RAX: ptr>    If a node was replaced then the
;;                                    old KVNode will be returned, if a new
;;                                    node was inserted 0 is returned, if
;;                                    the node could not be inserted, -1 
;;                                    is returned.
kv__set_index:
	fpre

	;; Get the KVNode @ index
	;; KVNode* rbx = kv_array[index]
	;; KVNode  r9  = *rbx
	lea	rbx, [kv_array + r8*ptr_sz]
	mov 	r9, [rbx] 

.find_insert_point:
	;; Check if the node doesn't exist.
	cmp	r9, 0
	je	.new_key

	;; Check if the key already exists
	;; r10 = r9.key
	mov	r10, [r9 + KVNode.key]

	;; If the keys exists then we'll overwrite it
	;; rax = str_equal(...)
	invoke 	str_equal, rdx, r10
	cmp	rax, 1
	je	.key_exists

	;; Follow the linked list of nodes
	;; KVNode* rbx = r9.next (current node)
	;; KVNode  r9  = *rbx
	lea 	rbx, [r9 + KVNode.next]
	mov	r9, [rbx]
	jmp	.find_insert_point

	;; The keys exists already so we need to overwrite it.
	;; This can be done by replacing the KVNode.
.key_exists:
	;; Get a free node
	invoke 	kvpool_get
	cmp	rax, 0
	je	.throw_no_free_nodes

	;; Set the node values
	mov	[rax + KVNode.key], rdx
	mov	[rax + KVNode.value], rsi
	mov	[rax + KVNode.value_size], rdi

	;; Update the next pointer to match the current node
	mov	rcx, [r9 + KVNode.next]
	mov	[rax + KVNode.next], rcx

	;; Set the old .next = 0
	mov	qword [r9 + KVNode.next], 0

	;; Set the new KVNode and return the replaced node
	mov	[rbx], rax
	mov	rax, r9

	jmp 	.end

	;; The key doesn't exist so we
.new_key:
	;; TODO: Remove duplicated code

	;; Get a free node
	invoke 	kvpool_get
	cmp	rax, 0
	je	.throw_no_free_nodes

	;; Set the node values
	mov	[rax + KVNode.key], rdx
	mov	[rax + KVNode.value], rsi
	mov	[rax + KVNode.value_size], rdi

	;; Set the new KVNode and return the replaced node
	mov	[rbx], rax
	mov	rax, 0

	jmp	.end

	;; Could not get any free nodes from the pool. 
.throw_no_free_nodes:
	invoke	throw_ex, ex_msg_no_free_nodes	

.end:
	fpost
	ret

;; Get a value from the hashmap using a key.
;;   @[I] key          <RDX: ptr>     Pointer to a string to use as a key.
;; 
;; FIXME: value should be a single struct with the length
;;   @[O] value        <RAX: ptr>     Pointer to the value bytes or 0 if not found.
;;   @[O] value_length <R11: uint32>  Length of the value if it was found.
kv_get:
	fpre

	invoke	kv__get_index, rdx

	;; FIXME: This is a duplicate of what's in kv__set_index

	;; Get the KVNode @ index
	;; KVNode* rbx = kv_array[index]
	;; KVNode  r9  = *rbx
	lea	rbx, [kv_array + rax*ptr_sz]
	mov 	r9, [rbx] 

.find_insert_point:
	;; Check if the node doesn't exist.
	cmp	r9, 0
	je	.key_not_found

	;; Check if the key already exists
	;; r10 = r9.key
	mov	r10, [r9 + KVNode.key]

	;; If the keys exists then we'll overwrite it
	;; rax = str_equal(...)
	invoke 	str_equal, rdx, r10
	cmp	rax, 1
	je	.key_found

	;; Follow the linked list of nodes
	;; KVNode* rbx = r9.next (current node)
	;; KVNode  r9  = *rbx
	lea 	rbx, [r9 + KVNode.next]
	mov	r9, [rbx]
	jmp	.find_insert_point

.key_found:
	mov	rax, [r9 + KVNode.value]
	mov	r11, [r9 + KVNode.value_size]
	jmp	.end

.key_not_found:
	mov 	rax, 0
	mov	r11, 0

.end:
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

