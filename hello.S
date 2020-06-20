        .global _start
        .text
_start:
        call _a
_a:     pop rbx

        // ssize_t write(int fd, const void *buf, size_t count);
        xor eax, eax
        inc eax
        mov edi, eax
        mov rsi, rbx
        add rsi, _msg - _a
        mov edx, _msg_end - _msg
        syscall

        // exit(0)
        mov eax, 0x3c
        xor edi, edi
        syscall

_msg:   
        .ascii "Hello World\n"
_msg_end:       
