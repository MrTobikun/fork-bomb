global main

extern malloc

section .text
main:
    while_begin:
        ; system call #2 sys_fork
        mov eax, 2
        int 80h ; in C declared as fork()

        ; memory allocation in bytes
        push 400000
        call malloc
        add esp, 4 ; clean push

        jmp while_begin