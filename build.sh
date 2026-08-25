#!/bin/bash
export PREFIX="$HOME/opt/cross"
export TRAGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
make all
