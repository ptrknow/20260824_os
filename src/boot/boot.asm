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
    mov ax, DATA_SEG    ; Step 5: set up segment registers with GDT data selectors
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000 ; Step 6: set up stack pointer
    mov esp, ebp

    ; Enable A20 line to access memory beyond 1 MB
    in al, 0x92
    or al, 2
    out 0x92, al

    jmp $

times 510-($ - $$) db 0 ; Fill the rest of sectors with zeros, up to 510 bytes

dw 0xAA55 ; The boot sector signature
