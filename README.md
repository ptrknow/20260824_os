# Real Mode

Compile:
```
make all
```

Boot with QEMU:
```
make run
```

Boot with QEMU and GDB server:
```
make debug
```

Run GDB in another terminal:
```
gdb

# Inside gdb session
target remote localhost:1234
# Set breakpoint at start of bootloader
break *0x7c00
# Switch to assembler layout
layout asm
# Step through
stepi
```

Raw hexdump:
```
xxd boot.bin
```