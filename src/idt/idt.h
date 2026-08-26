#ifndef IDT_H
#define IDT_H

#include <stdint.h>

struct idt_desc {
    uint16_t offset_1; // offset bits 0-15
    uint16_t selector; // GDT selector
    uint8_t zero;
    uint8_t type_attr; // Type and attributes
    uint16_t offset_2; // Offset bits 16-31
} __attribute__((packed));

struct idtr_desc {
    uint16_t limit; // Size of table - 1
    uint32_t base;
} __attribute__((packed));

void idt_init();

#endif
