format ELF64 executable

segment readable executable
entry _start
_start:
    call main
    mov rdi,rax
    mov rax,60
    syscall

