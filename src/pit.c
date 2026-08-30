/* ==============================================================================
   MadOS Hobby OS - pit.c
   Pilote du contrôleur de temps matériel Intel 8253/8254 (PIT)
   ============================================================================== */

#include <stdint.h>

extern void outb(unsigned short port, unsigned char val);
extern void term_print(const char* str);

static volatile uint32_t timer_ticks = 0;

void init_pit(uint32_t frequency) {
    /* Calculer le diviseur (fréquence de base = 1193182 Hz) */
    uint32_t divisor = 1193182 / frequency;

    /* Envoyer le mot de commande : Channel 0, LOBYTE/HIBYTE, Mode 3 (Square Wave) */
    outb(0x43, 0x36);

    /* Envoyer le diviseur octet par octet */
    outb(0x40, (uint8_t)(divisor & 0xFF));
    outb(0x40, (uint8_t)((divisor >> 8) & 0xFF));
}

/* Appelé par le gestionnaire d'interruption IDT à chaque tick d'horloge IRQ0 */
void timer_handler(void) {
    timer_ticks++;
}

/* Retourne l'uptime du système en secondes */
uint32_t get_uptime(void) {
    return timer_ticks / 100; /* 100 ticks = 1 seconde */
}

/* Retourne le nombre brut de ticks d'horloge (100 Hz, resolution de 10ms) */
uint32_t get_ticks(void) {
    return timer_ticks;
}
