# Real Mode

Create a 2-sector (1024-byte) raw binary virtual hard disk:
```
nasm -f bin boot.asm -o boot.bin
nasm -f bin data.asm -o data.bin
dd if=./boot.bin of=./os.bin
dd if=./data.bin conv=notrunc oflag=append of=./os.bin
```

Boot with QEMU:
```
qemu-system-x86_64 -hda os.bin
```

Raw hexdump:
```
xxd os.bin
```