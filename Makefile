NASMPARAMS = -f bin
FAT12_PARAMS = -F 12
DISK_SIZE = 2880

bin/%.bin: src/%.asm
	mkdir -p bin
	nasm $(NASMPARAMS) $< -o $@

bin/bootloader.img: bin/bootloader.bin bin/stg.bin
	dd if=/dev/zero of=$@ bs=1024 count=$(DISK_SIZE) status=progress

#echo -e "o\nn\np\n1\n\n\na\nw\n" | fdisk $@

#sudo losetup -fP $@

	sudo mkfs.vfat $(FAT12_PARAMS) $@

	sudo mkdir /mnt/tempdisk
	sudo mount -o loop $@ /mnt/tempdisk

	sudo cp $(word 2, $^) /mnt/tempdisk

	sudo umount /mnt/tempdisk
	sudo rm -rf /mnt/tempdisk

#sudo losetup -d /dev/loop0
	
	dd if=$< of=$@ bs=512 seek=0 count=1 conv=notrunc

#-60 bytes por ter BPB no começo

iso/bootloader.img: bin/bootloader.img
	mkdir iso
	cp $^ iso/

hashidaOS.iso: iso/bootloader.img
	genisoimage -quiet -V '$(basename $@)' -input-charset iso8859-1 -o $@ -b $(notdir $<) -hide $(notdir $<) iso/
	rm -rf iso

clean:
	rm -rf bin iso hashidaOS.iso