
default: hello.exe hello-with-dup.exe memfd.exe

bin: hello.bin hello-with-dup.bin memfd.exe

%.o: %.S
	as --64 -mmnemonic=intel -msyntax=intel -mnaked  $< -o $@

%.exe: %.o
	ld -o $@ $<

%.bin: %.exe
	objcopy -j .text -O binary $< $@

clean:
	-rm -fv hello.o hello.exe hello.bin
	-rm -fv hello-with-dup.o hello-with-dup.exe hello-with-dup.bin
	-rm -fv memfd.o memfd.exe memfd.bin
