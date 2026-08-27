section .asm

extern int21h_handler
extern no_interrupt_handler

global int21h
global idt_load
global no_interrupt

idt_load:
    ; set up stack frame
    push ebp     ; back up base pointer to previous stack
    mov ebp, esp ; base pointer now points to current stack
                 ; we are free to move esp around

    ; load the first argument to this function
    ; which is expected to be the address of IDT
    mov ebx, [ebp + 8]
    ; load IDT into CPU
    lidt [ebx]

    ; restore stack frame
    pop ebp
    ret

int21h:
    cli
    pushad
    call int21h_handler
    popad
    sti
    iret

no_interrupt:
    cli
    pushad
    call no_interrupt_handler
    popad
    sti
    iret
