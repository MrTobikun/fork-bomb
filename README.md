# Fork bomb by Okaberin

Code from the book "fork() as Weapons of Mass Destruction"

NASM compiler was used to run the code.

Assembly parameters:
```
nasm -f elf fork_bomb_linux.asm
gcc -m32 fork_bomb_linux.o -o fork_bomb_linux
```

Build platform only Linux.
