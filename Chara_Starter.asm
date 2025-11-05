.data
## Text lines
welcome_text: .asciiz "=== Digital Pet Simulator (MIPS32) ===\nInitialiazing system...\n\nPlease set parameters (press Enter for default):"
enter_EDR: .asciiz "\nEnter Natural Energy Depletion Rate (EDR) [Default: 1]:"
enter_MEL: .asciiz "\nEnter Maximum Energy Level (MEL) [Default: 15]:"
enter_IEL: .asciiz "\nEnter Initial Energy Level (IEL) [Default: 5]:"
success: .asciiz "\nParameters set successfully!"
EDR_label: .asciiz "\n-EDR:"
MEL_label: .asciiz "\n-MEL:"
IEL_label: .asciiz "\n-IEL:"
closing: .asciiz "\nYour Digital Pet is alive! Current status:"
energy_label: .asciiz "\nEnergy:"
out_of: .asciiz "/20"
enter_command: .asciiz "\nEnter a command (F, E, P, I, R, Q) >" 
newline: .asciiz "\n"

## Default variables
EDR: .word 1
MEL: .word 15
IEL: .word 8
current_energy: .word 0

edr_input: .space 10
mel_input: .space 10
iel_input: .space 10




.text
main:
## Print welcome text
li $v0, 4
la $a0, welcome_text
syscall

## EDR message
li $v0, 4
la $a0, enter_EDR
syscall

li $v0, 8
la $a0, edr_input
li $a1, 10
syscall


lb $t0, edr_input
beq $t0, 10, skip_edr ## if 'Enter' keep default and skip to next prompt
la $a0, edr_input
jal str_to_int
sw $v0, EDR

skip_edr:
## MEL message
li $v0, 4
la $a0, enter_MEL
syscall

li $v0, 8
la $a0, mel_input
li $a1, 10
syscall

lb $t0, mel_input
beq $t0, 10, skip_mel
la $a0, mel_input
jal str_to_int
sw $v0, MEL

skip_mel:
## IEL message
li $v0, 4
la $a0, enter_IEL
syscall

li $v0, 8
la $a0, iel_input
li $a1, 10
syscall

lb $t0, iel_input
beq $t0, 10, skip_iel
la $a0, iel_input
jal str_to_int
sw $v0, IEL

skip_iel:
## Current energy
lw $t1, IEL
sw $t1, current_energy

## Print success message
li $v0, 4
la $a0, success
syscall

## Print stored values 
# EDR
li $v0, 4
la $a0, EDR_label
syscall
li $v0, 1
lw $a0, EDR
syscall

# MEL
li $v0, 4
la $a0, MEL_label
syscall
li $v0, 1
lw $a0, MEL
syscall

# IEL
li $v0, 4
la $a0, IEL_label
syscall
li $v0, 1
lw $a0, IEL
syscall

# Closing
li $v0, 4
la $a0, closing
syscall

li $v0, 4
la $a0, energy_label
syscall
li $v0, 1
lw $a0, current_energy
syscall
li $v0, 4
la $a0, out_of
syscall

li $v0, 10
syscall


############################
str_to_int:
li $v0, 0 ## result = 0
convert_loop:
lb $t0, 0($a0)
beqz $t0, done_conv
beq $t0, 10, done_conv
addi $t0, $t0, -48
mul $v0, $v0, 10
add $v0, $v0, $t0
addi $a0, $a0, 1 ## increment
j convert_loop
done_conv:
jr $ra
