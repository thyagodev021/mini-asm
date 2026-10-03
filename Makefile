mini: mini.o
	ld mini.o -o mini
mini.o: mini.asm
	nasm -f elf64 mini.asm -o mini.o
run: mini
	./mini
clean:
	rm -f mini mini.o
