/* ==============================================================================
   MadOS Hobby OS - gui.c
   Moteur Graphique VESA LFB & Bureau Gaming ROG (800x600x32bpp)
   ============================================================================== */

#include <stdint.h>
#include <stddef.h>

extern void* kmalloc(size_t size);
extern void get_mouse_state(int* x, int* y, uint8_t* buttons);

// Dimensions (Gérées de façon dynamique via VESA/Multiboot)
int scr_width = 1024;
int scr_height = 768;

// Couleurs en format 32-bit (ARGB / XRGB)
#define COLOR_DARK_BG   0x1E1E1E
#define COLOR_ROG_RED   0xE60012
#define COLOR_LIGHT_RED 0xFF4D4D
#define COLOR_WHITE     0xFFFFFF
#define COLOR_GREY      0x4A4A4A
#define COLOR_DARK_GREY 0x2A2A2A
#define COLOR_WINDOW_BG 0x2D2D2D
#define COLOR_WINDOW_HDR 0x1A1A1A
#define COLOR_CYAN      0x00E5FF

static uint32_t* framebuffer = NULL;
static uint32_t* backbuffer = NULL;
static uint32_t pitch_pixels = 1024;

typedef struct {
    const char* title;
    int x;
    int y;
    int w;
    int h;
    int is_dragging;
    int drag_x;
    int drag_y;
    int active;
} gui_window_t;

static gui_window_t win_monitor = {
    .title = "System Monitor",
    .x = 20,
    .y = 100,
    .w = 360,
    .h = 220,
    .is_dragging = 0,
    .drag_x = 0,
    .drag_y = 0,
    .active = 1
};

static gui_window_t win_console = {
    .title = "ROG Game Console",
    .x = 420,
    .y = 100,
    .w = 360,
    .h = 220,
    .is_dragging = 0,
    .drag_x = 0,
    .drag_y = 0,
    .active = 1
};

static gui_window_t win_explorer = {
    .title = "ROG File Explorer",
    .x = 220,
    .y = 330,
    .w = 360,
    .h = 220,
    .is_dragging = 0,
    .drag_x = 0,
    .drag_y = 0,
    .active = 1
};

static int explorer_selected_file = 0;

static gui_window_t win_opengl = {
    .title = "ROG GL 3D Engine",
    .x = 600,
    .y = 330,
    .w = 380,
    .h = 220,
    .is_dragging = 0,
    .drag_x = 0,
    .drag_y = 0,
    .active = 1
};

static gui_window_t* window_stack[4] = {
    &win_monitor,
    &win_console,
    &win_explorer,
    &win_opengl
};
static int start_menu_open = 0;

typedef struct {
    float x, y, z;
} vec3_t;

typedef struct {
    int x, y;
} vec2_t;

static const vec3_t cube_vertices[8] = {
    {-1.0f, -1.0f, -1.0f},
    { 1.0f, -1.0f, -1.0f},
    { 1.0f,  1.0f, -1.0f},
    {-1.0f,  1.0f, -1.0f},
    {-1.0f, -1.0f,  1.0f},
    { 1.0f, -1.0f,  1.0f},
    { 1.0f,  1.0f,  1.0f},
    {-1.0f,  1.0f,  1.0f}
};

static const int cube_edges[12][2] = {
    {0, 1}, {1, 2}, {2, 3}, {3, 0},
    {4, 5}, {5, 6}, {6, 7}, {7, 4},
    {0, 4}, {1, 5}, {2, 6}, {3, 7}
};

static vec3_t rotate_3d(vec3_t p, float ax, float ay, float az);
static vec2_t project_3d(vec3_t p, int cx, int cy, float scale, float fov);
void draw_line(int x0, int y0, int x1, int y1, uint32_t color);

static char gui_cmd_buffer[32];
static int gui_cmd_len = 0;
static char gui_console_history[4][40] = {
    "ROG Console Ready. Type cmd:",
    "ex: play, temp, uptime, clear",
    "------------------------------",
    "system online."
};

// Police 8x8 compacte pour les caractères ASCII de base
// Chaque ligne représente les 8 pixels horizontaux d'un caractère
static const uint8_t font_8x8[128][8] = {
    [0x20] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // Espace
    [0x2d] = {0x00, 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00}, // -
    [0x2e] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00}, // .
    [0x2f] = {0x00, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x00}, // /
    [0x30] = {0x3e, 0x66, 0x6e, 0x76, 0x66, 0x66, 0x3e, 0x00}, // 0
    [0x31] = {0x18, 0x1c, 0x18, 0x18, 0x18, 0x18, 0x7e, 0x00}, // 1
    [0x32] = {0x3e, 0x66, 0x06, 0x1c, 0x30, 0x62, 0x7e, 0x00}, // 2
    [0x33] = {0x3e, 0x66, 0x06, 0x1e, 0x06, 0x66, 0x3e, 0x00}, // 3
    [0x34] = {0x0c, 0x1c, 0x3c, 0x6c, 0x7e, 0x0c, 0x0c, 0x00}, // 4
    [0x35] = {0x7e, 0x60, 0x7c, 0x06, 0x06, 0x66, 0x3e, 0x00}, // 5
    [0x36] = {0x3e, 0x60, 0x7c, 0x66, 0x66, 0x66, 0x3e, 0x00}, // 6
    [0x37] = {0x7e, 0x66, 0x06, 0x0c, 0x18, 0x18, 0x18, 0x00}, // 7
    [0x38] = {0x3e, 0x66, 0x66, 0x3e, 0x66, 0x66, 0x3e, 0x00}, // 8
    [0x39] = {0x3e, 0x66, 0x66, 0x3e, 0x06, 0x06, 0x3e, 0x00}, // 9
    [0x3a] = {0x00, 0x18, 0x18, 0x00, 0x00, 0x18, 0x18, 0x00}, // :
    [0x3c] = {0x00, 0x0e, 0x1c, 0x38, 0x1c, 0x0e, 0x00, 0x00}, // <
    [0x3d] = {0x00, 0x00, 0x7e, 0x00, 0x7e, 0x00, 0x00, 0x00}, // =
    [0x3e] = {0x00, 0x70, 0x38, 0x1c, 0x38, 0x70, 0x00, 0x00}, // >
    [0x41] = {0x18, 0x3c, 0x66, 0x66, 0x7e, 0x66, 0x66, 0x00}, // A
    [0x42] = {0x7c, 0x66, 0x66, 0x7c, 0x66, 0x66, 0x7c, 0x00}, // B
    [0x43] = {0x3e, 0x66, 0x60, 0x60, 0x60, 0x66, 0x3e, 0x00}, // C
    [0x44] = {0x78, 0x6c, 0x66, 0x66, 0x66, 0x6c, 0x78, 0x00}, // D
    [0x45] = {0x7e, 0x60, 0x60, 0x7c, 0x60, 0x60, 0x7e, 0x00}, // E
    [0x46] = {0x7e, 0x60, 0x60, 0x7c, 0x60, 0x60, 0x60, 0x00}, // F
    [0x47] = {0x3e, 0x66, 0x60, 0x6e, 0x66, 0x66, 0x3e, 0x00}, // G
    [0x48] = {0x66, 0x66, 0x66, 0x7e, 0x66, 0x66, 0x66, 0x00}, // H
    [0x49] = {0x7e, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7e, 0x00}, // I
    [0x4a] = {0x3e, 0x0c, 0x0c, 0x0c, 0x0c, 0xcc, 0x78, 0x00}, // J
    [0x4b] = {0x66, 0x6c, 0x78, 0x70, 0x78, 0x6c, 0x66, 0x00}, // K
    [0x4c] = {0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x7e, 0x00}, // L
    [0x4d] = {0x63, 0x77, 0x7f, 0x6b, 0x63, 0x63, 0x63, 0x00}, // M
    [0x4e] = {0x63, 0x73, 0x7b, 0x6f, 0x67, 0x63, 0x63, 0x00}, // N
    [0x4f] = {0x3e, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3e, 0x00}, // O
    [0x50] = {0x7c, 0x66, 0x66, 0x7c, 0x60, 0x60, 0x60, 0x00}, // P
    [0x51] = {0x3e, 0x66, 0x66, 0x66, 0x6a, 0x6c, 0x3e, 0x02}, // Q
    [0x52] = {0x7c, 0x66, 0x66, 0x7c, 0x78, 0x6c, 0x66, 0x00}, // R
    [0x53] = {0x3e, 0x66, 0x60, 0x3e, 0x06, 0x66, 0x3e, 0x00}, // S
    [0x54] = {0x7e, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00}, // T
    [0x55] = {0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3e, 0x00}, // U
    [0x56] = {0x66, 0x66, 0x66, 0x66, 0x3c, 0x18, 0x18, 0x00}, // V
    [0x57] = {0x63, 0x63, 0x63, 0x6b, 0x7f, 0x77, 0x63, 0x00}, // W
    [0x58] = {0x66, 0x66, 0x3c, 0x18, 0x3c, 0x66, 0x66, 0x00}, // X
    [0x59] = {0x66, 0x66, 0x66, 0x3c, 0x18, 0x18, 0x18, 0x00}, // Y
    [0x5a] = {0x7e, 0x06, 0x0c, 0x18, 0x30, 0x60, 0x7e, 0x00}, // Z
    [0x5b] = {0x3c, 0x30, 0x30, 0x30, 0x30, 0x30, 0x3c, 0x00}, // [
    [0x5d] = {0x3c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x3c, 0x00}, // ]
    [0x61] = {0x00, 0x3c, 0x06, 0x3e, 0x66, 0x66, 0x3d, 0x00}, // a
    [0x62] = {0x60, 0x60, 0x7c, 0x66, 0x66, 0x66, 0x7c, 0x00}, // b
    [0x63] = {0x00, 0x3e, 0x60, 0x60, 0x60, 0x66, 0x3e, 0x00}, // c
    [0x64] = {0x06, 0x06, 0x3e, 0x66, 0x66, 0x66, 0x3e, 0x00}, // d
    [0x65] = {0x00, 0x3e, 0x66, 0x7e, 0x60, 0x66, 0x3e, 0x00}, // e
    [0x66] = {0x1c, 0x30, 0x30, 0x7c, 0x30, 0x30, 0x30, 0x00}, // f
    [0x67] = {0x00, 0x3e, 0x66, 0x66, 0x3e, 0x06, 0x3c, 0x00}, // g
    [0x68] = {0x60, 0x60, 0x7c, 0x66, 0x66, 0x66, 0x66, 0x00}, // h
    [0x69] = {0x18, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00}, // i
    [0x6a] = {0x0c, 0x00, 0x0c, 0x0c, 0x0c, 0xcc, 0x78, 0x00}, // j
    [0x6b] = {0x60, 0x60, 0x66, 0x6c, 0x78, 0x6c, 0x66, 0x00}, // k
    [0x6c] = {0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x1c, 0x00}, // l
    [0x6d] = {0x00, 0x76, 0x7f, 0x6b, 0x6b, 0x6b, 0x6b, 0x00}, // m
    [0x6e] = {0x00, 0x7c, 0x66, 0x66, 0x66, 0x66, 0x66, 0x00}, // n
    [0x6f] = {0x00, 0x3e, 0x66, 0x66, 0x66, 0x66, 0x3e, 0x00}, // o
    [0x70] = {0x00, 0x7c, 0x66, 0x66, 0x7c, 0x60, 0x60, 0x00}, // p
    [0x71] = {0x00, 0x3e, 0x66, 0x66, 0x3e, 0x06, 0x06, 0x00}, // q
    [0x72] = {0x00, 0x7c, 0x66, 0x60, 0x60, 0x60, 0x60, 0x00}, // r
    [0x73] = {0x00, 0x3e, 0x60, 0x3e, 0x06, 0x66, 0x3e, 0x00}, // s
    [0x74] = {0x30, 0x30, 0x7c, 0x30, 0x30, 0x36, 0x1c, 0x00}, // t
    [0x75] = {0x00, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3e, 0x00}, // u
    [0x76] = {0x00, 0x66, 0x66, 0x66, 0x3c, 0x18, 0x18, 0x00}, // v
    [0x77] = {0x00, 0x63, 0x6b, 0x6b, 0x7f, 0x36, 0x22, 0x00}, // w
    [0x78] = {0x00, 0x66, 0x3c, 0x18, 0x3c, 0x66, 0x66, 0x00}, // x
    [0x79] = {0x00, 0x66, 0x66, 0x66, 0x3e, 0x06, 0x3c, 0x00}, // y
    [0x7a] = {0x00, 0x7e, 0x0c, 0x18, 0x30, 0x60, 0x7e, 0x00}, // z
    [0x40] = {0x3e, 0x66, 0x6f, 0x6b, 0x3b, 0x00, 0x3e, 0x00}, // @
    [0x7e] = {0x00, 0x00, 0x2c, 0x56, 0x32, 0x00, 0x00, 0x00}, // ~
    [0x23] = {0x24, 0x7e, 0x24, 0x24, 0x7e, 0x24, 0x24, 0x00}, // #
    [0x25] = {0x62, 0x66, 0x0c, 0x18, 0x30, 0x66, 0x46, 0x00}, // %
};

// Dessine un pixel
void draw_pixel(int x, int y, uint32_t color) {
    if (x >= 0 && x < scr_width && y >= 0 && y < scr_height) {
        if (backbuffer != NULL) {
            backbuffer[y * scr_width + x] = color;
        } else {
            framebuffer[y * pitch_pixels + x] = color;
        }
    }
}

// Dessine un rectangle plein
void draw_rect(int x, int y, int w, int h, uint32_t color) {
    for (int dy = 0; dy < h; dy++) {
        for (int dx = 0; dx < w; dx++) {
            draw_pixel(x + dx, y + dy, color);
        }
    }
}

// Dessine un caractère
void draw_char(char c, int x, int y, uint32_t color) {
    uint8_t code = (uint8_t)c;
    if (code >= 128) return;
    
    // Obtenir la matrice du caractère
    const uint8_t* glyph = font_8x8[code];
    if (glyph == NULL) return;
    
    for (int cy = 0; cy < 8; cy++) {
        uint8_t row = glyph[cy];
        for (int cx = 0; cx < 8; cx++) {
            if (row & (0x80 >> cx)) {
                // Facteur d'échelle 2x pour une meilleure lisibilité
                draw_pixel(x + cx * 2,     y + cy * 2,     color);
                draw_pixel(x + cx * 2 + 1, y + cy * 2,     color);
                draw_pixel(x + cx * 2,     y + cy * 2 + 1, color);
                draw_pixel(x + cx * 2 + 1, y + cy * 2 + 1, color);
            }
        }
    }
}

// Dessine une chaîne de caractères
void draw_string(const char* str, int x, int y, uint32_t color) {
    while (*str) {
        draw_char(*str, x, y, color);
        x += 16; // 8 pixels * 2 de facteur d'échelle
        str++;
    }
}

// Initialise le framebuffer graphique
int init_graphics(unsigned int multiboot_info_addr) {
    uint32_t* mboot = (uint32_t*)multiboot_info_addr;
    uint32_t flags = mboot[0];
    
    // Vérifier si le framebuffer est disponible (bit 12)
    if (!(flags & (1 << 12))) {
        return 0; // Pas de framebuffer VESA dispo
    }
    
    // Extraire l'adresse linéaire du Framebuffer (offset 88)
    uint32_t fb_addr = mboot[22]; 
    framebuffer = (uint32_t*)fb_addr;
    
    uint32_t width = mboot[25];
    uint32_t height = mboot[26];
    
    if (width != 0 && height != 0) {
        scr_width = width;
        scr_height = height;
    } else {
        framebuffer = (uint32_t*)0xFD000000; // Adresse physique par défaut standard dans QEMU VBE
    }
    
    pitch_pixels = scr_width;
    
    // Allouer la mémoire pour le double buffer dynamiquement
    backbuffer = (uint32_t*)kmalloc(scr_width * scr_height * 4);
    
    return 1;
}

// Copie le backbuffer dans le framebuffer de l'écran en une seule fois
void flush_buffer(void) {
    if (backbuffer == NULL || framebuffer == NULL) return;
    uint32_t* src = backbuffer;
    uint32_t* dst = framebuffer;
    int size = scr_width * scr_height;
    for (int i = 0; i < size; i++) {
        dst[i] = src[i];
    }
}

// Dessine un dégradé de fond ROG (noir vers rouge sombre)
void draw_rog_gradient(void) {
    for (int y = 0; y < scr_height; y++) {
        // Dégradé linéaire du gris très foncé vers le rouge ROG sombre
        uint8_t r = 30 + (y * 40) / scr_height; // 30 -> 70
        uint8_t g = 30 - (y * 20) / scr_height; // 30 -> 10
        uint8_t b = 30 - (y * 20) / scr_height; // 30 -> 10
        uint32_t color = ((uint32_t)r << 16) | ((uint32_t)g << 8) | b;
        for (int x = 0; x < scr_width; x++) {
            draw_pixel(x, y, color);
        }
    }
}

// Dessine le Logo ROG en pixels de façon stylisée au centre
void draw_rog_center_logo(void) {
    int cx = scr_width / 2;
    int cy = scr_height / 2 - 30;
    
    // Dessiner le contour de l'oeil ROG stylisé
    for(int i = -80; i < 80; i++) {
        draw_pixel(cx + i, cy - (i * i) / 200 + 40, COLOR_ROG_RED);
        draw_pixel(cx + i, cy + (i * i) / 300 - 10, COLOR_ROG_RED);
    }
    
    // Dessiner des rectangles décoratifs
    draw_rect(cx - 90, cy - 40, 180, 8, COLOR_ROG_RED);
    draw_rect(cx - 70, cy - 20, 140, 4, COLOR_LIGHT_RED);
}

// Dessine une fenêtre GUI style ROG
void draw_gui_window(const char* title, int x, int y, int w, int h) {
    // Ombre de la fenêtre
    draw_rect(x + 5, y + 5, w, h, 0x0F0F0F);
    // Corps de la fenêtre
    draw_rect(x, y, w, h, COLOR_WINDOW_BG);
    // Barre de titre
    draw_rect(x, y, w, 28, COLOR_WINDOW_HDR);
    // Bordure fine rouge
    for (int i = 0; i < w; i++) {
        draw_pixel(x + i, y, COLOR_ROG_RED);
        draw_pixel(x + i, y + h - 1, COLOR_ROG_RED);
        draw_pixel(x + i, y + 28, COLOR_ROG_RED);
    }
    for (int i = 0; i < h; i++) {
        draw_pixel(x, y + i, COLOR_ROG_RED);
        draw_pixel(x + w - 1, y + i, COLOR_ROG_RED);
    }
    
    // Bouton Fermer (X)
    draw_rect(x + w - 24, y + 6, 16, 16, COLOR_ROG_RED);
    draw_string("X", x + w - 22, y + 6, COLOR_WHITE);
    
    // Titre de la fenêtre
    draw_string(title, x + 10, y + 6, COLOR_WHITE);
}

static void bring_to_front(int stack_idx) {
    if (stack_idx == 3) return; // Déjà au-dessus
    gui_window_t* clicked_win = window_stack[stack_idx];
    for (int i = stack_idx; i < 3; i++) {
        window_stack[i] = window_stack[i + 1];
    }
    window_stack[3] = clicked_win;
}

static void bring_win_to_front(gui_window_t* win) {
    for (int i = 0; i < 4; i++) {
        if (window_stack[i] == win) {
            bring_to_front(i);
            break;
        }
    }
}

// Dessine le Bureau Graphique complet de MadOS et gère l'interaction des fenêtres
void render_rog_desktop(int temp, int uptime, int battery) {
    // 0. Récupérer l'état de la souris
    int mx, my;
    uint8_t m_buttons;
    get_mouse_state(&mx, &my, &m_buttons);
    
    static uint8_t last_buttons = 0;

    int clicked_start = 0;
    int clicked_win = 0;

    // Gérer les clics (transition bouton relâché -> bouton enfoncé)
    if ((m_buttons & 1) && !(last_buttons & 1)) {
        // 1. Clic sur le bouton de menu START (ROG)
        if (mx >= 5 && mx < 85 && my >= scr_height - 35 && my < scr_height - 5) {
            start_menu_open = !start_menu_open;
            clicked_start = 1;
        }

        // 2. Clic à l'intérieur du menu démarrer s'il est ouvert
        if (start_menu_open && !clicked_start &&
            mx >= 5 && mx < 305 && my >= scr_height - 340 && my < scr_height - 40) {
            
            // Clic colonne gauche (Programmes)
            if (mx >= 15 && mx < 175) {
                int item_clicked = (my - (scr_height - 330)) / 40;
                if (item_clicked == 0) { // System Monitor
                    win_monitor.active = 1;
                    bring_win_to_front(&win_monitor);
                } else if (item_clicked == 1) { // ROG Game Console
                    win_console.active = 1;
                    bring_win_to_front(&win_console);
                } else if (item_clicked == 2) { // VFS File Explorer
                    win_explorer.active = 1;
                    bring_win_to_front(&win_explorer);
                } else if (item_clicked == 3) { // GL 3D Engine
                    win_opengl.active = 1;
                    bring_win_to_front(&win_opengl);
                }
                start_menu_open = 0;
            }
            // Clic colonne droite (Actions)
            else if (mx >= 185 && mx < 295) {
                int item_clicked = (my - (scr_height - 330)) / 40;
                if (item_clicked == 0) { // Play Chime
                    extern void play_rog_chime(void);
                    play_rog_chime();
                } else if (item_clicked == 1) { // System Info (re-active tout)
                    win_monitor.active = 1;
                    win_console.active = 1;
                    win_explorer.active = 1;
                    win_opengl.active = 1;
                }
                
                // Bouton Redémarrer en bas de la colonne de droite
                if (my >= scr_height - 75 && my < scr_height - 45) {
                    // Reboot
                    extern void outb(unsigned short port, unsigned char val);
                    outb(0x64, 0xFE);
                }
                start_menu_open = 0;
            }
            clicked_win = 1;
        }

        // Fermer le menu démarrer si clic à l'extérieur
        if (start_menu_open && !clicked_start && !clicked_win) {
            start_menu_open = 0;
        }

        // 3. Clic sur les fenêtres (de haut en bas dans le Z-order)
        if (!clicked_start && !clicked_win) {
            for (int i = 3; i >= 0; i--) {
                gui_window_t* w = window_stack[i];
                if (w->active &&
                    mx >= w->x && mx < w->x + w->w &&
                    my >= w->y && my < w->y + w->h) {
                    
                    bring_to_front(i); // Amener au premier plan
                    clicked_win = 1;
                    
                    // Clic sur le bouton Fermer (X)
                    if (mx >= window_stack[3]->x + window_stack[3]->w - 24 &&
                        mx < window_stack[3]->x + window_stack[3]->w - 8 &&
                        my >= window_stack[3]->y + 6 && my < window_stack[3]->y + 22) {
                        window_stack[3]->active = 0;
                    }
                    // Clic sur la barre de titre pour le drag
                    else if (my >= window_stack[3]->y && my < window_stack[3]->y + 28) {
                        window_stack[3]->is_dragging = 1;
                        window_stack[3]->drag_x = mx - window_stack[3]->x;
                        window_stack[3]->drag_y = my - window_stack[3]->y;
                    }
                    // Clic sur la liste de fichiers (uniquement si c'est win_explorer)
                    else if (window_stack[3] == &win_explorer) {
                        if (mx >= win_explorer.x + 10 && mx < win_explorer.x + 160 &&
                            my >= win_explorer.y + 40 && my < win_explorer.y + 200) {
                            int line_clicked = (my - (win_explorer.y + 40)) / 25;
                            extern int vfs_get_file_count(void);
                            extern int vfs_is_file_active(int index);
                            int active_idx = 0;
                            for (int j = 0; j < vfs_get_file_count(); j++) {
                                if (vfs_is_file_active(j)) {
                                    if (active_idx == line_clicked) {
                                        explorer_selected_file = j;
                                        break;
                                    }
                                    active_idx++;
                                }
                            }
                        }
                    }
                    break; // Empêcher le clic de traverser vers une fenêtre en dessous
                }
            }
        }
    }
    
    // Si bouton gauche relâché, arrêter le drag
    if (!(m_buttons & 1)) {
        win_monitor.is_dragging = 0;
        win_console.is_dragging = 0;
        win_explorer.is_dragging = 0;
        win_opengl.is_dragging = 0;
    }
    
    // Déplacer les fenêtres si drag en cours
    if (m_buttons & 1) {
        if (win_monitor.is_dragging) {
            win_monitor.x = mx - win_monitor.drag_x;
            win_monitor.y = my - win_monitor.drag_y;
        }
        if (win_console.is_dragging) {
            win_console.x = mx - win_console.drag_x;
            win_console.y = my - win_console.drag_y;
        }
        if (win_explorer.is_dragging) {
            win_explorer.x = mx - win_explorer.drag_x;
            win_explorer.y = my - win_explorer.drag_y;
        }
        if (win_opengl.is_dragging) {
            win_opengl.x = mx - win_opengl.drag_x;
            win_opengl.y = my - win_opengl.drag_y;
        }
    }
    
    last_buttons = m_buttons;

    // 1. Dessiner le fond d'écran de jeu ROG
    draw_rog_gradient();
    draw_rog_center_logo();
    
    // Titre du bureau
    draw_string("MADOS ROG GRAPHICAL DESKTOP v4.0", 20, 20, COLOR_WHITE);
    draw_string("Gaming Bare-Metal GUI Mode (Active)", 20, 42, COLOR_CYAN);
    
    // 2. Dessiner les fenêtres selon le Z-order (de bas en haut dans le stack)
    for (int w = 0; w < 4; w++) {
        gui_window_t* win = window_stack[w];
        if (!win->active) continue;
        
        if (win == &win_monitor) {
            draw_gui_window(win_monitor.title, win_monitor.x, win_monitor.y, win_monitor.w, win_monitor.h);
            draw_string("Arch : x86 Protected Mode", win_monitor.x + 15, win_monitor.y + 40, COLOR_WHITE);
            
            draw_string("Temp :", win_monitor.x + 15, win_monitor.y + 70, COLOR_WHITE);
            char temp_str[8];
            temp_str[0] = (temp / 10) + '0';
            temp_str[1] = (temp % 10) + '0';
            temp_str[2] = ' '; temp_str[3] = 'C'; temp_str[4] = '\0';
            draw_string(temp_str, win_monitor.x + 175, win_monitor.y + 70, COLOR_LIGHT_RED);
            
            draw_string("Uptime :", win_monitor.x + 15, win_monitor.y + 100, COLOR_WHITE);
            char upt_str[16];
            int units = uptime % 10;
            int tens = (uptime / 10) % 10;
            int hundreds = (uptime / 100) % 10;
            upt_str[0] = hundreds + '0';
            upt_str[1] = tens + '0';
            upt_str[2] = units + '0';
            upt_str[3] = ' '; upt_str[4] = 's'; upt_str[5] = 'e'; upt_str[6] = 'c'; upt_str[7] = '\0';
            draw_string(upt_str, win_monitor.x + 175, win_monitor.y + 100, COLOR_CYAN);
            
            draw_string("Battery :", win_monitor.x + 15, win_monitor.y + 130, COLOR_WHITE);
            char bat_str[8];
            bat_str[0] = (battery / 10) + '0';
            bat_str[1] = (battery % 10) + '0';
            bat_str[2] = '%'; bat_str[3] = '\0';
            draw_string(bat_str, win_monitor.x + 175, win_monitor.y + 130, COLOR_WHITE);
            
            draw_string("SIMD : SSE / FPU Active", win_monitor.x + 15, win_monitor.y + 160, COLOR_CYAN);
        }
        else if (win == &win_console) {
            draw_gui_window(win_console.title, win_console.x, win_console.y, win_console.w, win_console.h);
            
            // Afficher l'historique
            for (int i = 0; i < 4; i++) {
                draw_string(gui_console_history[i], win_console.x + 15, win_console.y + 40 + i * 25, COLOR_WHITE);
            }
            
            // Afficher ce que tape l'utilisateur
            char input_line[40];
            int k = 0;
            input_line[k++] = '>';
            input_line[k++] = ' ';
            for (int i = 0; i < gui_cmd_len; i++) {
                input_line[k++] = gui_cmd_buffer[i];
            }
            input_line[k++] = '_';
            input_line[k] = '\0';
            draw_string(input_line, win_console.x + 15, win_console.y + 150, COLOR_CYAN);
        }
        else if (win == &win_explorer) {
            draw_gui_window(win_explorer.title, win_explorer.x, win_explorer.y, win_explorer.w, win_explorer.h);
            
            // Séparateur vertical entre la liste de fichiers (gauche) et le contenu (droite)
            for (int i = 28; i < win_explorer.h; i++) {
                draw_pixel(win_explorer.x + 170, win_explorer.y + i, COLOR_ROG_RED);
            }
            
            extern int vfs_get_file_count(void);
            extern int vfs_is_file_active(int index);
            extern const char* vfs_get_filename(int index);
            extern const char* vfs_get_file_content(int index);
            
            // Dessiner la liste des fichiers à gauche
            int active_idx = 0;
            for (int i = 0; i < vfs_get_file_count(); i++) {
                if (vfs_is_file_active(i)) {
                    const char* fname = vfs_get_filename(i);
                    if (fname) {
                        uint32_t color = (explorer_selected_file == i) ? COLOR_CYAN : COLOR_WHITE;
                        if (explorer_selected_file == i) {
                            // Dessiner un petit indicateur de sélection
                            draw_rect(win_explorer.x + 8, win_explorer.y + 42 + active_idx * 25, 4, 12, COLOR_CYAN);
                        }
                        draw_string(fname, win_explorer.x + 18, win_explorer.y + 40 + active_idx * 25, color);
                    }
                    active_idx++;
                }
            }
            
            // Dessiner le contenu du fichier sélectionné à droite
            const char* content = vfs_get_file_content(explorer_selected_file);
            if (content) {
                int line = 0;
                char line_buf[12];
                int char_idx = 0;
                for (int i = 0; content[i] != '\0' && line < 6; i++) {
                    if (content[i] == '\n') {
                        line_buf[char_idx] = '\0';
                        draw_string(line_buf, win_explorer.x + 180, win_explorer.y + 40 + line * 25, COLOR_WHITE);
                        line++;
                        char_idx = 0;
                    } else {
                        if (char_idx < 10) {
                            line_buf[char_idx++] = content[i];
                        }
                        if (char_idx == 10 || content[i+1] == '\0') {
                            line_buf[char_idx] = '\0';
                            draw_string(line_buf, win_explorer.x + 180, win_explorer.y + 40 + line * 25, COLOR_WHITE);
                            line++;
                            char_idx = 0;
                        }
                    }
                }
            } else {
                draw_string("Select file", win_explorer.x + 180, win_explorer.y + 40, COLOR_GREY);
            }
        }
        else if (win == &win_opengl) {
            draw_gui_window(win_opengl.title, win_opengl.x, win_opengl.y, win_opengl.w, win_opengl.h);
            
            // Centre de l'écran 3D (relatif à la fenêtre)
            int cx = win_opengl.x + win_opengl.w / 2;
            int cy = win_opengl.y + 28 + (win_opengl.h - 28) / 2;
            
            // Calcul des angles à partir du temps (uptime / ticks)
            static float ax = 0.0f;
            static float ay = 0.0f;
            static float az = 0.0f;
            ax += 0.04f;
            ay += 0.03f;
            az += 0.015f;
            
            // Projeter les 8 sommets du cube en 2D
            vec2_t projected[8];
            for (int i = 0; i < 8; i++) {
                vec3_t rot = rotate_3d(cube_vertices[i], ax, ay, az);
                projected[i] = project_3d(rot, cx, cy, 55.0f, 2.0f);
            }
            
            // Dessiner les 12 arêtes du cube avec Bresenham
            for (int i = 0; i < 12; i++) {
                int p0 = cube_edges[i][0];
                int p1 = cube_edges[i][1];
                draw_line(projected[p0].x, projected[p0].y, projected[p1].x, projected[p1].y, COLOR_CYAN);
            }
            
            // Dessiner une indication textuelle
            draw_string("MADOS SOFTWARE GL 3D", win_opengl.x + 10, win_opengl.y + 35, COLOR_WHITE);
        }
    }

    // 2.5. Dessiner le menu Démarrer Windows 7 (si ouvert)
    if (start_menu_open) {
        int sm_x = 5;
        int sm_y = scr_height - 340;
        int sm_w = 300;
        int sm_h = 300;
        
        // Ombre et fond du menu (style bleu-gris sombre type Aero Windows 7)
        draw_rect(sm_x + 3, sm_y + 3, sm_w, sm_h, 0x050505);
        draw_rect(sm_x, sm_y, sm_w, sm_h, 0x181824);
        
        // Bordures rouges ROG
        for (int i = 0; i < sm_w; i++) {
            draw_pixel(sm_x + i, sm_y, COLOR_ROG_RED);
            draw_pixel(sm_x + i, sm_y + sm_h - 1, COLOR_ROG_RED);
        }
        for (int i = 0; i < sm_h; i++) {
            draw_pixel(sm_x, sm_y + i, COLOR_ROG_RED);
            draw_pixel(sm_x + sm_w - 1, sm_y + i, COLOR_ROG_RED);
        }
        
        // Colonne de droite (Actions système rapides)
        draw_rect(sm_x + 180, sm_y + 2, 118, sm_h - 4, 0x101018);
        
        // Séparateur vertical
        for (int i = 2; i < sm_h - 2; i++) {
            draw_pixel(sm_x + 179, sm_y + i, COLOR_ROG_RED);
        }
        
        // --- COLONNE DE GAUCHE : Raccourcis Applications (Aero Hover-friendly Layout) ---
        draw_rect(sm_x + 10, sm_y + 10, 160, 32, COLOR_WINDOW_BG);
        draw_string("1. Monitor", sm_x + 20, sm_y + 18, COLOR_WHITE);
        
        draw_rect(sm_x + 10, sm_y + 50, 160, 32, COLOR_WINDOW_BG);
        draw_string("2. Console", sm_x + 20, sm_y + 58, COLOR_WHITE);
        
        draw_rect(sm_x + 10, sm_y + 90, 160, 32, COLOR_WINDOW_BG);
        draw_string("3. VFS Files", sm_x + 20, sm_y + 98, COLOR_WHITE);
        
        draw_rect(sm_x + 10, sm_y + 130, 160, 32, COLOR_WINDOW_BG);
        draw_string("4. GL 3D Cube", sm_x + 20, sm_y + 138, COLOR_WHITE);
        
        // Décoration / Logo ROG en bas à gauche
        draw_string("MADOS ROG OS v4", sm_x + 15, sm_y + 260, COLOR_CYAN);
        
        // --- COLONNE DE DROITE : Système & Raccourcis ---
        draw_string("Play Sound", sm_x + 190, sm_y + 18, COLOR_CYAN);
        draw_string("Show All", sm_x + 190, sm_y + 58, COLOR_CYAN);
        
        // Bouton Arrêt / Redémarrage Windows 7 (Shut down)
        draw_rect(sm_x + 190, sm_y + sm_h - 35, 100, 25, COLOR_ROG_RED);
        draw_string("Reboot", sm_x + 212, sm_y + sm_h - 30, COLOR_WHITE);
    }

    // 4. Dessiner la Barre des Tâches (Taskbar) en bas du bureau
    draw_rect(0, scr_height - 40, scr_width, 40, COLOR_WINDOW_HDR);
    // Ligne supérieure rouge de la barre des tâches
    for (int x = 0; x < scr_width; x++) {
        draw_pixel(x, scr_height - 40, COLOR_ROG_RED);
    }
    
    // Bouton de menu "START"
    draw_rect(5, scr_height - 35, 80, 30, COLOR_ROG_RED);
    draw_string("ROG", 28, scr_height - 28, COLOR_WHITE);
    
    // Zones d'informations à droite de la barre des tâches
    draw_string("UTC Time CMOS RTC", scr_width - 180, scr_height - 28, COLOR_WHITE);
    
    // 5. Récupérer et dessiner le curseur de la souris (par-dessus tout)
    // Dessiner le pointeur
    uint32_t cursor_color = (m_buttons & 1) ? COLOR_CYAN : COLOR_ROG_RED;
    for (int i = 0; i < 15; i++) {
        for (int j = 0; j <= i; j++) {
            if (j == 0 || j == i || i == 14 || (i == 10 && j > 5)) {
                draw_pixel(mx + j, my + i, cursor_color);
            } else {
                draw_pixel(mx + j, my + i, COLOR_WHITE);
            }
        }
    }
    
    // Feedback de clic (petit carré cyan sous le curseur)
    if (m_buttons & 1) {
        draw_rect(mx - 2, my - 2, 4, 4, COLOR_CYAN);
    }
}

// Comparaison de chaînes simple pour la console GUI
static int gui_strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char*)s1 - *(unsigned char*)s2;
}

// Gère la saisie d'un caractère dans la console GUI interactif
void gui_handle_char(char c) {
    if (c == '\n') {
        if (gui_cmd_len > 0) {
            gui_cmd_buffer[gui_cmd_len] = '\0';
            
            // Décaler l'historique vers le haut
            for (int i = 0; i < 3; i++) {
                for (int j = 0; j < 40; j++) {
                    gui_console_history[i][j] = gui_console_history[i+1][j];
                }
            }
            // Ajouter la commande actuelle dans l'historique
            int len = 0;
            gui_console_history[3][len++] = '>';
            gui_console_history[3][len++] = ' ';
            for (int i = 0; i < gui_cmd_len && len < 39; i++) {
                gui_console_history[3][len++] = gui_cmd_buffer[i];
            }
            gui_console_history[3][len] = '\0';
            
            // Traiter la commande
            char response[40] = "";
            if (gui_strcmp(gui_cmd_buffer, "clear") == 0) {
                for (int i = 0; i < 4; i++) {
                    gui_console_history[i][0] = '\0';
                }
            } else if (gui_strcmp(gui_cmd_buffer, "play") == 0) {
                extern void play_rog_chime(void);
                play_rog_chime();
                const char* msg = "Playing ROG chime...";
                int r_len = 0;
                while (*msg && r_len < 39) response[r_len++] = *msg++;
                response[r_len] = '\0';
            } else if (gui_strcmp(gui_cmd_buffer, "temp") == 0) {
                extern int get_cpu_temperature(void);
                int temp = get_cpu_temperature();
                const char* prefix = "CPU Temp: ";
                int r_len = 0;
                while (*prefix && r_len < 39) response[r_len++] = *prefix++;
                response[r_len++] = (temp / 10) + '0';
                response[r_len++] = (temp % 10) + '0';
                response[r_len++] = ' ';
                response[r_len++] = 'C';
                response[r_len] = '\0';
            } else if (gui_strcmp(gui_cmd_buffer, "uptime") == 0) {
                extern uint32_t get_uptime(void);
                int upt = (int)get_uptime();
                const char* prefix = "Uptime: ";
                int r_len = 0;
                while (*prefix && r_len < 39) response[r_len++] = *prefix++;
                
                char ut_str[10];
                int units = upt % 10;
                int tens = (upt / 10) % 10;
                int hundreds = (upt / 100) % 10;
                ut_str[0] = hundreds + '0';
                ut_str[1] = tens + '0';
                ut_str[2] = units + '0';
                ut_str[3] = ' '; ut_str[4] = 's'; ut_str[5] = '\0';
                const char* ps = ut_str;
                while (*ps && r_len < 39) response[r_len++] = *ps++;
                response[r_len] = '\0';
            } else {
                const char* prefix = "Unknown cmd: ";
                int r_len = 0;
                while (*prefix && r_len < 39) response[r_len++] = *prefix++;
                for (int i = 0; i < gui_cmd_len && r_len < 39; i++) {
                    response[r_len++] = gui_cmd_buffer[i];
                }
                response[r_len] = '\0';
            }
            
            if (response[0] != '\0') {
                for (int i = 0; i < 3; i++) {
                    for (int j = 0; j < 40; j++) {
                        gui_console_history[i][j] = gui_console_history[i+1][j];
                    }
                }
                int r_len = 0;
                while (response[r_len] != '\0' && r_len < 39) {
                    gui_console_history[3][r_len] = response[r_len];
                    r_len++;
                }
                gui_console_history[3][r_len] = '\0';
            }
            
            gui_cmd_len = 0;
        }
    } else if (c == '\b') {
        if (gui_cmd_len > 0) {
            gui_cmd_len--;
        }
    } else {
        if (gui_cmd_len < 30 && c >= 32 && c < 127) {
            gui_cmd_buffer[gui_cmd_len++] = c;
        }
    }
}

// Approximations de sinus et cosinus (séries de Taylor simplifiées)
static float mados_sin(float x) {
    while (x > 3.14159f) x -= 6.28318f;
    while (x < -3.14159f) x += 6.28318f;
    float x2 = x * x;
    return x * (1.0f - x2 * (0.166667f - x2 * (0.008333f - x2 * 0.000198f)));
}

static float mados_cos(float x) {
    return mados_sin(x + 1.57079f);
}

// Rotation 3D d'un point
static vec3_t rotate_3d(vec3_t p, float ax, float ay, float az) {
    vec3_t r;
    // Rotation X
    float s = mados_sin(ax), c = mados_cos(ax);
    float y1 = p.y * c - p.z * s;
    float z1 = p.y * s + p.z * c;
    
    // Rotation Y
    s = mados_sin(ay); c = mados_cos(ay);
    float x2 = p.x * c + z1 * s;
    float z2 = -p.x * s + z1 * c;
    
    // Rotation Z
    s = mados_sin(az); c = mados_cos(az);
    r.x = x2 * c - y1 * s;
    r.y = x2 * s + y1 * c;
    r.z = z2;
    return r;
}

// Projection perspective 3D vers 2D
static vec2_t project_3d(vec3_t p, int cx, int cy, float scale, float fov) {
    vec2_t proj;
    float distance = 4.0f;
    float z_depth = p.z + distance;
    if (z_depth <= 0.1f) z_depth = 0.1f;
    proj.x = cx + (int)((p.x * fov * scale) / z_depth);
    proj.y = cy + (int)((p.y * fov * scale) / z_depth);
    return proj;
}

// Dessin de ligne Bresenham
void draw_line(int x0, int y0, int x1, int y1, uint32_t color) {
    int dx = (x1 - x0 >= 0) ? x1 - x0 : x0 - x1;
    int dy = (y1 - y0 >= 0) ? y1 - y0 : y0 - y1;
    int sx = (x0 < x1) ? 1 : -1;
    int sy = (y0 < y1) ? 1 : -1;
    int err = dx - dy;
    
    while (1) {
        draw_pixel(x0, y0, color);
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y0 += sy;
        }
    }
}
