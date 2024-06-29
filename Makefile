# Params
NASMPARAMS_16 = -isrc/bootloader/libs/ -f bin
NASMPARAMS_32 = -f elf32
GNUPARAMS = -m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -Wno-write-strings
LDPARAMS = -melf_i386
FAT_PARAMS = -F 12
DISK_SIZE = 2880

# Bootloader Objects
STAGES = $(patsubst src/bootloader/stages/%.asm,build/%.o,$(wildcard src/bootloader/stages/*.asm))

build/%.o: src/bootloader/stages/%.asm
	mkdir -p build
	nasm $(NASMPARAMS_16) $< -o $@

# OS Objects
CPP_SOURCES = $(shell find src/os -type f -name '*.cpp')
ASM_SOURCES = $(shell find src/os -type f -name '*.asm')

OBJECTS = $(patsubst src/os/%.cpp,build/%.o,$(CPP_SOURCES)) $(patsubst src/os/%.asm,build/%.o,$(ASM_SOURCES))

build/%.o: src/os/%.asm
	mkdir -p build
	nasm $(NASMPARAMS_32) $< -o $@

build/%.o: src/os/%.cpp
	mkdir -p build
	gcc $(GNUPARAMS) -o $@ -c $< 

bin/hskernel.bin: linker.ld $(OBJECTS)
	mkdir -p bin
	ld $(LDPARAMS) -T $< -o $@ $(OBJECTS)

# OS Build
bin/bootloader.img: $(STAGES) bin/hskernel.bin
	mkdir -p bin
	dd if=/dev/zero of=$@ bs=1024 count=$(DISK_SIZE) status=progress

	sudo mkfs.vfat $(FAT_PARAMS) $@

	sudo mkdir /mnt/tempdisk
	sudo mount -o loop $@ /mnt/tempdisk

	@for file in $(filter-out build/stage1.o,$^); do \
		sudo cp $$file /mnt/tempdisk; \
	done

	sudo umount /mnt/tempdisk
	sudo rm -rf /mnt/tempdisk
	
	dd if=$@ of=bpb.temp bs=64 seek=0 count=1 conv=notrunc
	dd if=$< of=$@ bs=512 seek=0 count=1 conv=notrunc
	dd if=bpb.temp of=$@ bs=60 seek=0 count=1 conv=notrunc
	
	sudo rm -rf bpb.temp

iso/bootloader.img: bin/bootloader.img
	mkdir iso
	cp $^ iso/

bin/hashidaOS.iso: iso/bootloader.img
	genisoimage -quiet -V '$(basename $@)' -input-charset iso8859-1 -o $@ -b $(notdir $<) -hide $(notdir $<) iso/
	rm -rf iso

# Utils
.PHONY: debug run clean
debug: bin/hashidaOS.iso
	hexdump $< -C

run: bin/hashidaOS.iso
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
	rm -rf build bin iso