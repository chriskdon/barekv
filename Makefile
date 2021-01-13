.DEFAULT_GOAL := barekv

barekv.o: *.asm
	nasm -felf64 -g barekv.asm

barekv: barekv.o
	ld barekv.o -o barekv

preprocess: *.asm
	nasm -e barekv.asm
