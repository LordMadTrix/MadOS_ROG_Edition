/* ==============================================================================
   MadOS Hobby OS - idt.c
   Configuration de la table des vecteurs d'interruptions (IDT)
   ============================================================================== */

#include <stdint.h>

struct idt_entry {
    uint16_t base_lo;
    uint16_t sel;        /* Segment selector de la GDT (0x08 pour le code) */
    uint8_t  always0;    /* Doit toujours être à 0 */
    uint8_t  flags;
    uint16_t base_hi;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

struct idt_entry idt[256];
struct idt_ptr ip;

extern void term_print(const char* str);

void idt_set_gate(uint8_t num, uint32_t base, uint16_t sel, uint8_t flags) {
    idt[num].base_lo = (base & 0xFFFF);
    idt[num].base_hi = (base >> 16) & 0xFFFF;
    idt[num].sel     = sel;
    idt[num].always0 = 0;
    idt[num].flags   = flags;
}

/* Handler par défaut pour les exceptions */
void exception_handler(void) {
    term_print("\n");
    term_print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    term_print("!!!                   MADOS KERNEL PANIC DETECTE                     !!!\n");
    term_print("!!! Une exception fatale du processeur a ete interceptee par l'IDT   !!!\n");
    term_print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    while (1);
}

/* Handlers externes */
extern void timer_handler(void);
extern void outb(unsigned short port, unsigned char val);

/* PIC Remapping */
void pic_remap(void) {
    outb(0x20, 0x11);
    outb(0xA0, 0x11);
    outb(0x21, 0x20); /* Master IRQs map to 32-39 */
    outb(0xA1, 0x28); /* Slave IRQs map to 40-47 */
    outb(0x21, 0x04);
    outb(0xA1, 0x02);
    outb(0x21, 0x01);
    outb(0xA1, 0x01);
    
    /* Masquer toutes les interruptions sauf IRQ0 (Horloge PIT), IRQ1 (Clavier) et IRQ12 (Souris via Cascade IRQ2) */
    outb(0x21, 0xF8); /* 11111000 -> IRQ0, IRQ1, IRQ2 activées */
    outb(0xA1, 0xEF); /* 11101111 -> IRQ12 activée */
}

/* Stubs d'interruptions assembleurs */
extern void irq0_stub(void);
extern void irq1_stub(void);
extern void irq12_stub(void);

/* Handlers C classiques appelés par les stubs assembleurs */
void irq0_handler(void) {
    timer_handler();
    outb(0x20, 0x20); /* EOI */
}

extern void keyboard_handler(void);
void irq1_handler(void) {
    keyboard_handler();
    outb(0x20, 0x20); /* EOI */
}

extern void mouse_handler(void);
void irq12_handler(void) {
    mouse_handler();
    outb(0xA0, 0x20); /* EOI esclave */
    outb(0x20, 0x20); /* EOI maitre */
}

void init_idt(void) {
    ip.limit = (sizeof(struct idt_entry) * 256) - 1;
    ip.base  = (uint32_t)&idt;

    /* Initialisation de l'IDT à 0 avec le handler d'exception par défaut */
    for (int i = 0; i < 256; i++) {
        idt_set_gate(i, (uint32_t)exception_handler, 0x08, 0x8E);
    }

    /* Remaper le PIC */
    pic_remap();

    /* Enregistrer l'horloge IRQ0 via son stub assembleur sur le vecteur 32 (0x20) */
    idt_set_gate(32, (uint32_t)irq0_stub, 0x08, 0x8E);

    /* Enregistrer le clavier IRQ1 via son stub assembleur sur le vecteur 33 (0x21) */
    idt_set_gate(33, (uint32_t)irq1_stub, 0x08, 0x8E);

    /* Enregistrer la souris IRQ12 via son stub assembleur sur le vecteur 44 (0x20 + 12) */
    idt_set_gate(44, (uint32_t)irq12_stub, 0x08, 0x8E);

    /* Chargement de l'IDT */
    __asm__ volatile("lidt %0" : : "m"(ip));

    /* Activer les interruptions */
    __asm__ volatile("sti");
}

