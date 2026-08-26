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
add-symbol-file build/kernelfull.o 0x100000
target remote localhost:1234
# Set breakpoint at start of bootloader
break _start

# Continue execution
continue
# Switch to assembler layout
layout asm
# Step through
stepi
```

Raw hexdump:
```
xxd boot.bin
```
