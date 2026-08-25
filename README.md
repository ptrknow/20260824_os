# Real Mode

Compile bootloader:
`nasm -f bin boot.asm -o boot.bin`

Boot with QEMU:
`qemu-system-x86_64 -hda boot.bin`

Raw hexdump:
`xxd boot.bin`