ORG 0      ; Tells NASM where in memory our program will run
BITS 16    ; 16-bit code

start:
    cli             ; disables hardware interrupt
    mov ax, 0x7c0
    mov ds, ax      ; set data segment register
    mov es, ax      ; set ext segment register
    mov ax, 0x00
    mov ss, ax      ; set stack segment register
                    ; to point to the base of IVT
    sti             ; enable hardware interrupt

    ; Set up registers to read from disk
    ; (Read from the second sector just after our boot sector)
    mov bx, 0x0200  ; ES:BX = 0x7c0 * 16 + 0x200 = 0x7e00
    mov ah, 0x02    ; Read from disk CMD
    mov al, 0x01    ; Read one sector (512 bytes)
    mov ch, 0x00    ; Cylinder 0
    mov cl, 0x02    ; Sector 2
    mov dh, 0x00    ; Head 0
    mov dl, 0x80    ; Primary hard drive
    int 0x13        ; Read from disk interrupt

    mov si, 0x200
    call print
    jmp $           ; Infinite loop, GOTO THIS instruction

print:
    mov bx, 0       ; Clear BX register and use it as a counter
.loop:
    lodsb           ; Load the byte at address SI into AL and increment SI
    cmp al, 0       ; Compare value in AL to 0 (end of string)
    je .done        ; If AL is 0, at the end of string
    call print_char ; Otherwise, print the character in AL
    jmp .loop       ; Loop to the next character
.done:
    ret             ; Swap back from IRET to RET

print_char:
    mov ah, 0eh     ; Load the BIOS service number for printing a character
    int 0x10        ; Call BIOS interrupt 0x10 to handle screen operations
    ret             ; Return from the print_char function

div_zero_msg: db 'Divide by zero error!', 0 ; Null-terminated string to be printed

times 510-($ - $$) db 0 ; Fill the rest of sectors with zeros, up to 510 bytes

dw 0xAA55 ; The boot sector signature
