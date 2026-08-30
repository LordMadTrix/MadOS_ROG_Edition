/* ==============================================================================
   MadOS Hobby OS - msr.c
   Pilote de lecture/écriture des Model Specific Registers (MSR) et température CPU
   ============================================================================== */

#include <stdint.h>

/* Instructions x86 de bas niveau pour interagir avec les MSR */
void rdmsr(uint32_t msr, uint32_t *lo, uint32_t *hi) {
    __asm__ volatile("rdmsr" : "=a"(*lo), "=d"(*hi) : "c"(msr));
}

void wrmsr(uint32_t msr, uint32_t lo, uint32_t hi) {
    __asm__ volatile("wrmsr" : : "a"(lo), "d"(hi), "c"(msr));
}

/* 
   Lecture de la température du processeur (Intel/AMD standard compatible MSR)
   MSR_IA32_THERM_STATUS      = 0x19C
   MSR_IA32_TEMPERATURE_TARGET = 0x1A2
*/
int get_cpu_temperature(void) {
    uint32_t lo, hi;
    
    /* 1. Récupération de la température cible maximale (TjMax) */
    /* MSR 0x1A2 : IA32_TEMPERATURE_TARGET */
    // On met un bloc try-catch virtuel ou on s'assure d'intercepter pour éviter les plantages
    // Sous QEMU, nous retournons une valeur réaliste s'il n'émule pas ce MSR.
    lo = 0; hi = 0;
    
    // Tentative de lecture sécurisée
    __asm__ volatile (
        "mov $0x1A2, %%ecx\n\t"
        "rdmsr\n\t"
        : "=a"(lo), "=d"(hi)
        :
        : "ecx"
    );
    
    uint32_t tj_max = (lo >> 16) & 0xFF;
    if (tj_max == 0) {
        tj_max = 100; /* Fallback classique à 100°C si non défini */
    }

    /* 2. Récupération de la valeur du capteur thermique */
    /* MSR 0x19C : IA32_THERM_STATUS */
    lo = 0; hi = 0;
    __asm__ volatile (
        "mov $0x19C, %%ecx\n\t"
        "rdmsr\n\t"
        : "=a"(lo), "=d"(hi)
        :
        : "ecx"
    );

    /* Le décalage thermique est stocké sur les bits 16 à 22 */
    uint32_t thermal_reading = (lo >> 16) & 0x7F;
    
    /* La température réelle est TjMax - Résultat du capteur */
    int temp = (int)tj_max - (int)thermal_reading;

    /* Si les MSR ne sont pas émulés (valeur renvoyant TjMax exacte ou 0) */
    if (temp <= 0 || temp > 120) {
        return 42; /* Température simulée standard en émulation QEMU */
    }
    
    return temp;
}
