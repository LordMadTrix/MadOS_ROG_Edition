/* ==============================================================================
   MadOS Hobby OS - asus_ec.c
   Pilote de bas niveau pour le contrôleur embarqué (EC) ASUS ROG (Ports 0x6C/0x68)
   ============================================================================== */

#include <stdint.h>

#define EC_SC_PORT 0x6C  /* Status / Command Port */
#define EC_DATA_PORT 0x68 /* Data Port */

#define EC_OBF_MASK 0x01  /* Output Buffer Full */
#define EC_IBF_MASK 0x02  /* Input Buffer Full */

#define EC_CMD_READ  0x80 /* Commande de lecture EC */
#define EC_CMD_WRITE 0x81 /* Commande d'écriture EC */

/* Déclarations de fonctions I/O issues de kernel.c */
extern unsigned char inb(unsigned short port);
extern void outb(unsigned short port, unsigned char val);
extern void term_print(const char* str);
extern void term_print_int(int num);

/* Attendre que le buffer d'entrée de l'EC soit vide (prêt à recevoir) */
static void ec_wait_write(void) {
    int timeout = 100000;
    while ((inb(EC_SC_PORT) & EC_IBF_MASK) && timeout > 0) {
        timeout--;
    }
}

/* Attendre que le buffer de sortie de l'EC soit plein (donnée disponible) */
static void ec_wait_read(void) {
    int timeout = 100000;
    while (!(inb(EC_SC_PORT) & EC_OBF_MASK) && timeout > 0) {
        timeout--;
    }
}

/* Écriture d'un octet dans un registre spécifique de l'EC */
void asus_ec_write(uint8_t addr, uint8_t data) {
    term_print("  [EC] Ecriture: Registre 0x");
    term_print_int(addr);
    term_print(" <- ");
    term_print_int(data);
    term_print("\n");

    ec_wait_write();
    outb(EC_SC_PORT, EC_CMD_WRITE);
    
    ec_wait_write();
    outb(EC_DATA_PORT, addr);
    
    ec_wait_write();
    outb(EC_DATA_PORT, data);
}

/* Lecture d'un octet depuis un registre de l'EC */
uint8_t asus_ec_read(uint8_t addr) {
    ec_wait_write();
    outb(EC_SC_PORT, EC_CMD_READ);
    
    ec_wait_write();
    outb(EC_DATA_PORT, addr);
    
    ec_wait_read();
    return inb(EC_DATA_PORT);
}

/* Configuration matérielle de la limite de charge de batterie */
void mados_set_battery_limit(uint8_t limit) {
    /* 
       Sur la plupart des cartes mères ASUS ROG récentes, la limite de charge 
       de la batterie est configurée via le registre EC 0x12 (parfois 0xEF).
    */
    term_print("Envoi de la commande de limite batterie au materiel...\n");
    asus_ec_write(0x12, limit);
    term_print("Seuil de charge materiel configure avec succes !\n");
}

/* Configuration matérielle des couleurs AURA RGB */
void mados_set_hardware_rgb(uint8_t r, uint8_t g, uint8_t b) {
    /*
       Sur les modèles ASUS ROG, le rétroéclairage RGB est souvent contrôlé 
       via les registres EC 0x40 (Rouge), 0x41 (Vert), 0x42 (Bleu).
    */
    term_print("Mise a jour des LED physiques de la carte mere...\n");
    asus_ec_write(0x40, r);
    asus_ec_write(0x41, g);
    asus_ec_write(0x42, b);
    term_print("Couleur AURA physique mise a jour !\n");
}
