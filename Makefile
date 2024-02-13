# in case shell inherited from environment
SHELL = /bin/sh

# clears out the suffix list .SUFFIXES:
# introduces all suffixes which may be subject to implicit rules in this Makefile.
.SUFFIXES: 

TARGET = image

BOOT_LOADER_DIR = ./bloatloader
BOOT_LOADER_PATH = $(BOOT_LOADER_DIR)/build/bootloader

KERNEL_DIR = ./kernel
KERNEL_PATH = $(KERNEL_DIR)/build/kernel

all: make_bootloader make_kernel $(TARGET)

make_bootloader:
	$(MAKE) -C $(BOOT_LOADER_DIR)

make_kernel:
	$(MAKE) -C $(KERNEL_DIR)

$(TARGET): 
	qemu-img create -f raw $@ 64K
	cat $(BOOT_LOADER_PATH) > $@ 
	cat $(KERNEL_PATH) >> $@
	truncate $@ -s 64K

.PHONY: clean distclean qemu

qemu: $(TARGET)
	qemu-system-i386 -nographic -no-reboot -drive file=$^,index=0,format=raw -m 50M -d int,cpu_reset 

clean:
	$(RM) -r $(TARGET)

distclean:
	$(RM) -r $(TARGET) 
	$(MAKE) clean -C $(BOOT_LOADER_DIR)
	$(MAKE) clean -C $(KERNEL_DIR)

