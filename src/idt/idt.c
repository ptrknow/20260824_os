#include "idt.h"
#include "config.h"
#include "kernel.h"
#include "memory/memory.h"
#include "io/io.h"

struct idt_desc idt_descriptors[TOTAL_INTERRUPTS];
struct idtr_desc idtr_descriptor;

extern void idt_load(struct idtr_desc* ptr);

void idt_zero() {
    print("Divide by zero error\n");
}

void idt_set(int interrupt_no, void *address) {
    struct idt_desc* desc = &idt_descriptors[interrupt_no];
    desc->offset_1  = (uint32_t)address & 0x0000ffff;
    desc->selector  = KERNEL_CODE_SELECTOR;
    desc->zero      = 0x00;
    desc->type_attr = 0xEE;
    desc->offset_2  = (uint32_t)address >> 16;
}

// IDT entry will point to the assembly routine int21h
// as the interrupt handler. This assembly routine
// eventually calls the int21h_handler C function which
// contains the real work of processing the interrupt.
extern void int21h();
extern void no_interrupt();

void int21h_handler() {
    // Read scancode from keyboard controller to drain
    // controller's output buffer. Controller will not
    // raise IRQ1 again until after the buffer is drained.
    unsigned char scancode = insb(0x60);
    (void)scancode;

    print("Keyboard pressed!\n");
    // Ack
    outb(0x20, 0x20);
}

void no_interrupt_handler() {
    // Ack
    outb(0x20, 0x20);
}

void idt_init() {
    memset(idt_descriptors, 0, sizeof(idt_descriptors));
    idtr_descriptor.limit = sizeof(idt_descriptors) - 1;
    idtr_descriptor.base  = (uint32_t) idt_descriptors;

    for (int i = 0; i < TOTAL_INTERRUPTS; i++)
        idt_set(i, no_interrupt);
    idt_set(0, idt_zero);
    idt_set(0x21, int21h);
    idt_load(&idtr_descriptor);
}
