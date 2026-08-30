/* ==============================================================================
   MadOS Hobby OS - linker.ld
   Script d'édition de liens pour positionner le noyau en mémoire
   ============================================================================== */

ENTRY(_start)

SECTIONS
{
    /* GRUB charge le noyau à l'adresse physique de 1 Mo */
    . = 1M;

    /* En-tête multiboot en premier pour que GRUB le trouve au début */
    .text BLOCK(4K) : ALIGN(4K)
    {
        *(.multiboot)
        *(.text)
    }

    /* Données en lecture seule */
    .rodata BLOCK(4K) : ALIGN(4K)
    {
        *(.rodata)
    }

    /* Données initialisées */
    .data BLOCK(4K) : ALIGN(4K)
    {
        *(.data)
    }

    /* Données non initialisées + Pile */
    .bss BLOCK(4K) : ALIGN(4K)
    {
        *(COMMON)
        *(.bss)
    }
}
