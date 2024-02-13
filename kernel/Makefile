# in case shell inherited from environment
SHELL = /bin/sh

# clears out the suffix list .SUFFIXES:
# introduces all suffixes which may be subject to implicit rules in this Makefile.
.SUFFIXES: .c

SRC_DIR = src
TARGET_DIR = build
TARGET = kernel

CC = /home/box/code/c/system_stuff/crosscompiler/bin/i686-pc-elf-gcc

all: $(TARGET_DIR) $(TARGET)

$(TARGET_DIR):
	mkdir $@

$(TARGET): $(SRC_DIR)/$(TARGET).c
	$(CC) -o $(TARGET_DIR)/$(TARGET) $^ -nostdlib -ffreestanding -Wall -Wextra -T $(SRC_DIR)/script.ld

clean:
	$(RM) -r $(TARGET_DIR) 
