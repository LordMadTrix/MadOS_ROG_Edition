/* ==============================================================================
   MadOS Hobby OS - rtc.c
   Pilote de l'Horloge Temps Réel (RTC) CMOS
   ============================================================================== */

#include <stdint.h>

#define CMOS_ADDRESS 0x70
#define CMOS_DATA    0x71

extern unsigned char inb(unsigned short port);
extern void outb(unsigned short port, unsigned char val);

int get_update_in_progress_flag() {
    outb(CMOS_ADDRESS, 0x0A);
    return (inb(CMOS_DATA) & 0x80);
}

uint8_t get_rtc_register(int reg) {
    outb(CMOS_ADDRESS, reg);
    return inb(CMOS_DATA);
}

void get_rtc_time(int *second, int *minute, int *hour, int *day, int *month, int *year) {
    unsigned char last_second;
    unsigned char last_minute;
    unsigned char last_hour;
    unsigned char last_day;
    unsigned char last_month;
    unsigned char last_year;
    unsigned char registerB;

    // Attendre que la mise à jour RTC ne soit pas en cours
    while (get_update_in_progress_flag());

    *second = get_rtc_register(0x00);
    *minute = get_rtc_register(0x02);
    *hour = get_rtc_register(0x04);
    *day = get_rtc_register(0x07);
    *month = get_rtc_register(0x08);
    *year = get_rtc_register(0x09);

    // Double lecture pour s'assurer de la cohérence de l'heure
    do {
        last_second = *second;
        last_minute = *minute;
        last_hour = *hour;
        last_day = *day;
        last_month = *month;
        last_year = *year;

        while (get_update_in_progress_flag());
        *second = get_rtc_register(0x00);
        *minute = get_rtc_register(0x02);
        *hour = get_rtc_register(0x04);
        *day = get_rtc_register(0x07);
        *month = get_rtc_register(0x08);
        *year = get_rtc_register(0x09);
    } while( (last_second != *second) || (last_minute != *minute) || (last_hour != *hour) ||
             (last_day != *day) || (last_month != *month) || (last_year != *year) );

    registerB = get_rtc_register(0x0B);

    // Convertir BCD en binaire si nécessaire
    if (!(registerB & 0x04)) {
        *second = ((*second / 16) * 10) + (*second & 0xf);
        *minute = ((*minute / 16) * 10) + (*minute & 0xf);
        *hour = (((*hour & 0x7F) / 16) * 10) + (*hour & 0xf);
        *day = ((*day / 16) * 10) + (*day & 0xf);
        *month = ((*month / 16) * 10) + (*month & 0xf);
        *year = ((*year / 16) * 10) + (*year & 0xf);
    }

    // Gérer le format 12 heures si nécessaire
    if (!(registerB & 0x02) && (*hour & 0x80)) {
        *hour = ((*hour & 0x7F) + 12) % 24;
    }
}
