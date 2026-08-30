; ==============================================================================
; MadOS Hobby OS - boot.asm
; Point d'entrée compatible Multiboot 1 pour GRUB et QEMU
; ==============================================================================

MBOOT_PAGE_ALIGN    equ 1 << 0
MBOOT_MEM_INFO      equ 1 << 1
MBOOT_VIDEO_MODE    equ 1 << 2
MBOOT_HEADER_MAGIC  equ 0x1BADB002
MBOOT_HEADER_FLAGS  equ MBOOT_PAGE_ALIGN | MBOOT_MEM_INFO | MBOOT_VIDEO_MODE
MBOOT_CHECKSUM      equ -(MBOOT_HEADER_MAGIC + MBOOT_HEADER_FLAGS)

section .multiboot
align 4
    dd MBOOT_HEADER_MAGIC
    dd MBOOT_HEADER_FLAGS
    dd MBOOT_CHECKSUM
    dd 0 ; header_addr
    dd 0 ; load_addr
    dd 0 ; load_end_addr
    dd 0 ; bss_end_addr
    dd 0 ; entry_addr
    dd 0   ; mode_type (0 = linear graphics)
    dd 1024 ; width
    dd 768 ; height
    dd 32  ; depth

section .bss
align 16
stack_bottom:
    resb 16384 ; 16 KiB pour la pile d'exécution
stack_top:

section .text
global _start
extern kernel_main

_start:
    ; Initialisation du pointeur de pile
    mov esp, stack_top

    ; Activer SSE et FPU pour les calculs de haute performance (gaming)
    call enable_sse

    ; Passage des informations Multiboot au noyau C (facultatif mais standard)
    push ebx ; Pointeur vers la structure d'informations Multiboot
    push eax ; Nombre magique Multiboot

    ; Appel du point d'entrée du noyau C
    call kernel_main

    ; Si le noyau C retourne, on entre dans une boucle infinie
.hang:
    cli
    hlt
    jmp .hang

enable_sse:
    ; Activer le FPU (Control Register 0)
    mov eax, cr0
    and ax, 0xFFFB      ; Désactiver TS (Task Switched - bit 3)
    or ax, 0x0022       ; Activer MP (Monitor Coprocessor - bit 1) et NE (Numeric Error - bit 5)
    mov cr0, eax

    ; Activer SSE (Control Register 4)
    mov eax, cr4
    or ax, 0x0600       ; Activer OSFXSR (SSE instructions - bit 9) et OSXMMEXCPT (SIMD exceptions - bit 10)
    mov cr4, eax
    ret

; Stub d'interruption pour IRQ0 (Horloge)
global irq0_stub
extern irq0_handler

irq0_stub:
    pusha           ; Sauvegarde EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI
    push ds
    push es
    push fs
    push gs

    mov ax, 0x10    ; Sélecteur de données du noyau
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call irq0_handler

    pop gs
    pop fs
    pop es
    pop ds
    popa            ; Restauration des registres
    iret            ; Retour d'interruption

; Stub d'interruption pour IRQ1 (Clavier)
global irq1_stub
extern irq1_handler

irq1_stub:
    pusha           ; Sauvegarde EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI
    push ds
    push es
    push fs
    push gs

    mov ax, 0x10    ; Sélecteur de données du noyau
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call irq1_handler

    pop gs
    pop fs
    pop es
    pop ds
    popa            ; Restauration des registres
    iret            ; Retour d'interruption

; Stub d'interruption pour IRQ12 (Souris PS/2)
global irq12_stub
extern irq12_handler

irq12_stub:
    pusha
    push ds
    push es
    push fs
    push gs

    mov ax, 0x10    ; Sélecteur de données du noyau
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call irq12_handler

    pop gs
    pop fs
    pop es
    pop ds
    popa
    iret

