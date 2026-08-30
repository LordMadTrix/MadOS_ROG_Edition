/* ==============================================================================
   MadOS Hobby OS - mem.c
   Allocateur de mémoire dynamique simple (Tas/Heap)
   ============================================================================== */

#include <stdint.h>
#include <stddef.h>

#define HEAP_START 0x01000000 /* Début du tas à 16 Mo */
#define HEAP_SIZE  0x01000000 /* Taille du tas : 16 Mo */

typedef struct block {
    size_t size;
    int free;
    struct block* next;
} block_t;

static block_t* free_list = (block_t*)HEAP_START;

void init_heap(void) {
    free_list->size = HEAP_SIZE - sizeof(block_t);
    free_list->free = 1;
    free_list->next = NULL;
}

void* kmalloc(size_t size) {
    /* Aligner sur 4 octets */
    size = (size + 3) & ~3;

    block_t* curr = free_list;
    while (curr != NULL) {
        if (curr->free && curr->size >= size) {
            /* Est-ce qu'on peut diviser le bloc ? */
            if (curr->size >= size + sizeof(block_t) + 4) {
                block_t* next_block = (block_t*)((uintptr_t)curr + sizeof(block_t) + size);
                next_block->size = curr->size - size - sizeof(block_t);
                next_block->free = 1;
                next_block->next = curr->next;

                curr->size = size;
                curr->next = next_block;
            }
            curr->free = 0;
            return (void*)((uintptr_t)curr + sizeof(block_t));
        }
        curr = curr->next;
    }
    return NULL; /* Plus de mémoire ! */
}

void kfree(void* ptr) {
    if (ptr == NULL) return;

    block_t* block = (block_t*)((uintptr_t)ptr - sizeof(block_t));
    block->free = 1;

    /* Fusionner les blocs libres consécutifs */
    block_t* curr = free_list;
    while (curr != NULL) {
        if (curr->free && curr->next != NULL && curr->next->free) {
            curr->size += sizeof(block_t) + curr->next->size;
            curr->next = curr->next->next;
            continue; /* Réessayer sur le même bloc fusionné */
        }
        curr = curr->next;
    }
}

void get_heap_stats(size_t* total_allocated, size_t* total_free, int* block_count) {
    *total_allocated = 0;
    *total_free = 0;
    *block_count = 0;

    block_t* curr = free_list;
    while (curr != NULL) {
        (*block_count)++;
        if (curr->free) {
            *total_free += curr->size;
        } else {
            *total_allocated += curr->size;
        }
        curr = curr->next;
    }
}
