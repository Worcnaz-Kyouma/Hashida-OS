NASMPARAMS = -f bin
FAT16_PARAMS = -F 16
DISK_SIZE = 1024

bin/%.bin: src/%.asm
	mkdir -p bin
	nasm $(NASMPARAMS) $< -o $@

bin/bootloader.img: bin/bootloader.bin bin/stg.bin
	dd if=/dev/zero of=$@ bs=1M count=$(DISK_SIZE) status=progress

	echo -e "o\nn\np\n1\n\n\nw\n" | fdisk $@

	sudo losetup -fP $@

	sudo mkfs.vfat $(FAT16_PARAMS) /dev/loop0p1

	sudo mkdir /mnt/tempdisk
	sudo mount /dev/loop0p1 /mnt/tempdisk

	sudo cp $(word 2, $^) /mnt/tempdisk

	sudo umount /mnt/tempdisk
	sudo rm -rf /mnt/tempdisk

	sudo losetup -d /dev/loop0
	
	dd if=$< of=$@ bs=440 seek=0 count=1 conv=notrunc
#440 por usar MBR
#1MiB iniciais nao usados... coisa do windows e linux pelo que vi, ai essas ferramente do seguem

iso/bootloader.img: bin/bootloader.img
	mkdir iso
	cp $^ iso/

hashidaOS.iso: iso/bootloader.img
	genisoimage -quiet -V '$(basename $@)' -input-charset iso8859-1 -hard-disk-boot -o $@ -b $(notdir $<) -hide $(notdir $<) iso/
	rm -rf iso

clean:
	rm -rf bin iso hashidaOS.iso