section .asm

global idt_load
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
