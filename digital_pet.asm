.data 

welcome_text: .asciiz "=== digital pet simulator (MIPS32) ===\ninitialising system ...\n\nPlease set parameters (press enter for default values):\n"
newline: .asciiz "\n"
EDR_prompt: .asciiz "Enter natural energy depletion rate (EDR) [Default: 1]: "
MEL_prompt: .asciiz "Enter maximum energy level (MEL) [Default: 15]: "
IEL_prompt: .asciiz "Enter intial energy level (IEL) [Default: 5]: "
start_game_text1: .asciiz "\nParameters set successfully!\n- EDR: "
start_game_text2: .asciiz " units/sec\n-MEL: "
start_game_text3: .asciiz " units\n-IEL: "
start_game_text4: .asciiz " units\n\nYour digital pet is alive! Current status:\n"

buffer: .space 256 #buffer to hold string input (256 chars)
newline_char: .byte 10
EDR: .word 1
MEL: .word 15
IEL: .word 5
delay: .word 50
depletion_time: 2000

.text
.globl main

main:
#print weclome text
  li $v0, 4
  la $a0, welcome_text
  syscall

# INITIATE SETTING PARAMETERS  
  li $v0, 4
  la $a0, EDR_prompt
  syscall

#read input as string
  li $v0, 8
  la $a0, buffer
  li $a1, 256
  syscall
  # check for enter (\n)
  lb $t0, buffer #load first byte of buffer into $t0
  lbu $t1, newline_char #loads 10 into $t1
  beq $t0, $t1, set_MEL #if 1st char = \n --> default EDR 
  jal convert_to_int #else, convert input to int
  sw $t3, EDR

set_MEL:
# set MEL 
  li $v0, 4
  la $a0, MEL_prompt
  syscall

  li $v0, 8
  la $a0, buffer
  li $a1, 256
  syscall
  lb $t0, buffer
  lbu $t1, newline_char
  beq $t0, $t1, set_IEL 
  jal convert_to_int
  sw $t3, MEL 

set_IEL:
  li $v0, 4
  la $a0, IEL_prompt
  syscall

  li $v0, 8
  la $a0, buffer
  li $a1, 256
  syscall
  lb $t0, buffer
  lbu $t1, newline_char
  beq $t0, $t1, print_parameters 
  jal convert_to_int
  sw $t3, IEL 
  j print_parameters


# THIS CONVERTS A STRING TO AN INT
convert_to_int: 
  la $t2, buffer #$t2 is a pointer to current char 
  li $t3, 0
conversion_loop:
  lb $t0, 0($t2)
  li $t1, 10 #(\n)
  beq $t0, $t1, conversion_done
# check if char is digit ('0' - '9')
  li $t1, '0'
  blt $t0, $t1, conversion_done
  li $t1, '9'
  bgt $t0, $t1, conversion_done

# convert char to digit value
  li $t1, '0'
  sub $t4, $t0, $t1 # $t4 = '5' - '0' = 5
    # newTotal = (oldTotal X 10) + currentDigitValue
  li $t5, 10
  mul $t3, $t3, $t5 # result = result * 10
  add $t3, $t3, $t4 # result = result + digit

# move to next char 
  addi $t2, $t2, 1
  j conversion_loop

conversion_done:
  jr $ra


print_parameters:
  li $v0, 4
  la $a0, start_game_text1
  syscall
  li $v0, 1
  lw $a0, EDR 
  syscall
  li $v0, 4
  la $a0, start_game_text2
  syscall
  li $v0, 1
  lw $a0, MEL
  syscall
  li $v0, 4
  la $a0, start_game_text3
  syscall
  li $v0, 1
  lw $a0, IEL
  syscall
  li $v0, 4
  la $a0, start_game_text4
  syscall


game_loop:
  j exit 


exit:
  li $v0, 10
  syscall


