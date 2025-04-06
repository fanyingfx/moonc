#!/bin/bash
# set -x
cfile=$@
moon run src/main -- $cfile

asmfile="${cfile%.c}.asm"
echo $asmfile

fasm $asmfile