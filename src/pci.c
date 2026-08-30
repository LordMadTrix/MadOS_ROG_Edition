/* ==============================================================================
   MadOS Hobby OS - pci.c
   Pilote et scanner du bus périphérique PCI (Peripheral Component Interconnect)
   ============================================================================== */

#include <stdint.h>

extern void outb(unsigned short port, unsigned char val);
extern unsigned char inb(unsigned short port);
extern void term_print(const char* str);
extern void term_print_int(int num);
extern void term_set_color(unsigned char color);

/* Couleurs VGA */
#define COLOR_LIGHT_CYAN  11
#define COLOR_WHITE       15
#define COLOR_GREEN       2
#define COLOR_LIGHT_RED   12

uint32_t pci_read_config_32(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset) {
    uint32_t address;
    uint32_t lbus  = (uint32_t)bus;
    uint32_t lslot = (uint32_t)slot;
    uint32_t lfunc = (uint32_t)func;
    
    /* Construire l'adresse de configuration PCI */
    address = (uint32_t)((lbus << 16) | (lslot << 11) |
              (lfunc << 8) | (offset & 0xFC) | ((uint32_t)0x80000000));
              
    /* Écrire l'adresse dans le port d'adresse de configuration */
    /* outb 32-bit equivalent */
    __asm__ volatile ("outl %0, %1" : : "a"(address), "Nd"((uint16_t)0xCF8));
    
    /* Lire les données du port de données de configuration */
    uint32_t tmp;
    __asm__ volatile ("inl %1, %0" : "=a"(tmp) : "Nd"((uint16_t)0xCFC));
    return tmp;
}

uint16_t pci_get_vendor_id(uint8_t bus, uint8_t slot, uint8_t func) {
    uint32_t r0 = pci_read_config_32(bus, slot, func, 0);
    return (uint16_t)(r0 & 0xFFFF);
}

uint16_t pci_get_device_id(uint8_t bus, uint8_t slot, uint8_t func) {
    uint32_t r0 = pci_read_config_32(bus, slot, func, 0);
    return (uint16_t)(r0 >> 16);
}

uint8_t pci_get_class_id(uint8_t bus, uint8_t slot, uint8_t func) {
    uint32_t r8 = pci_read_config_32(bus, slot, func, 8);
    return (uint8_t)(r8 >> 24);
}

uint8_t pci_get_subclass_id(uint8_t bus, uint8_t slot, uint8_t func) {
    uint32_t r8 = pci_read_config_32(bus, slot, func, 8);
    return (uint8_t)(r8 >> 16);
}

void print_pci_class(uint8_t class_id) {
    switch (class_id) {
        case 0x00: term_print("Pre-Class 2.0 Device"); break;
        case 0x01: term_print("Mass Storage Controller"); break;
        case 0x02: term_print("Network Controller"); break;
        case 0x03: term_print("Display Controller (VGA)"); break;
        case 0x04: term_print("Multimedia Controller"); break;
        case 0x05: term_print("Memory Controller"); break;
        case 0x06: term_print("Bridge Device"); break;
        case 0x07: term_print("Simple Comm Controller"); break;
        case 0x08: term_print("Base System Peripheral"); break;
        case 0x09: term_print("Input Device Controller"); break;
        case 0x0A: term_print("Docking Station"); break;
        case 0x0B: term_print("Processor"); break;
        case 0x0C: term_print("Serial Bus Controller"); break;
        case 0x0D: term_print("Wireless Controller"); break;
        case 0x0E: term_print("Intelligent Controller"); break;
        case 0x0F: term_print("Satellite Comm Controller"); break;
        case 0x10: term_print("Encryption Controller"); break;
        case 0x11: term_print("Signal Processing Controller"); break;
        default:   term_print("Unknown Device Class"); break;
    }
}

void pci_print_hex(uint16_t num) {
    char hex_chars[] = "0123456789ABCDEF";
    char buf[7];
    buf[0] = '0';
    buf[1] = 'x';
    buf[2] = hex_chars[(num >> 12) & 0xF];
    buf[3] = hex_chars[(num >> 8) & 0xF];
    buf[4] = hex_chars[(num >> 4) & 0xF];
    buf[5] = hex_chars[num & 0xF];
    buf[6] = '\0';
    term_print(buf);
}

void pci_scan(void) {
    term_set_color(COLOR_LIGHT_CYAN);
    term_print("PCI BUS SCANNER - Liste du materiel detecte :\n");
    term_set_color(COLOR_WHITE);
    term_print("----------------------------------------------------------------------\n");

    int found = 0;
    for (uint16_t bus = 0; bus < 256; bus++) {
        for (uint8_t slot = 0; slot < 32; slot++) {
            for (uint8_t func = 0; func < 8; func++) {
                uint16_t vendor = pci_get_vendor_id((uint8_t)bus, slot, func);
                if (vendor != 0xFFFF && vendor != 0x0000) {
                    uint16_t device = pci_get_device_id((uint8_t)bus, slot, func);
                    uint8_t class_id = pci_get_class_id((uint8_t)bus, slot, func);
                    
                    term_print(" Bus ");
                    term_print_int(bus);
                    term_print(" Slot ");
                    term_print_int(slot);
                    term_print(" Func ");
                    term_print_int(func);
                    term_print(" : ");
                    
                    term_set_color(COLOR_GREEN);
                    pci_print_hex(vendor);
                    term_print(":");
                    pci_print_hex(device);
                    
                    term_set_color(COLOR_WHITE);
                    term_print(" | ");
                    print_pci_class(class_id);
                    term_print("\n");
                    
                    found++;
                }
            }
        }
    }
    
    if (found == 0) {
        term_set_color(COLOR_LIGHT_RED);
        term_print("Aucun peripherique PCI detecte.\n");
        term_set_color(COLOR_WHITE);
    } else {
        term_print("----------------------------------------------------------------------\n");
        term_print("Total : ");
        term_print_int(found);
        term_print(" peripherique(s) PCI trouve(s).\n");
    }
}
