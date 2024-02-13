wait_enter_press:
  pushw %bp
  movw %sp, %bp

  0:
    movb $0x0, %ah
    int $0x16
    cmpw $0x1C0D, %ax
  jne 0b

  popw %bp
  ret

# print message and code with new line at the end
# arguments: ascii error code in ax, error msg address
print_message:
  pushw %bp
  pushw %si
  movw %sp, %bp

  movw 6(%bp), %si # message

  # print message
  0:
    movb $0x0E, %ah
    movb (%si), %al
    int $0x10
    incw %si
    cmpb $0x0, (%si)
  jne 0b

  cmpw $0x0, 8(%bp)
  je 0f

# print 0
  movb $0x0E, %ah
  movb $0x30, %al
  int $0x10

# print x
  movb $0x0E, %ah
  movb $'x', %al
  int $0x10

# print code in hex
  movb $0x0E, %ah

  movb 9(%bp), %al
  int $0x10

  movb 8(%bp), %al
  int $0x10

  0:
  call print_new_line
  popw %si
  popw %bp
  ret

# prints new line
print_new_line:
# print carriage return
  movb $0x0E, %ah
  movb $0xD, %al
  int $0x10

# print new line
  movb $0x0E, %ah
  movb $0xA, %al
  int $0x10

  ret

# byte must be located in lower half
# return: higher 4 bits of in %ah lower in %al
byte_to_ascii_hex:
  pushw %bp
  movw %sp, %bp

  movb 4(%bp), %al
  shrb $0x4, %al # shift higher 4 bits to lower 4

  pushw %ax
  call half_bit_value_to_ascii

  movb %al, %ah

  movb 4(%bp), %al
  andb $0xF, %al # remove higher 4 bits

  pushw %ax
  call half_bit_value_to_ascii

  addw $0x4, %sp # move stack pointer 2 values back
  popw %bp
  ret

# argument is lower 4 bits of lower byte of register
# return is in %al
half_bit_value_to_ascii:
  pushw %bp
  movw %sp, %bp

  movb 4(%bp), %al
  cmpb $0x9, %al # check if value is digit or char
  jle number

  char:
  addb $0x37, %al # add 0x37 to make value to ascii char
  jmp 0f

  number:
  addb $'0', %al # add '0' to char to make it ascii digit
  jmp 0f

  0:
  popw %bp
  ret

