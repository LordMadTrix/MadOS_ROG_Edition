/* ==============================================================================
   MadOS Hobby OS - task.c
   Ordonnanceur de tâches (Multitâche coopératif)
   ============================================================================== */

#include <stdint.h>
#include <stddef.h>

extern void* kmalloc(size_t size);
extern void term_print(const char* str);
extern void term_print_int(int num);

typedef struct task {
    int id;
    uint32_t esp;
    uint32_t ebp;
    uint32_t stack_mem;
    struct task* next;
} task_t;

static task_t* current_task = NULL;
static task_t* task_list = NULL;
static int next_task_id = 1;

void init_multitasking(void) {
    task_t* main_task = (task_t*)kmalloc(sizeof(task_t));
    main_task->id = 0;
    main_task->esp = 0;
    main_task->ebp = 0;
    main_task->stack_mem = 0;
    main_task->next = main_task; // Circulaire
    current_task = main_task;
    task_list = main_task;
}

__attribute__((noinline)) void switch_to_task(task_t* next) {
    if (current_task == next) return;
    
    task_t* prev = current_task;
    current_task = next;
    
    __asm__ volatile(
        "pushfl\n\t"
        "push %%ebp\n\t"
        "push %%edi\n\t"
        "push %%esi\n\t"
        "push %%ebx\n\t"
        "mov %%esp, %0\n\t"
        "mov %1, %%esp\n\t"
        "pop %%ebx\n\t"
        "pop %%esi\n\t"
        "pop %%edi\n\t"
        "pop %%ebp\n\t"
        "popfl\n\t"
        : "=m"(prev->esp)
        : "m"(next->esp)
        : "memory"
    );
}

void task_yield(void) {
    if (current_task == NULL) return;
    switch_to_task(current_task->next);
}

void create_task(void (*entry)()) {
    task_t* new_task = (task_t*)kmalloc(sizeof(task_t));
    new_task->id = next_task_id++;
    
    uint32_t stack_size = 4096;
    void* stack = kmalloc(stack_size);
    new_task->stack_mem = (uint32_t)stack;
    
    uint32_t* esp = (uint32_t*)((uintptr_t)stack + stack_size);
    
    *(--esp) = (uint32_t)entry; // Point de retour de switch_to_task
    *(--esp) = 0;               // EBP initial
    *(--esp) = 0;               // EDI
    *(--esp) = 0;               // ESI
    *(--esp) = 0;               // EBX
    *(--esp) = 0x200;           // EFLAGS (STI)
    
    new_task->esp = (uint32_t)esp;
    new_task->ebp = 0;
    
    new_task->next = task_list->next;
    task_list->next = new_task;
}

int get_current_task_id(void) {
    if (current_task) return current_task->id;
    return -1;
}
