#!/bin/bash
set -e
nasm -f elf32 src/boot.asm -o src/boot.o
gcc -m32 -c src/kernel.c -o src/kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/gdt.c -o src/gdt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/idt.c -o src/idt.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra -mgeneral-regs-only
gcc -m32 -c src/msr.c -o src/msr.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/asus_ec.c -o src/asus_ec.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/mem.c -o src/mem.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/pit.c -o src/pit.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/pci.c -o src/pci.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/rtc.c -o src/rtc.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/task.c -o src/task.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/vfs.c -o src/vfs.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/sound.c -o src/sound.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/gui.c -o src/gui.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
gcc -m32 -c src/mouse.c -o src/mouse.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

ld -m elf_i386 -T src/linker.ld -o iso/boot/mados_kernel.bin src/boot.o src/kernel.o src/gdt.o src/idt.o src/msr.o src/asus_ec.o src/mem.o src/pit.o src/pci.o src/rtc.o src/task.o src/vfs.o src/sound.o src/gui.o src/mouse.o

grub-file --is-x86-multiboot iso/boot/mados_kernel.bin
mkdir -p iso/boot/grub
grub-mkrescue -o MadOS.iso iso
echo "COMPILE_SUCCESS"
