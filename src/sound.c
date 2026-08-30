/* ==============================================================================
   MadOS Hobby OS - sound.c
   Pilote du haut-parleur système (PC Speaker)
   ============================================================================== */

#include <stdint.h>

extern unsigned char inb(unsigned short port);
extern void outb(unsigned short port, unsigned char val);
extern uint32_t get_ticks(void);

// Joue une note à une fréquence donnée
void play_sound(uint32_t frequency) {
    uint32_t div;
    uint8_t tmp;

    // Calculer le diviseur de fréquence pour le canal 2 du PIT
    div = 1193180 / frequency;
    
    // Configurer le PIT canal 2
    outb(0x43, 0xB6);
    outb(0x42, (uint8_t)(div & 0xFF));
    outb(0x42, (uint8_t)((div >> 8) & 0xFF));

    // Activer le PC Speaker (bits 0 et 1 du port 0x61)
    tmp = inb(0x61);
    if (tmp != (tmp | 3)) {
        outb(0x61, tmp | 3);
    }
}

// Arrête le son
void nosound(void) {
    uint8_t tmp = inb(0x61) & 0xFC;
    outb(0x61, tmp);
}

// Fonction d'attente basée sur les ticks PIT (1 tick = 10ms)
void sleep_ticks(uint32_t ticks) {
    uint32_t start = get_ticks();
    while (get_ticks() - start < ticks) {
        __asm__ volatile("hlt");
    }
}

// Émet un bip à une fréquence et pendant une durée en ticks (1 tick = 10ms)
void beep(uint32_t frequency, uint32_t ticks) {
    play_sound(frequency);
    sleep_ticks(ticks);
    nosound();
}

// Joue une mélodie ROG de démarrage
void play_rog_chime(void) {
    // Succession de notes rapides de style "Game startup"
    beep(523, 10); // C5 (Do)
    sleep_ticks(2);
    beep(659, 10); // E5 (Mi)
    sleep_ticks(2);
    beep(784, 10); // G5 (Sol)
    sleep_ticks(2);
    beep(1046, 25); // C6 (Do octave sup)
}
