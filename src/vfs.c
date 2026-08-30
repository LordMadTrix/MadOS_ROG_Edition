/* ==============================================================================
   MadOS Hobby OS - vfs.c
   Système de Fichiers Virtuel (VFS RAMFS)
   ============================================================================== */

#include <stdint.h>
#include <stddef.h>

#define MAX_FILES 16
#define MAX_FILENAME_LEN 32
#define MAX_FILE_SIZE 512

extern void* kmalloc(size_t size);
extern void kfree(void* ptr);
extern void term_print(const char* str);
extern void term_print_int(int num);
extern int strcmp(const char* s1, const char* s2);

typedef struct {
    char name[MAX_FILENAME_LEN];
    char* content;
    size_t size;
    int active;
} vfs_file_t;

static vfs_file_t files[MAX_FILES];
static int file_count = 0;

void vfs_write(const char* name, const char* content);

void vfs_init(void) {
    for (int i = 0; i < MAX_FILES; i++) {
        files[i].active = 0;
    }
    
    // Créer des fichiers par défaut
    vfs_write("motd.txt", "Bienvenue sur MadOS ROG Edition 4.0 !\nSysteme bare-metal ultra-optimise pour le gaming.");
    vfs_write("kernel.cfg", "tuning_latency=ultra_low\nsse_engine=enabled\nfan_speed=100%\nrgb_aura=red");
    vfs_write("credits.txt", "MadOS Developpe par MadTrix.\nPair-programmed avec Antigravity.");
}

void vfs_list(void) {
    term_print("\nListe des fichiers du VFS RAMFS :\n");
    int count = 0;
    for (int i = 0; i < MAX_FILES; i++) {
        if (files[i].active) {
            term_print("  - ");
            term_print(files[i].name);
            term_print(" (");
            term_print_int((int)files[i].size);
            term_print(" octets)\n");
            count++;
        }
    }
    if (count == 0) {
        term_print("  (Aucun fichier)\n");
    }
}

void vfs_read(const char* name) {
    for (int i = 0; i < MAX_FILES; i++) {
        if (files[i].active && strcmp(files[i].name, name) == 0) {
            term_print("\n--- Contenu de ");
            term_print(name);
            term_print(" ---\n");
            term_print(files[i].content);
            term_print("\n----------------\n");
            return;
        }
    }
    term_print("\nErreur : Fichier non trouve.\n");
}

void vfs_write(const char* name, const char* content) {
    // Vérifier si le fichier existe déjà
    for (int i = 0; i < MAX_FILES; i++) {
        if (files[i].active && strcmp(files[i].name, name) == 0) {
            // Libérer l'ancien contenu
            kfree(files[i].content);
            
            // Calculer la taille
            size_t size = 0;
            while (content[size] != '\0' && size < MAX_FILE_SIZE) {
                size++;
            }
            
            files[i].content = (char*)kmalloc(size + 1);
            for (size_t j = 0; j < size; j++) {
                files[i].content[j] = content[j];
            }
            files[i].content[size] = '\0';
            files[i].size = size;
            return;
        }
    }
    
    // Trouver un slot vide
    for (int i = 0; i < MAX_FILES; i++) {
        if (!files[i].active) {
            // Copier le nom
            int name_len = 0;
            while (name[name_len] != '\0' && name_len < (MAX_FILENAME_LEN - 1)) {
                files[i].name[name_len] = name[name_len];
                name_len++;
            }
            files[i].name[name_len] = '\0';
            
            // Copier le contenu
            size_t size = 0;
            while (content[size] != '\0' && size < MAX_FILE_SIZE) {
                size++;
            }
            
            files[i].content = (char*)kmalloc(size + 1);
            for (size_t j = 0; j < size; j++) {
                files[i].content[j] = content[j];
            }
            files[i].content[size] = '\0';
            files[i].size = size;
            files[i].active = 1;
            file_count++;
            return;
        }
    }
    term_print("\nErreur : Espace disque VFS plein.\n");
}

int vfs_get_file_count(void) {
    return MAX_FILES;
}

int vfs_is_file_active(int index) {
    if (index >= 0 && index < MAX_FILES) {
        return files[index].active;
    }
    return 0;
}

const char* vfs_get_filename(int index) {
    if (index >= 0 && index < MAX_FILES && files[index].active) {
        return files[index].name;
    }
    return NULL;
}

const char* vfs_get_file_content(int index) {
    if (index >= 0 && index < MAX_FILES && files[index].active) {
        return files[index].content;
    }
    return NULL;
}

size_t vfs_get_file_size(int index) {
    if (index >= 0 && index < MAX_FILES && files[index].active) {
        return files[index].size;
    }
    return 0;
}
