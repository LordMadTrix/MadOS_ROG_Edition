/* ==============================================================================
   MadOS Hobby OS - mouse.c
   Pilote de souris PS/2 et Touchpad standard
   ============================================================================== */

#include <stdint.h>

#define MOUSE_PORT   0x60
#define MOUSE_STATUS 0x64
#define MOUSE_CMD    0x64

extern unsigned char inb(unsigned short port);
extern void outb(unsigned short port, unsigned char val);

static int mouse_cycle = 0;
static int8_t mouse_byte[3];
static int mouse_x = 400; // Position initiale au centre de l'écran (800x600)
static int mouse_y = 300;
static uint8_t mouse_buttons = 0;

// Attente que le contrôleur PS/2 soit prêt
// type = 0 : attente écriture (Input buffer vide), type = 1 : attente lecture (Output buffer plein)
void mouse_wait(uint8_t type) {
    uint32_t timeout = 100000;
    if (type == 0) {
        while (timeout--) {
            if ((inb(MOUSE_STATUS) & 2) == 0) return;
        }
    } else {
        while (timeout--) {
            if ((inb(MOUSE_STATUS) & 1) == 1) return;
        }
    }
}

// Envoyer une commande à la souris PS/2
void mouse_write(uint8_t write) {
    mouse_wait(0);
    outb(MOUSE_CMD, 0xD4); // Indiquer qu'on envoie à la souris (auxiliary device)
    mouse_wait(0);
    outb(MOUSE_PORT, write);
}

// Lire un octet de la souris
uint8_t mouse_read(void) {
    mouse_wait(1);
    return inb(MOUSE_PORT);
}

// Initialise le Touchpad / Souris PS/2
void init_mouse(void) {
    uint8_t status;

    // 1. Activer l'interface auxiliaire de souris sur le 8042
    mouse_wait(0);
    outb(MOUSE_CMD, 0xA8);

    // 2. Activer les interruptions souris (IRQ12)
    mouse_wait(0);
    outb(MOUSE_CMD, 0x20); // Demander le mot de configuration actuel
    mouse_wait(1);
    status = (inb(MOUSE_PORT) | 2); // Activer le bit d'interruption souris (bit 1)
    
    mouse_wait(0);
    outb(MOUSE_CMD, 0x60); // Demander à écrire le mot de configuration
    mouse_wait(0);
    outb(MOUSE_PORT, status);

    // 3. Charger les paramètres par défaut de la souris
    mouse_write(0xF6);
    mouse_read(); // Lire l'ACK de confirmation (0xFA)

    // 4. Activer la transmission des paquets (data reporting)
    mouse_write(0xF4);
    mouse_read(); // Lire l'ACK (0xFA)
}

// Appelé par l'IRQ12
void mouse_handler(void) {
    uint8_t status = inb(MOUSE_STATUS);
    
    // S'assurer que la donnée provient bien de la souris (bit 5 activé)
    if (!(status & 0x20)) return;

    switch (mouse_cycle) {
        case 0:
            mouse_byte[0] = inb(MOUSE_PORT);
            // L'octet 0 doit avoir le bit 3 activé (vérification de synchronisation du paquet)
            if (mouse_byte[0] & 8) {
                mouse_cycle = 1;
            }
            break;
        case 1:
            mouse_byte[1] = inb(MOUSE_PORT);
            mouse_cycle = 2;
            break;
        case 2:
            mouse_byte[2] = inb(MOUSE_PORT);
            
            // Paquet complet de 3 octets reçu, traitement des coordonnées relatives
            int x_offset = (int)mouse_byte[1];
            int y_offset = (int)mouse_byte[2];

            // Traitement des signes (bit 4 pour X, bit 5 pour Y dans l'octet 0)
            if (mouse_byte[0] & 0x10) {
                x_offset |= ~0xFF; // Signe négatif pour X
            }
            if (mouse_byte[0] & 0x20) {
                y_offset |= ~0xFF; // Signe négatif pour Y
            }

            // Boutons de la souris (bits 0: gauche, 1: droit, 2: milieu)
            mouse_buttons = (mouse_byte[0] & 0x07);

            // Mise à jour de la position (la souris PS/2 utilise Y inversé par rapport aux pixels de l'écran)
            mouse_x += x_offset;
            mouse_y -= y_offset;

            // Limiter la souris aux bords de l'écran dynamiquement
            extern int scr_width;
            extern int scr_height;
            if (mouse_x < 0) mouse_x = 0;
            if (mouse_x > scr_width - 1) mouse_x = scr_width - 1;
            if (mouse_y < 0) mouse_y = 0;
            if (mouse_y > scr_height - 1) mouse_y = scr_height - 1;

            mouse_cycle = 0; // Prêt pour le prochain paquet
            break;
    }
}

// Récupère les coordonnées et l'état des boutons
void get_mouse_state(int* x, int* y, uint8_t* buttons) {
    *x = mouse_x;
    *y = mouse_y;
    *buttons = mouse_buttons;
}
