# hexdump file -C
NASMPARAMS = -f bin
FAT_PARAMS = -F 12
DISK_SIZE = 2880

bin/%.bin: src/%.asm
	mkdir -p bin
	nasm $(NASMPARAMS) $< -o $@

bin/bootloader.img: bin/bootloader.bin bin/stage2.bin
	dd if=/dev/zero of=$@ bs=1024 count=$(DISK_SIZE) status=progress

	sudo mkfs.vfat $(FAT_PARAMS) $@

	sudo mkdir /mnt/tempdisk
	sudo mount -o loop $@ /mnt/tempdisk

	sudo cp $(word 2, $^) /mnt/tempdisk

	sudo umount /mnt/tempdisk
	sudo rm -rf /mnt/tempdisk
	
	dd if=$@ of=bpb.temp bs=64 seek=0 count=1 conv=notrunc
	dd if=$< of=$@ bs=512 seek=0 count=1 conv=notrunc
	dd if=bpb.temp of=$@ bs=60 seek=0 count=1 conv=notrunc
	
	sudo rm -rf bpb.temp

#-60 bytes por ter BPB no começo

iso/bootloader.img: bin/bootloader.img
	mkdir iso
	cp $^ iso/

hashidaOS.iso: iso/bootloader.img
	genisoimage -quiet -V '$(basename $@)' -input-charset iso8859-1 -o $@ -b $(notdir $<) -hide $(notdir $<) iso/
	rm -rf iso

debug: hashidaOS.iso
	hexdump $< -C

run: hashidaOS.iso
	qemu-system-i386                                 	\
  	-accel tcg,thread=single                       		\
  	-cpu core2duo                                  		\
  	-m 128                                         		\
  	-no-reboot                                     		\
  	-drive format=raw,media=cdrom,file=$<    			\
  	-serial stdio                                  		\
  	-smp 1                                         		\
  	-usb                                           		\
  	-vga std

clean:
	rm -rf bin iso hashidaOS.iso