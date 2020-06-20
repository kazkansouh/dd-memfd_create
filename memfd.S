        .global _start
        .text
_start:
        call _a
_a:     pop rdi

        // int memfd_create(const char *name, unsigned int flags);
        mov eax, 0x13f                  # rax = 319, memfd_create
        add rdi, _file - _a             # rdi = file name
        xor esi, esi                    # rsi = 0
        syscall                         # memfd_create("FILE", 0)

        // int pause(void);
        mov eax, 0x22                   # rax = 34, pause
        syscall                         # pause()

_file:   .asciz "FILE"
_file_end:       
