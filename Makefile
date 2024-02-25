NASMPARAMS = -f bin

bin/bootloader.bin: src/bootloader.asm
	mkdir -p bin
	nasm $(NASMPARAMS) $< -o $@

bin/bootloader.img: bin/bootloader.bin
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ seek=0 count=1 conv=notrunc

iso/bootloader.img: bin/bootloader.img
	mkdir iso
	cp $< iso/

hashidaOS.iso: iso/bootloader.img
	genisoimage -quiet -V '$(basename $@)' -input-charset iso8859-1 -o $@ -b $(notdir $<) -hide $(notdir $<) iso/
	rm -rf iso

clean:
	rm -rf bin iso hashidaOS.iso