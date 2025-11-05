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
healthbar_text: .asciiz " Energy: "
command_prompt: .asciiz "Enter a command (F, E, P, I, R, Q) eg F2 >"
feed_message1: .asciiz "Command recognised: Feed "
feed_message2: .asciiz "Energy increased by "
feed_message3: .asciiz " units\n"
deplete_string1: .asciiz "time +"
deplete_string2: .asciiz "s ... natural energy depletion!\n"
death_message1: .asciiz "Error, energy level equal or less than 0. DP is dead!"
death_message2: .asciiz "*** your digital pet has died! ***\nWhat's your next move? (R,Q) >"



buffer: .space 256 #buffer to hold string input (256 chars)
newline_char: .byte 10
EDR: .word 1
MEL: .word 15
IEL: .word 5
current_energy: .word 0
initial_time: .word 0
elapsed_time: .word 0
time_interval: .word 1000


.text
.globl main

main:
#print welcome text
  li $v0, 4
  la $a0, welcome_text
  syscall

#----------------------------------------------

# Initiate setting the parameters
# set EDR
  li $v0, 4
  la $a0, EDR_prompt
  syscall
  jal set_param 
  beq $t0, $t1, set_MEL     #if 1st char = \n(enter) --> use default
  jal convert_to_int        #else, convert input to int
  sw $t3, EDR 

set_MEL:
# set MEL 
  li $v0, 4
  la $a0, MEL_prompt
  syscall 
  jal set_param 
  beq $t0, $t1, set_IEL 
  jal convert_to_int
  sw $t3, MEL 

set_IEL:
  li $v0, 4
  la $a0, IEL_prompt
  syscall
  jal set_param 
  beq $t0, $t1, print_parameters 
  jal convert_to_int
  sw $t3, IEL
  j print_parameters

#----------------------------------------------

set_param:
#read input as string
  li $v0, 8
  la $a0, buffer
  li $a1, 256
  syscall
  # check for enter (\n)
  lb $t0, buffer #load first byte of buffer into $t0
  lbu $t1, newline_char #loads 10 into $t1
  jr $ra

#----------------------------------------------

# Converts a string to an INT
convert_to_int: 
  addi $sp, $sp, -4
  sw $ra, 0($sp)

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
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra

#---------------------------------------------

print_parameters:
  # set current level to IEL.
  lw $t0, IEL
  sw $t0, current_energy
  
  # Print all parameters 
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
  j game_loop_start

#---------------------------------------------
health_bar:
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  lw $t0, current_energy
  lw $t1, MEL
  li $t2, 0
  li $t4, 0

  sub $t3, $t1, $t0

  li $v0, 11
  li $a0 91 #'['
  syscall
block_loop:
  beq $t0, $t2, dash_loop
  li $v0, 11
  li $a0, 9608 # '█'
  syscall
  addi $t2, $t2, 1
  j block_loop
dash_loop:
  beq $t4, $t3, end_health_bar
  li $v0, 11
  li $a0, 45 # '-'
  syscall
  addi $t4, $t4 1
  j dash_loop 
end_health_bar:
  li $v0, 11
  li $a0, 93 # ']'
  syscall
  li $v0, 4
  la $a0, healthbar_text
  syscall
  li $v0, 1
  lw $a0, current_energy
  syscall
  li $v0, 11
  li $a0, 47 # '/'
  syscall
  li $v0, 1
  lw $a0, MEL
  syscall
  li $v0, 4
  la $a0, newline
  syscall 

  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra 



#-------------------------------------------
deplete:
  lw $t0, elapsed_time
	lw $t1, time_interval
	div $t0, $t1
	mflo $t2
	
	li $v0, 4
	la $a0, deplete_string1
	syscall
	
	li $v0, 1
	add $a0, $t2, $0
	syscall

  li $v0, 4
  la $a0, deplete_string2
  syscall 
	
	li $v0, 4
	la $a0, newline
	syscall

  lw $t3, current_energy
  # if result is negative
  bgt $t2, $t3, set_zero
  sub $t3, $t3, $t2 
  sw $t3, current_energy

	j game_loop_start

set_zero:
  lw $t3, current_energy
  add $t3, $0, $0
  sw $t3, current_energy
  j game_loop_start

#---------------------------------------
check_energy_level: 
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  lw $t1, current_energy
  lw $t2, MEL
  bgt $t1, $t2, max_energy
  ble $t1, $0, dead
  jr $ra
max_energy:
  add $t1, $t2, $0
  sw $t1, current_energy
  jr $ra 

#---------------------------------------
dead:
  # set current_energy to 0
  lw $t1, current_energy
  add $t1, $0, $0
  sw $t1, current_energy

  li $v0, 4
  la $a0, death_message1
  syscall
  
  jal health_bar

  li $v0, 4
  la $a0, death_message2
  j exit

#---------------------------------------------
game_loop_start:
  jal check_energy_level
  jal health_bar

game_loop:
  # start time 
  li $v0, 30
  syscall
  sw $a0, initial_time
  # prompt user 
  li $v0, 5
  syscall
  # end time
  li $v0, 30
  syscall
  lw $t0, initial_time
  # calculate elapsed time
  sub $t1, $a0, $t0
  sw $t1, elapsed_time
  lw $t2, time_interval
  # if > interval --> deplete
  bgt $t1, $t2, deplete
  j game_loop_start



#---------------------------------------------
exit:
  li $v0, 10
  syscall


