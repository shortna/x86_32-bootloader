# in case shell inherited from environment
SHELL = /bin/sh

# clears out the suffix list .SUFFIXES:
# introduces all suffixes which may be subject to implicit rules in this Makefile.
.SUFFIXES:
.SUFFIXES: .o .asm 

SRC_DIR = src
OBJ_DIR = objects
TARGET_DIR = build

OBJECTS = first_stage.o second_stage.o
TARGET = bootloader

AS = /home/box/code/c/system_stuff/crosscompiler/bin/i686-pc-elf-as
LD = /home/box/code/c/system_stuff/crosscompiler/bin/i686-pc-elf-ld

all: $(TARGET_DIR) $(OBJ_DIR) $(OBJECTS) $(TARGET)

$(TARGET_DIR):
	mkdir $@

$(OBJ_DIR):
	mkdir $@

$(OBJECTS): %.o: $(SRC_DIR)/%.asm
	$(AS) -o $(OBJ_DIR)/$@ $<

$(TARGET): $(patsubst %,$(OBJ_DIR)/%,$(OBJECTS))
	$(LD) -o $(TARGET_DIR)/$@ $^ --Ttext=0x7C00 --oformat=binary

clean:
	$(RM) -r $(TARGET_DIR) $(OBJ_DIR)
