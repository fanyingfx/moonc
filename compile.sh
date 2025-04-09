#!/bin/bash
# set -x

cfile=$1
moon run src/main -- $cfile

asmfile="${cfile%.c}.asm"

fasm $asmfile

if [[ "$2" == "run" || "$2" == "r" ]]; then
    elf_file="${cfile%.c}"
    eval "./${elf_file}"
fi
