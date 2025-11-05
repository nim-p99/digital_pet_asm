.data
welcome_text:.asciiz
"===digital pet simulator (MIPS32) ===\ninitialising system...\nPlease set parameters (press Enter for default)\n"
first_prompt:.asciiz
"Please enter the natural energy depeltion rate EDR. If not set, default value is 1 unit of energy every 1 second\n"
second_prompt:.asciiz
"Please enter the maximum energy level MEL. If not set, default value is 15\n"
third_prompt:.asciiz
"Please enter the initial energy level IEL. If not set, default value is 5\n"
msg_success:.asciiz
"\nPet's initial parameters set successfully!\n"
msg_EDR:.asciiz
"- EDR: "
msg_MEL:.asciiz
"- MEL: "
msg_IEL:.asciiz
"- IEL: "
msg_units_sec:.asciiz
" units/sec\n"
msg_units:.asciiz
" units\n"
msg_alive:.asciiz
"\nYour digital pet is alive!\n"
msg_current_energy:.asciiz
"Current energy: "
dog_art:.asciiz
"     .-.\n     (___________________________()6 `-,\n     (   ______________________   /''\"`\n     //\\\\                      //\\\\\n      \"\" \"\"                     \"\" \"\"\n"

input_buffer:.space
16  # store text (if presses enter)
EDR:.word
0
MEL:.word
0
IEL:.word
0
default_EDR_val:.word
1
default_MEL_val:.word
15
default_IEL_val:.word
5

.text
.globl
main

main:  # print doggy
la $a0, dog_art
li $v0, 4
syscall

# print welcome text
addi $v0, $0, 4  # Set system call code (print welcome text) #4 sets the string
la   $a0, welcome_text  # Load address of string into $a0.
syscall  # Print string.

# EDR Prompt
addi $v0, $0, 4  # Set system call code (print welcome text) #4 sets the string
la   $a0, first_prompt
syscall

# Read EDR input AS STRING not integer anymore
li $v0, 8
la $a0, input_buffer
li $a1, 16
syscall

# Check is user pressed ENTER
lb $t1, input_buffer
beq $t1, 10, default_EDR  # JUMPS TO default_EDR  # ASCII 10 is the newline character / if \n uses 1 (default)

# If not enter then reads integer
li $v0, 5
syscall
j
store_EDR

default_EDR:
li $v0, 1

store_EDR:
sw $v0, EDR

# MEL Prompt
addi $v0, $0, 4  # Set system call code (print welcome text) #4 sets the string
la   $a0, second_prompt
syscall

# Read MEL input AS STRING not integer anymore
li $v0, 8
la $a0, input_buffer
li $a1, 16
syscall

# Check is user pressed ENTER
lb $t1, input_buffer
beq $t1, 10, default_MEL

# If not enter then stores the number inputted
li $v0, 5
syscall
j
store_MEL

default_MEL:
li $v0, 15

store_MEL:
sw $v0, MEL

# IEL Prompt
addi $v0, $0, 4  # Set system call code (print welcome text) #4 sets the string
la   $a0, third_prompt
syscall

# Read MEL input AS STRING not integer anymore
li $v0, 8
la $a0, input_buffer
li $a1, 16
syscall

# Check is user pressed ENTER
lb $t1, input_buffer
beq $t1, 10, default_IEL

# If not enter then stores the number inputted
li $v0, 5
syscall
j
store_IEL

default_IEL:
li $v0, 5

store_IEL:
sw $v0, IEL

# displayed confirmation
li $v0, 4
la $a0, msg_success
syscall

# --- Print EDR ---
li $v0, 4
la $a0, msg_EDR
syscall
lw $a0, EDR
li $v0, 1
syscall
li $v0, 4
la $a0, msg_units_sec
syscall

# --- Print MEL ---
li $v0, 4
la $a0, msg_MEL
syscall
lw $a0, MEL
li $v0, 1
syscall
li $v0, 4
la $a0, msg_units
syscall

# --- Print IEL ---
li $v0, 4
la $a0, msg_IEL
syscall
lw $a0, IEL
li $v0, 1
syscall
li $v0, 4
la $a0, msg_units
syscall

# --- Final message ---
li $v0, 4
la $a0, msg_alive
syscall

# Prints current energy
li $v0, 4
la $a0, msg_current_energy
syscall
lw $a0, IEL
li $v0, 1
syscall
li $v0, 4
la $a0, msg_units
syscall

li   $v0, 10
syscall

	
	  