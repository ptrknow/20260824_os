[BITS 32]
global _start
extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax, DATA_SEG    ; set up segment registers with GDT data selectors
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000 ; set up stack pointer
    mov esp, ebp

    ; Enable A20 line to access memory beyond 1 MB
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Remap the master PIC
    mov al, 00010001b ; Initialization Command Word (ICW)
    out 0x20, al      ; cmd port
    mov al, 0x20      ; Interrupt vector offset
    out 0x21, al      ; data port
    mov al, 00000001b
    out 0x21, al

    ; The slave PIC is ignored

    call kernel_main

    jmp $

times 512-($ - $$) db 0
