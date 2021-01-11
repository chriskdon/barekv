.DEFAULT_GOAL := barekv

barekv.o: barekv.asm
	nasm -felf64 -g barekv.asm

barekv: barekv.o
	ld barekv.o -o barekv
