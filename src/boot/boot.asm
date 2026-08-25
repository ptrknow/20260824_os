; Set the origin back to 0x7c00 for simplicity
ORG 0x7c00 ; Tells NASM where in memory our program will run
BITS 16    ; 16-bit code

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; The short jump here is preparing for later
_start:
    jmp short start
    nop
    ; Avoid our bootloader code from being overwritten
    ; (BIOS may assume the sector is a BIOS parameter block)
    times 33 db 0

start:
    jmp 0:step2 ; Code segment will be changed to 0x00 with this jmp
                ; such that the origin 0x00 * 16 + 0x7c00 is correct

step2:
    cli             ; disables hardware interrupt
    ; Since origin is 0x7c00, all segment registers should be zero
    mov ax, 0x00
    mov ds, ax      ; set data segment register
    mov es, ax      ; set ext segment register
    mov ss, ax      ; set stack segment register
    mov sp, 0x7c00  ; set stack pointer
    sti             ; enable hardware interrupt

.load_protected:
    cli                  ; Step 1: disable interrupts
    lgdt[gdt_descriptor] ; Step 2: load GDT descriptor
    mov eax, cr0         ; Step 3: set bit 0 to 1 in cr0 register
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32  ; Step 4: perform a far jump
                         ; to clear the prefetch queue,
                         ; and to load CS register with GDT code selector

; GDT format
; bits 0:15  Segment limit (low)
;      16:31 Base (low)
;      32:39 Base (mid)
;      40:47 Access byte
;      48:51 Segment limit (high)
;      52:55 Flag
;      56:63 Base (high) 
; We want to set
; - segment limit to 0xfffff
; - base to 0x0
; - flag with granularity bit on (granularity = 4KB)
; - flag with 32-bit bit on (32-bit protected mode)
; Thus, both code and data selectors will utilize the
; full 4GB memory in 32-bit:
;    (Segment Limit + 1) * Granularity
;  = (0xfffff + 1) * 4KB
;  = 1048576 * 4 * 1024
;  = 4GB
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:        ; CS should point to here
    dw 0xffff    ; Segment limit 0-15 bits
    dw 0         ; Base 0-15 bits
    db 0         ; Base 16-23 bits
    db 0x9a      ; Access byte
    db 11001111b ; Flag 0xC and Segment limit (High) 0xF
    db 0         ; Base 24-31 bits

; offset 0x10
gdt_data:        ; DS, SS, ES, FS, GS
    dw 0xffff    ; Segment limit 0-15 bits
    dw 0         ; Base 0-15 bits
    db 0         ; Base 16-23 bits
    db 0x92      ; Access byte
    db 11001111b ; Flag 0xC and Segment limit (High) 0xF
    db 0         ; Base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of GDT (2 bytes)
    dd gdt_start               ; Base of GDT (4 bytes)

[BITS 32]
load32:
    ; Enable A20 line to access memory beyond 1 MB
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Load the kernel
    mov eax, 1             ; LBA 0 is the boot sector
                           ; LBA 1 is the second sector
    mov ecx, 100           ; load 512 * 100 bytes
    mov edi, 0x0100000     ; memory address to load the sectors into
    call ata_lba_read
    jmp CODE_SEG:0x0100000 ; execute kernel.asm file

ata_lba_read:
    mov ebx, eax ; backup LBA

    ; Send the highest 8 bits of LBA to hard disk controller
    shr eax, 24 ; shift right
    or eax, 0xe0 ; select the master drive
    mov dx, 0x1f6
    out dx, al

    ; Send the total sectors to read
    mov eax, ecx
    mov dx, 0x1f2
    out dx, al

    ; Send the lowest 8 bits of LBA
    mov eax, ebx
    mov dx, 0x1f3
    out dx, al

    ; Send the next higher 8 bits of LBA
    mov dx, 0x1f4
    mov eax, ebx
    shr eax, 8
    out dx, al

    ; Send the remaining upper 8 bits of LBA
    mov dx, 0x1f5
    mov eax, ebx
    shr eax, 16
    out dx, al

    ; Initiate the read cmd
    ; Cmd byte = 0x20, Cmd port = 0x1f7
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

; A loop that reads all sectors into memory
.next_sector:
    push ecx

; A loop that checks if we need to read from disk
.try_again:
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again

    ; Read 256 words (512 bytes) at a time
    mov ecx, 256      ; now ecx is the number words to read
    mov dx, 0x1f0
    rep insw          ; read a word from port 0x1f0 and store it in edi
                      ; repeats this process ecx times, each time decrementing
                      ; ecx and incrementing edi

    pop ecx           ; restore number of sectors in ecx
    loop .next_sector ; decrement ecx, jump to label if ecx is not zero

    ret

times 510-($ - $$) db 0 ; Fill the rest of sectors with zeros, up to 510 bytes

dw 0xAA55 ; The boot sector signature
