barekv.o: barekv.asm
	nasm -felf64 barekv.asm

barekv: barekv.o
	ld barekv.o -o barekv
