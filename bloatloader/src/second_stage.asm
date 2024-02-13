.code16

.set KERNEL_ADDRESS, 0x101000
.set GDT_ADDRESS, 0x8200
.set IDT_ADDRESS, 0x8a00

.section .text
  clc           # clear CF (carry flag)
  xorw %ax, %ax # set ax to zero 

  movw $0x7000, %ax
  movw %ax, %SS
  movw $0xFFFF, %sp # reset stack to start position

# check if A20 already enabled
  call check_A20
  cmpb $0x1, %al
  je A20_enabled

# enabling A20
  call enable_A20

# check if A20 enabled successfully
  call check_A20
  cmpb $0x1, %al
  je A20_enabled

# if A20 failed
  pushw $0x0030 # ascii 0
  pushw $error
  jmp print_message
  jmp .
  
  A20_enabled:
    xorw %ax, %ax
    movb $0x31, %ah

    pushw %ax
    pushw $A20_status_msg
    call print_message # it isn`t error, just message in this case

  addw $0x4, %sp # return stack pointer 2 positions back

  call load_kernel
  call collect_system_info

  pushw $0x0
  pushw $wait_enter_press_msg
  call print_message # it isn`t error, just message in this case
  call wait_enter_press

  call enter_protected_mode

########################
#     SYSTEM INFO      #
########################
# system info will reside at 0xF000
collect_system_info:
  pushw %bp
  pushw %di
  pushw %ES
  movw %sp, %bp
  clc

  xorw %di, %di
  movw $0xF01, %ax  # 0xF01 * 0x10 = 0xF010
# first entry would be n elements
  movw %ax, %ES
  movw $0x0, %si

  xorl %ebx, %ebx
  loop_h:
    movl $0xE820, %eax
    movl $0x534D4150, %edx
    movw $0x18, %cx
    int $0x15
    jc system_info_end

    addw $0x18, %di
    movl $0x534D4150, %edx
    cmpl %edx, %eax
    jne system_info_end

    cmpl $0x0, %ebx
    je system_info_end

    inc %si
  jmp loop_h

  system_info_end:
    inc %si
    movw %si, 0xF000

  popw %ES
  popw %di
  popw %bp
  ret

########################
#     LOAD KERNEL      #
########################
load_kernel:
  pushw %bp
  pushw %di
  pushw %si
  pushw %dx
  pushw %cx
  pushw %ES
  movw %sp, %bp

disk_address_packet:
  .byte 0x10 # 16 bytes size of packet
  .byte 0
  .word 20 # n of secotrs
  .long 0x8200 # buffer 
  .quad 3 # absolute start sector number

  movb $0x42, %ah
  movb $0x80, %dl 
  movw $disk_address_packet, %si
  int $0x13

  cmpb $0x0, %ah
  je end
    
# prints read error code
  movb %ah, %al
  pushw %ax
  call byte_to_ascii_hex

  pushw %ax
  pushw $kernel_load_error
  call print_message

# prints error
  xorw %ax, %ax
  pushw %ax
  pushw $error
  call print_message

# falls into infinity
  jmp .

  end:

# source
  movw $0x8200, %si

# destination
  movw $0xFFFF, %ax
  movw %ax, %ES
  movw $0x10, %di

# amount of repeats
  movw $0x1400, %cx # 20 times * 512 bytes / 2
  rep movsw 

  popw %ES
  popw %cx
  popw %dx
  popw %si
  popw %di
  popw %bp
  ret

########################
#     ENABLING A20     #
########################
# check if A20 is enabled
# return 1 if enabled 0 otherwise
check_A20:
  pushw %bp
  pushw %ES
  movw %sp, %bp

# set segment to a value
# using which, with offset, gets address 0x500 (ASSUMING A20 disabled)

# (0xFFFF * 0x10) + 0x510 = 0x100500 (if memory wraps) = 0x500

# ES     = 0xFFFF
# offset = 0x510
# flag   = 0xAE

  movw $0xFFFF, %ax
  movw %ax, %ES

  xorw %ax, %ax
  movb $0x0, 0x500
  movb $0x0, %ES:0x510

  movb $0x0, %al

  movb $0xAE, %ES:0x510
  cmpb $0xAE, 0x500
  je check_A20_end # if equal memory wraps around

  movb $0x1, %al

  check_A20_end:
  popw %ES
  popw %bp
  ret

enable_A20:
  pushw %bp
  movw %sp, %bp

########################################
#         USING BIOS FUNCTION          #
########################################
  mov $0x2401, %ax
  int $0x15

  call check_A20
  cmpb $0x1, %al
  je A20_enable_end

########################################
#    THROUGH KEYBOARD CONTROLLER       #
########################################
  cli # no interrupts
# I will not pretend like i understood this bit of code
# and it (probably) wrong anyway
  call empty_8042
  movb $0xd1, %al # command to write
  outb %al, $0x64
  call empty_8042
  movb $0xdf, %al # A20 on
  outb %al, $0x60
  call empty_8042

  call check_A20
  cmpb $0x1, %al
  je A20_enable_end
  jmp fast_gate_A20

  empty_8042:
    inb $0x64, %al
    testb $0x2, %al
    jnz empty_8042
    ret

########################################
#           FAST A20 GATE              #
########################################

fast_gate_A20:
# 0x92 - port number
  inb $0x92, %al # get input from port
# bit 1 - is 0: disable A20, 1: enable A20.
# test if bit 1 == 1 (check if A20 already enabled)
  testb $0x2, %al # use bitwise "and" and check against 0b0010 (0x2)

# 0b0010 & 0b0010 = 0b0010
# other case
# 0b0010 & 0b0000 = 0b0000 = 0
# thus, jump if not zero
  jnz A20_enable_end 
# enbaling 1 bit 
  orb $0x2, %al # 0bxx0x or 0b0010 = 0bxx1x
# preserve all bits except fast reset bit (bit 0)
  andb $0xFE, %al
  outb %al, $0x92 # output byte to port

  A20_enable_end:
  sti
  popw %bp
  ret

########################
#      MAKE GDT        #
########################
# start of this code = 0x7E00
# gdt will be 1024 bytes past
# 0x7E00 + 0x400 = 0x8200

# GDT memory address = 0x8200

# entry 0 - NULL descriptor
# entry 1 - code descriptor
# entry 2 - data descriptor

make_gdt:
  pushw %bp
  pushw %di
  pushw %cx
  movw %sp, %bp
  
  movw $0,  %ax
  movw %ax, %ES
  movw $GDT_ADDRESS, %di 

  # entry 0
  movw $0x4, %cx
  rep stosw # Fill CX words at ES:[DI] with AX

  # entry 1 - data segment
  movw $0x3200, 0(%di) # lower 2 bytes of limit
  movw $0x0000, 2(%di) # lower 2 bytes of base
  movb $0x00, 4(%di)   # middle byte of base
  movw $0x92, 5(%di)   # access 0b10010010 = 0x92
  movw $0xC0, 6(%di)   # 4 bit flags and 4 bit limit = 0b11000000 = 0xC0
  movw $0x00, 7(%di)   # higher byte of base

  addw $0x8, %di

  # entry 2 - code segment
  movw $0x3200, 0(%di) # lower 2 bytes of limit
  movw $0x0000, 2(%di) # lower 2 bytes of base
  movb $0x00, 4(%di)   # middle byte of base
  movw $0x9A, 5(%di)   # access 0b10011010 = 0x9A
  movw $0xC0, 6(%di)   # 4 bit flags and 4 bit limit = 0b11000000 = 0xC0
  movw $0x00, 7(%di)   # higher byte of base

  gdt:
    .word 24         # size
    .int GDT_ADDRESS # linear address

  lgdt gdt
  
  popw %cx
  popw %di
  popw %bp
  ret

########################
# INT DESCRIPTOR TABLE #
########################
make_idt:
  pushw %bp
  movw %sp, %bp
  idt:
    .word 2048       # size
    .int IDT_ADDRESS # linear address
  
  lidt idt

  popw %bp
  ret

.include "src/misc_functions.asm"

wait_enter_press_msg:
  .ascii "Press 'enter' to enter protected mode \0"

A20_status_msg:
  .ascii "A20 status = \0",

kernel_load_error:
  .ascii "Something went wrong, int 13, error code: \0"

error:
  .ascii "Error occurred, falling into infinity \0",

########################
# ENTER PROTECTED MODE #
########################
enter_protected_mode:
  # set video mode
  movb $0x0, %ah
  movb $0x13, %al
  int $0x10

  cli
  call make_gdt
  call make_idt

  # enter protected mode
  movl %CR0, %eax
  orl $0x1, %eax
  movl %eax, %CR0
  ljmp $0x10, $clear_pipe

.code32
clear_pipe:
  movw $0x8, %ax
  movw %ax, %DS
  movw %ax, %ES
  movw %ax, %FS
  movw %ax, %GS
  movw %ax, %SS

  movl $0x10000, %esp
  ljmp $0x10, $KERNEL_ADDRESS

.org 1024
