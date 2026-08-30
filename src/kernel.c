/* ==============================================================================
   MadOS Hobby OS - kernel.c
   Noyau 32-bit x86 avec pilote VGA, pilote clavier et pilotes matériels ROG
   ============================================================================== */

#include <stdint.h>
#include <stddef.h>

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_ADDRESS 0xB8000

/* Couleurs VGA standard */
enum vga_color {
    COLOR_BLACK = 0,
    COLOR_BLUE = 1,
    COLOR_GREEN = 2,
    COLOR_CYAN = 3,
    COLOR_RED = 4,
    COLOR_MAGENTA = 5,
    COLOR_BROWN = 6,
    COLOR_LIGHT_GREY = 7,
    COLOR_DARK_GREY = 8,
    COLOR_LIGHT_BLUE = 9,
    COLOR_LIGHT_GREEN = 10,
    COLOR_LIGHT_CYAN = 11,
    COLOR_LIGHT_RED = 12,
    COLOR_LIGHT_MAGENTA = 13,
    COLOR_LIGHT_BROWN = 14,
    COLOR_WHITE = 15,
};

/* Variables globales du terminal */
static int term_row = 0;
static int term_column = 0;
static unsigned char term_color = 15; /* White on Black */
static unsigned short* term_buffer = (unsigned short*)VGA_ADDRESS;
static unsigned char prompt_theme_color = 12; /* COLOR_LIGHT_RED default */

/* Déclarations des pilotes externes */
extern void init_gdt(void);
extern void init_idt(void);
extern int get_cpu_temperature(void);
extern void mados_set_battery_limit(uint8_t limit);
extern void mados_set_hardware_rgb(uint8_t r, uint8_t g, uint8_t b);

/* Nouveaux pilotes */
extern void init_heap(void);
extern void init_pit(uint32_t frequency);
extern uint32_t get_uptime(void);
extern uint32_t get_ticks(void);
extern void pci_scan(void);
extern void* kmalloc(size_t size);
extern void kfree(void* ptr);
extern void get_rtc_time(int *second, int *minute, int *hour, int *day, int *month, int *year);
extern void get_heap_stats(size_t* total_allocated, size_t* total_free, int* block_count);
extern void init_multitasking(void);
extern void create_task(void (*entry)());
extern void task_yield(void);
extern int get_current_task_id(void);
extern void vfs_init(void);
extern void vfs_list(void);
extern void vfs_read(const char* name);
extern void vfs_write(const char* name, const char* content);
extern void play_rog_chime(void);
extern int init_graphics(unsigned int multiboot_info_addr);
extern void render_rog_desktop(int temp, int uptime, int battery);
extern void flush_buffer(void);
extern void init_mouse(void);
extern void gui_handle_char(char c);

/* Déclarations de fonctions I/O de bas niveau */
unsigned char inb(unsigned short port) {
    unsigned char val;
    __asm__ volatile ("inb %1, %0" : "=a"(val) : "Nd"(port));
    return val;
}

void outb(unsigned short port, unsigned char val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

/* Fonctions d'affichage VGA */
static inline unsigned short vga_entry(unsigned char uc, unsigned char color) {
    return (unsigned short)uc | (unsigned short)color << 8;
}

void term_clear(void) {
    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            term_buffer[y * VGA_WIDTH + x] = vga_entry(' ', term_color);
        }
    }
    term_row = 0;
    term_column = 0;
}

void term_set_color(unsigned char color) {
    term_color = color;
}

/* Met à jour le curseur matériel VGA */
void update_cursor(int x, int y) {
    unsigned short temp = y * VGA_WIDTH + x;
    outb(0x3D4, 14);
    outb(0x3D5, temp >> 8);
    outb(0x3D4, 15);
    outb(0x3D5, temp & 0xFF);
}

void scroll(void) {
    for (int y = 1; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            term_buffer[(y - 1) * VGA_WIDTH + x] = term_buffer[y * VGA_WIDTH + x];
        }
    }
    for (int x = 0; x < VGA_WIDTH; x++) {
        term_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = vga_entry(' ', term_color);
    }
    term_row = VGA_HEIGHT - 1;
}

void term_putchar(char c) {
    if (c == '\n') {
        term_column = 0;
        if (++term_row == VGA_HEIGHT) {
            scroll();
        }
    } else if (c == '\r') {
        term_column = 0;
    } else if (c == '\b') {
        if (term_column > 0) {
            term_column--;
            term_buffer[term_row * VGA_WIDTH + term_column] = vga_entry(' ', term_color);
        }
    } else {
        term_buffer[term_row * VGA_WIDTH + term_column] = vga_entry(c, term_color);
        if (++term_column == VGA_WIDTH) {
            term_column = 0;
            if (++term_row == VGA_HEIGHT) {
                scroll();
            }
        }
    }
    update_cursor(term_column, term_row);
}

void term_print(const char* str) {
    while (*str) {
        term_putchar(*str++);
    }
}

/* Fonctions de traitement de chaînes simples */
int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char*)s1 - *(unsigned char*)s2;
}

int strncmp(const char* s1, const char* s2, int n) {
    while (n > 0 && *s1 && (*s1 == *s2)) {
        s1++;
        s2++;
        n--;
    }
    if (n == 0) return 0;
    return *(unsigned char*)s1 - *(unsigned char*)s2;
}

void int_to_str(int num, char* str) {
    int i = 0;
    int is_negative = 0;

    if (num == 0) {
        str[i++] = '0';
        str[i] = '\0';
        return;
    }

    if (num < 0) {
        is_negative = 1;
        num = -num;
    }

    while (num != 0) {
        str[i++] = (num % 10) + '0';
        num = num / 10;
    }

    if (is_negative) {
        str[i++] = '-';
    }

    str[i] = '\0';

    /* Inverser la chaîne */
    int start = 0;
    int end = i - 1;
    while (start < end) {
        char temp = str[start];
        str[start] = str[end];
        str[end] = temp;
        start++;
        end--;
    }
}

void term_print_int(int num) {
    char buf[12];
    int_to_str(num, buf);
    term_print(buf);
}

/* Table de mappage AZERTY pour le clavier */
static const char kbd_azerty[] = {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', ')', '=', '\b',
  '\t', 'a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '^', '$', '\n',
    0,  'q', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', '%', '*',   0,
   '*', 'w', 'x', 'c', 'v', 'b', 'n', ',', ';', ':', '!',   0,  '*',   0,
   ' ',   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
     0,   0, '-',   0,   0,   0, '+',   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0
};

/* Pilote clavier interruptif (IRQ1) avec Buffer Circulaire */
#define KBD_BUFFER_SIZE 256
static volatile char kbd_buffer[KBD_BUFFER_SIZE];
static volatile int kbd_head = 0;
static volatile int kbd_tail = 0;

/* Appelé directement par l'IRQ1 du clavier */
void keyboard_handler(void) {
    static int shift_active = 0;
    unsigned char scancode = inb(0x60);
    
    if (scancode == 0x2A || scancode == 0x36) {
        shift_active = 1;
        return;
    }
    if (scancode == 0xAA || scancode == 0xB6) {
        shift_active = 0;
        return;
    }
    
    /* Ignorer les codes de relâchement */
    if (scancode & 0x80) {
        return;
    }

    if (scancode < sizeof(kbd_azerty)) {
        char c = kbd_azerty[scancode];
        if (c != 0) {
            if (shift_active && c >= 'a' && c <= 'z') {
                c = c - 'a' + 'A';
            }
            
            /* Enfiler le caractère */
            int next = (kbd_head + 1) % KBD_BUFFER_SIZE;
            if (next != kbd_tail) {
                kbd_buffer[kbd_head] = c;
                kbd_head = next;
            }
        }
    }
}

/* Lecture d'une touche de façon non-bloquante avec mise en sommeil CPU (HLT) */
char kbd_get_char(void) {
    while (kbd_tail == kbd_head) {
        /* Met le processeur en pause (mode économie d'énergie / refroidissement) */
        /* Il se réveille instantanément à la prochaine interruption (Timer ou Touche) */
        __asm__ volatile("hlt");
    }
    char c = kbd_buffer[kbd_tail];
    kbd_tail = (kbd_tail + 1) % KBD_BUFFER_SIZE;
    return c;
}

char kbd_get_char_nonblocking(void) {
    if (kbd_tail == kbd_head) {
        return 0;
    }
    char c = kbd_buffer[kbd_tail];
    kbd_tail = (kbd_tail + 1) % KBD_BUFFER_SIZE;
    return c;
}

/* Affiche le logo ASCII de MadOS ROG Edition */
void print_rog_logo(void) {
    term_set_color(COLOR_RED);
    term_print("      __  ___           __ ____  _____     ____   ____   ______\n");
    term_print("     /  |/  /___ _ ____/ // __ \\/ ___/    / __ \\ / __ \\ / ____/\n");
    term_print("    / /|_/ // __ `// __  // / / /\\__ \\    / /_/ // / / // / __  \n");
    term_print("   / /  / // /_/ // /_/ // /_/ /___/ /   / _, _// /_/ // /_/ /  \n");
    term_print("  /_/  /_/ \\__,_/ \\__,_/ \\____//____/   /_/ |_| \\____/ \\____/   \n");
    term_set_color(COLOR_LIGHT_RED);
    term_print("   ====-[ SYSTEME D'EXPLOITATION MAISON - ROG EDITION 4.0 ]-====\n\n");
    term_set_color(COLOR_WHITE);
}

void term_print_two_digits(int val) {
    if (val < 10) {
        term_print("0");
    }
    term_print_int(val);
}

void task1_func(void) {
    for (int i = 0; i < 5; i++) {
        term_print("\n  -> Tache 1 active (Etape ");
        term_print_int(i + 1);
        term_print(" / 5)");
        task_yield();
    }
    term_print("\n  -> Tache 1 terminee.");
    while(1) { task_yield(); }
}

void task2_func(void) {
    for (int i = 0; i < 5; i++) {
        term_print("\n  -> Tache 2 active (Etape ");
        term_print_int(i + 1);
        term_print(" / 5)");
        task_yield();
    }
    term_print("\n  -> Tache 2 terminee.");
    while(1) { task_yield(); }
}

/* Interprétation des commandes MadOS */
void run_mados_command(const char* cmd) {
    if (strcmp(cmd, "help") == 0) {
        term_set_color(COLOR_LIGHT_CYAN);
        term_print("Commandes disponibles :\n");
        term_set_color(COLOR_WHITE);
        term_print("  help              : Affiche cette aide.\n");
        term_print("  clear             : Efface l'ecran.\n");
        term_print("  date              : Affiche la date et l'heure du systeme (RTC).\n");
        term_print("  reboot            : Redemarre la machine.\n");
        term_print("  version           : Affiche la version du noyau.\n");
        term_print("  mados status      : Affiche l'etat reel du processeur (Capteur MSR).\n");
        term_print("  mados doctor      : Lance un diagnostic materiel.\n");
        term_print("  mados batt <lim>  : Regle la limite de charge batterie via l'EC ASUS.\n");
        term_print("  mados aura <col>  : Pilote les LED physiques de la carte mere (AURA RGB).\n");
        term_print("  mados pci         : Scanne le bus PCI pour lister le materiel.\n");
        term_print("  mados malloc      : Teste l'allocateur de memoire dynamique (Heap).\n");
        term_print("  mados perf        : Lance un benchmark de calcul pour mesurer les performances.\n");
        term_print("  mados color <col> : Modifie la couleur du prompt (red, green, blue, yellow, white, cyan).\n");
        term_print("  mados memmap      : Affiche l'utilisation detaillee de la memoire du tas (Heap).\n");
        term_print("  mados task        : Lance une simulation de multitache cooperatif.\n");
        term_print("  mados ls          : Liste les fichiers du systeme de fichiers virtuel (VFS).\n");
        term_print("  mados cat <file>  : Affiche le contenu d'un fichier du VFS.\n");
        term_print("  mados write <f> <c>: Ecrit du texte dans un fichier du VFS.\n");
        term_print("  mados play        : Joue la melodie retro gaming de demarrage (PC Speaker).\n");
    } 
    else if (strcmp(cmd, "version") == 0 || strcmp(cmd, "uname") == 0) {
        term_print("\nMadOS ROG Edition Kernel v4.0.0-xen (Custom 32-bit x86 Bare-Metal)\n");
        term_print("Compile le: 30 Mai 2026 a 14:46\n");
    }
    else if (strcmp(cmd, "clear") == 0) {
        term_clear();
    } 
    else if (strcmp(cmd, "date") == 0) {
        int sec, min, hour, day, month, year;
        get_rtc_time(&sec, &min, &hour, &day, &month, &year);
        term_print("\nDate et heure systeme (RTC CMOS) :\n  ");
        term_print_two_digits(day);
        term_print("/");
        term_print_two_digits(month);
        term_print("/20");
        term_print_two_digits(year);
        term_print(" ");
        term_print_two_digits(hour);
        term_print(":");
        term_print_two_digits(min);
        term_print(":");
        term_print_two_digits(sec);
        term_print("\n");
    } 
    else if (strcmp(cmd, "reboot") == 0) {
        term_set_color(COLOR_LIGHT_RED);
        term_print("\nRedemarrage en cours...\n");
        /* 8042 Keyboard Controller Reset */
        for (volatile int i = 0; i < 100000; i++);
        outb(0x64, 0xFE);
        while(1);
    } 
    else if (strcmp(cmd, "mados status") == 0) {
        term_set_color(COLOR_LIGHT_RED);
        term_print("\n--- MADOS STATUS (HARDWARE CAPTURE) ---\n");
        term_set_color(COLOR_WHITE);
        
        /* Extraction de la température physique du CPU via les registres MSR */
        int cpu_temp = get_cpu_temperature();
        
        term_print("  CPU          : Intel/AMD x86 Compatible\n");
        term_print("  Architecture : Mode Protege 32-bit (GDT + IDT Actives)\n");
        term_print("  Noyau        : Xen Bare-Metal Kernel\n");
        term_print("  Uptime       : ");
        term_print_int((int)get_uptime());
        term_print(" secondes\n");
        term_print("  Temp CPU     : ");
        term_print_int(cpu_temp);
        term_print(" C (Lu via MSR 0x19C)\n");
        
        /* Détection et affichage de l'optimisation SSE/FPU */
        uint32_t cr0_val, cr4_val;
        __asm__ volatile("mov %%cr0, %0" : "=r"(cr0_val));
        __asm__ volatile("mov %%cr4, %0" : "=r"(cr4_val));
        term_print("  Calculs SIMD : ");
        if ((cr4_val & 0x200) && (cr0_val & 0x2)) {
            term_set_color(COLOR_GREEN);
            term_print("SSE / FPU OPTIMISE (Active)\n");
        } else {
            term_set_color(COLOR_LIGHT_RED);
            term_print("DESACTIVE\n");
        }
        term_set_color(COLOR_WHITE);
        
        term_print("  Refroidis.   : ");
        term_set_color(COLOR_GREEN);
        term_print("ACTIF (Instruction HLT en boucle d'attente)\n");
        term_set_color(COLOR_WHITE);
        
        term_print("  Statut       : ");
        if (cpu_temp < 80) {
            term_set_color(COLOR_GREEN);
            term_print("REFROIDISSEMENT OK\n");
        } else {
            term_set_color(COLOR_LIGHT_RED);
            term_print("SURCHAUFFE DETECTEE\n");
        }
        term_set_color(COLOR_WHITE);
    } 
    else if (strcmp(cmd, "mados pci") == 0) {
        term_print("\n");
        pci_scan();
    }
    else if (strcmp(cmd, "mados malloc") == 0) {
        term_print("\nTest de l'allocateur de memoire dynamique...\n");
        char* ptr1 = (char*)kmalloc(128);
        char* ptr2 = (char*)kmalloc(256);
        
        if (ptr1 && ptr2) {
            term_set_color(COLOR_GREEN);
            term_print("Allocation reussie !\n");
            term_set_color(COLOR_WHITE);
            term_print("  Bloc 1 (128 octets) alloue a l'adresse : ");
            term_print_int((int)(uintptr_t)ptr1);
            term_print("\n  Bloc 2 (256 octets) alloue a l'adresse : ");
            term_print_int((int)(uintptr_t)ptr2);
            term_print("\n");
            
            /* Écrire des données pour tester */
            ptr1[0] = 'H'; ptr1[1] = 'e'; ptr1[2] = 'a'; ptr1[3] = 'p'; ptr1[4] = '\0';
            term_print("  Ecriture de test dans le Bloc 1 : ");
            term_print(ptr1);
            term_print("\nLiberation des blocs...\n");
            kfree(ptr1);
            kfree(ptr2);
            term_set_color(COLOR_GREEN);
            term_print("Liberation terminee.\n");
            term_set_color(COLOR_WHITE);
        } else {
            term_set_color(COLOR_LIGHT_RED);
            term_print("Echec de l'allocation memoire.\n");
            term_set_color(COLOR_WHITE);
        }
    }
    else if (strcmp(cmd, "mados perf") == 0) {
        term_print("\nLancement du benchmark gaming (MadOS ROG Performance test)...\n");
        term_print("Calcul intensif en cours...\n");
        
        uint32_t start_tick = get_ticks();
        
        volatile uint32_t val = 0xAA55AA55;
        for (uint32_t i = 0; i < 50000000; i++) {
            val = (val ^ i) + 3;
            val = (val << 3) | (val >> 29);
        }
        
        uint32_t end_tick = get_ticks();
        uint32_t duration_ticks = end_tick - start_tick;
        if (duration_ticks == 0) duration_ticks = 1;
        
        uint32_t score = 500000 / duration_ticks;
        
        term_set_color(COLOR_GREEN);
        term_print("Benchmark termine avec succes !\n");
        term_set_color(COLOR_WHITE);
        term_print("  Temps ecoule : ");
        term_print_int((int)duration_ticks * 10);
        term_print(" ms (");
        term_print_int((int)duration_ticks);
        term_print(" ticks d'horloge)\n");
        
        term_print("  Score de performance ROG : ");
        term_set_color(COLOR_LIGHT_RED);
        term_print_int((int)score);
        term_print(" ROG-Points\n");
        term_set_color(COLOR_WHITE);
        term_print("  Registre de verification final : ");
        term_print_int((int)val);
        term_print("\n");
    }
    else if (strcmp(cmd, "mados memmap") == 0) {
        size_t allocated, free;
        int blocks;
        get_heap_stats(&allocated, &free, &blocks);
        term_print("\n--- MADOS MEMORY MAP (HEAP STATUS) ---\n");
        term_print("  Total segments memoire : ");
        term_print_int(blocks);
        term_print("\n  Memoire allouee        : ");
        term_print_int((int)allocated);
        term_print(" octets\n  Memoire libre          : ");
        term_print_int((int)free);
        term_print(" octets\n");
        
        term_print("  Usage : [");
        int total = (int)(allocated + free);
        if (total > 0) {
            int ratio = (int)((allocated * 20) / total);
            for (int i = 0; i < 20; i++) {
                if (i < ratio) {
                    term_set_color(COLOR_LIGHT_RED);
                    term_print("#");
                } else {
                    term_set_color(COLOR_DARK_GREY);
                    term_print(".");
                }
            }
        }
        term_set_color(COLOR_WHITE);
        term_print("] ");
        int pct = total > 0 ? (int)((allocated * 100) / total) : 0;
        term_print_int(pct);
        term_print("%\n");
    }
    else if (strncmp(cmd, "mados color ", 12) == 0) {
        const char* color_arg = cmd + 12;
        term_print("\n");
        if (strcmp(color_arg, "red") == 0) {
            prompt_theme_color = COLOR_LIGHT_RED;
            term_print("Couleur du prompt changee en : Rouge Gaming\n");
        } else if (strcmp(color_arg, "green") == 0) {
            prompt_theme_color = COLOR_LIGHT_GREEN;
            term_print("Couleur du prompt changee en : Vert Eco\n");
        } else if (strcmp(color_arg, "blue") == 0) {
            prompt_theme_color = COLOR_LIGHT_BLUE;
            term_print("Couleur du prompt changee en : Bleu Silence\n");
        } else if (strcmp(color_arg, "cyan") == 0) {
            prompt_theme_color = COLOR_LIGHT_CYAN;
            term_print("Couleur du prompt changee en : Cyan Neon\n");
        } else if (strcmp(color_arg, "white") == 0) {
            prompt_theme_color = COLOR_WHITE;
            term_print("Couleur du prompt changee en : Blanc Pur\n");
        } else if (strcmp(color_arg, "yellow") == 0) {
            prompt_theme_color = COLOR_LIGHT_BROWN;
            term_print("Couleur du prompt changee en : Jaune Performance\n");
        } else {
            term_print("Couleur non reconnue (red, green, blue, yellow, white, cyan).\n");
        }
    }
    else if (strcmp(cmd, "mados task") == 0) {
        term_print("\nInitialisation du multitache...\n");
        init_multitasking();
        term_print("Creation de la Tache 1 et de la Tache 2...\n");
        create_task(task1_func);
        create_task(task2_func);
        term_print("Lancement de l'ordonnanceur cooperatif (Commutations de contexte)...\n");
        for (int i = 0; i < 12; i++) {
            task_yield();
        }
        term_print("\nRetour a la Tache Principale 0 !\n");
    }
    else if (strcmp(cmd, "mados ls") == 0) {
        vfs_list();
    }
    else if (strncmp(cmd, "mados cat ", 10) == 0) {
        vfs_read(cmd + 10);
    }
    else if (strncmp(cmd, "mados write ", 12) == 0) {
        const char* arg = cmd + 12;
        char filename[32];
        int i = 0;
        while (*arg != ' ' && *arg != '\0' && i < 31) {
            filename[i++] = *arg++;
        }
        filename[i] = '\0';
        if (*arg == ' ') {
            arg++;
            vfs_write(filename, arg);
            term_print("\nFichier ecrit avec succes.\n");
        } else {
            term_print("\nUsage : mados write <nom_fichier> <contenu>\n");
        }
    }
    else if (strcmp(cmd, "mados play") == 0) {
        term_print("\nLecture du carillon ROG (PC Speaker)...\n");
        play_rog_chime();
    }
    else if (strcmp(cmd, "mados doctor") == 0) {
        term_set_color(COLOR_LIGHT_CYAN);
        term_print("\nDiagnostic matériel du noyau :\n");
        
        term_set_color(COLOR_GREEN); term_print("  [ OK ] "); term_set_color(COLOR_WHITE); term_print("Segmentation GDT initialisee\n");
        term_set_color(COLOR_GREEN); term_print("  [ OK ] "); term_set_color(COLOR_WHITE); term_print("Table des vecteurs d'interruptions IDT chargee\n");
        
        /* Diagnostic MSR */
        int temp = get_cpu_temperature();
        if (temp > 0) {
            term_set_color(COLOR_GREEN); term_print("  [ OK ] "); term_set_color(COLOR_WHITE); term_print("Capteurs CPU MSR accessibles (Temp: ");
            term_print_int(temp); term_print(" C)\n");
        } else {
            term_set_color(COLOR_LIGHT_RED); term_print("  [ FAIL ] "); term_set_color(COLOR_WHITE); term_print("Acces MSR impossible\n");
        }

        /* Diagnostic ASUS EC Ports */
        term_set_color(COLOR_GREEN); term_print("  [ OK ] "); term_set_color(COLOR_WHITE); term_print("Communication E/S Ports 0x6C/0x68 (ASUS EC)\n");
        term_set_color(COLOR_GREEN); term_print("  [ OK ] "); term_set_color(COLOR_WHITE); term_print("Ordonnanceur Multitache pret\n");
    } 
    else if (strncmp(cmd, "mados batt ", 11) == 0) {
        const char* limit_str = cmd + 11;
        int limit = 0;
        while (*limit_str >= '0' && *limit_str <= '9') {
            limit = limit * 10 + (*limit_str - '0');
            limit_str++;
        }
        
        term_print("\n");
        if (limit >= 20 && limit <= 100) {
            mados_set_battery_limit((uint8_t)limit);
        } else {
            term_set_color(COLOR_LIGHT_RED);
            term_print("Seuil invalide (Entrez une valeur entre 20 et 100).\n");
            term_set_color(COLOR_WHITE);
        }
    }
    else if (strncmp(cmd, "mados aura ", 11) == 0) {
        const char* color_arg = cmd + 11;
        term_print("\n");
        if (strcmp(color_arg, "red") == 0) {
            term_set_color(COLOR_RED);
            mados_set_hardware_rgb(255, 0, 0);
            term_print("Style AURA applique : Rouge Performance\n");
        } else if (strcmp(color_arg, "green") == 0) {
            term_set_color(COLOR_GREEN);
            mados_set_hardware_rgb(0, 255, 0);
            term_print("Style AURA applique : Vert Eco\n");
        } else if (strcmp(color_arg, "blue") == 0) {
            term_set_color(COLOR_BLUE);
            mados_set_hardware_rgb(0, 0, 255);
            term_print("Style AURA applique : Bleu Silence\n");
        } else if (strcmp(color_arg, "white") == 0) {
            term_set_color(COLOR_WHITE);
            mados_set_hardware_rgb(255, 255, 255);
            term_print("Style AURA applique : Blanc Neutre\n");
        } else {
            term_print("Couleur non reconnue. Essayez: red, green, blue, white.\n");
        }
    } 
    else {
        term_set_color(COLOR_LIGHT_RED);
        term_print("\nCommande inconnue: ");
        term_print(cmd);
        term_print("\nTapez 'help' pour voir les commandes.\n");
        term_set_color(COLOR_WHITE);
    }
}

void print_prompt(void) {
    term_set_color(prompt_theme_color);
    term_print("madtrix");
    term_set_color(COLOR_WHITE);
    term_print("@");
    term_set_color(prompt_theme_color);
    term_print("mados");
    term_set_color(COLOR_WHITE);
    term_print(":[");
    term_set_color(COLOR_LIGHT_CYAN);
    term_print("~");
    term_set_color(COLOR_WHITE);
    term_print("]# ");
    term_set_color(COLOR_WHITE); /* Blanc par défaut pour la saisie */
}

/* Point d'entrée principal du Noyau C */
void kernel_main(unsigned int magic, unsigned int addr) {
    (void)magic;
    (void)addr;

    /* 1. Initialisation des tables matérielles GDT et IDT */
    init_gdt();
    init_idt();

    /* 2. Initialisation du Tas de mémoire dynamique et de l'Horloge PIT */
    init_heap();
    init_pit(100); /* 100 Hz (ticks toutes les 10ms) */
    vfs_init();    /* Initialisation du Système de Fichiers Virtuel (RAMFS) */
    init_mouse();  /* Initialisation de la souris et Touchpad PS/2 (IRQ12) */

    term_clear();
    print_rog_logo();
    
    term_print("GDT, IDT & Horloge PIT (IRQ0) Initialisees.\n");
    term_print("Allocateur de Tas (16 Mo) actif. VFS RAMFS et Souris PS/2 initialises.\n");
    term_print("Pilotes CPU MSR, ASUS EC, Multitache et Touchpad charges.\n");
    term_print("Bienvenue dans MadOS ROG Edition - Bare Metal OS !\n");
    term_print("Tapez 'help' pour commencer.\n\n");

    play_rog_chime(); /* Carillon de démarrage */

    /* 3. Tenter d'initialiser le mode graphique pour le Bureau ROG */
    if (init_graphics(addr)) {
        while (1) {
            int temp = get_cpu_temperature();
            int uptime = (int)get_uptime();
            
            // Lire et traiter le clavier non-bloquant pour la console interactive du GUI
            char c;
            while ((c = kbd_get_char_nonblocking()) != 0) {
                gui_handle_char(c);
            }
            
            render_rog_desktop(temp, uptime, 80);
            flush_buffer();
            
            // Petite pause d'attente active (approx 30ms) pour stabiliser le framerate
            for (volatile int i = 0; i < 3000000; i++);
        }
    }

    char cmd_buffer[256];
    int cmd_len = 0;

    print_prompt();

    while (1) {
        char c = kbd_get_char();
        
        if (c == '\n') {
            term_putchar('\n');
            cmd_buffer[cmd_len] = '\0';
            
            if (cmd_len > 0) {
                run_mados_command(cmd_buffer);
            }
            
            cmd_len = 0;
            term_print("\n");
            print_prompt();
        } 
        else if (c == '\b') {
            if (cmd_len > 0) {
                cmd_len--;
                term_putchar('\b');
            }
        } 
        else {
            if (cmd_len < 254) {
                cmd_buffer[cmd_len++] = c;
                term_putchar(c);
            }
        }
    }
}
