# 16-bit real mode assembly
# avaliable code space is 510 bytes
.code16

.set SECOND_STAGE_START, 0x7E00

.section .text
  .global _start

_start:
  clc           # clear CF (carry flag)
  xorw %ax, %ax # set ax to zero 

###################################
#  ESTABLISHING BOOT LOADER STACK #
###################################
# start adderrors of stack is 0x0007FFFF
# 0x7FFFF = (x * 0x10) + 0xFFFF
# 0x7FFFF - 0xFFFF = x * 0x10
# 0x70000 = x * 0x10
# x = 0x70000 / 0x10
# x = 0x7000

  movw $0x7000, %ax
  movw %ax, %SS
  movw $0xFFFF, %sp

###################################

  movb $0x42, %ah # read sector
  movb $0x80, %dl # number of sectors
  movw $disk_address_packet, %si
  int $0x13
  
  cmp $0x0, %ah 
  jne error_occured # jump if ah != 0 which indicates an error

  jmp SECOND_STAGE_START

  error_occured:
    movb %ah, %al
    pushw %ax
    call byte_to_ascii_hex
    addw $0x2, %sp

    pushw %ax
    pushw $error

    call print_message
    jmp .

error:
  .ascii "Something went wrong, int 13, error code: \0"

disk_address_packet:
  .byte 0x10 # 16 byte
  .byte 0
  .word 2 # n of secotrs
  .long SECOND_STAGE_START # buffer
  .quad 1
  
.include "src/misc_functions.asm"

  .org 510 - _start # pad rest wiht zeros
  .word 0xaa55      # magic number
