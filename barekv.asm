global _start

section .data

ptr_sz: equ 8

struc KVNode 
  .key      resb ptr_sz,
  .value    resb ptr_sz,
  .is_free  resb 1,
  .next     resb ptr_sz
endstruc

msg: db 'Hello World, Test', 0xA
msg_size: equ $ - msg

key_1: db 'key_1'
key_1_size: equ $ - key_1

key_2: db 'key_2'
key_2_size: equ $ - key_2

key_3: db 'key_3'
key_3_size: equ $ - key_3

val_1: db 'val_1'
val_2_size: equ $ - val_1

kv_node_pool: resb 100 * KVNode_size
kv_array: resb 100 * ptr_sz  ;; Array of pointers to KVNodes

section .text

_start:
	lea 	rsi, [msg]
	mov 	rdx, msg_size
	; call 	print_str

	mov 	qword [kv_array], msg
	mov 	byte  [kv_array + 8], msg_size   

	mov 	qword [kv_array + 9], key_1
	mov 	byte  [kv_array + 9 + 8], key_1_size   

	lea	rdx, [kv_array + 9]
	call    kv_print

	call 	exit_success

;; Get a KVNode from the pool.
;;   @[O] node <RAX: ptr> Pointer to a free KVNode
kvpool_get:
	ret

;; Free/return a KVNode to the pool.
;;   @[I] node <RDX: ptr> Pinter to the node to be returned.
kvpool_free:
	mov byte [rdx + KVNode.is_free], 1	
	ret

;; Debug function that prints out the hashmap.
;;   @[I] hashmap <RDX: ptr> Pointer to a hashmap data structure.
kv_print:
	mov	rsi, [rdx]
	movzx   rdx, byte [rdx + 8]
	call 	print_str	
	ret
	
;; Set a key-value pair in a hashmap
;;   @[I] hashmap    <RDX: ptr>     Pointer to hashmap data structure.
;;   @[I] key        <RAX: ptr>     Pointer to a string to use as a key.
;;   @[I] key_size   <???: uint32>  Length of the key string.
;;   @[I] value      <RBX: ptr>     Pointer to bytes.
;;   @[I] value_size <???: uint32>  Length of the value bytes.
kv_set:
	ret

;; Get a value from a hashmap using a key.
;;   @[I] hashmap      <RDX: ptr>    Pointer to a hashmap data structure.
;;   @[I] key          <RAX: ptr>    Pointer to a string to use as a key.
;;   @[I] key_size     <uint32>      Length of the key string.
;;   @[O] value        <RAX: ptr>    Pointer to the value bytes or 0 if not found.
;;   @[O] value_length <???: uint32> Length of the value if it was found.
kv_get:
	ret

;; Print a string;
;;   @[I] str  <RSI: ptr> Pointer to string to be printed.
;;   @[I] size <RDX: uint32> Length of @str.
print_str:
	mov 	edi, 1 ; STDOUT
	mov 	eax, 1 ; sys_write
	syscall
	ret

;; Exit the process with the success (0) return code.
exit_success:
	xor 	edi, edi ;; Return 0
	mov 	eax, 60
	syscall
	ret


