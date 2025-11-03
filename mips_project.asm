
.data

EDR_input: .asciiz "enter natural energy depletion rate (EDR) [Default: 1]: "
EDR: .word 1

MEL_input: .asciiz "enter maximum energy level (MEL) [Default: 15]: "
MEL: .word 15

IEL_input: .asciiz "enter initial energy level (IEL) [Defualt: 5]: "
IEL: .word 5

welcome_text: .asciiz "=== digital pet simulator (MIPS32) ===\ninitialising system...\n\nPlease set parameters (enter 0 for default values):\n"

initial_text_A:.asciiz "parameters set successfully!\n - EDR "
initial_text_B: .asciiz " units/sec\n - MEL: "
initial_text_C: .asciiz " units\n - IEL: "
initial_text_D: .asciiz " units\n\n your digital pet is alive! current status:"

new_line: "\n"

previous_time: .word 0 
current_time: .word 0

.text
main:
#--- printing welcome message ---#
	li $v0, 4 #print string syscall: EDR_input
	la $a0, welcome_text #loading address for syscall 
	syscall
	
#--- asking for default values, EDR -----#
	li $v0, 4 #print string syscall: EDR_input
	la $a0, EDR_input #loading address of EDR_input for syscall
	syscall
	
	li $v0, 5 #read integer syscall: prompting user to enter an integar  
	syscall 
	beqz $v0, using_default_EDR #preventing error if enter pressed ==> uses deffault values
	
	add $t0, $v0, $zero # moving user input from $v0 into temp storage
	sw $t0, EDR #storing the the user input into the EDR variable 
	
using_default_EDR:

#--- asking for default values, MEL -----#
	li $v0, 4 #print string syscall: MEL_input
	la $a0, MEL_input #loading address of MEL_input for syscall
	syscall #completes print
	  
	li $v0, 5 #read integer syscall: prompting user to enter an integar  
	syscall 
	beqz $v0, using_default_MEL
		
	add $t0, $v0, $zero # moving user input from $v0 into temp storage
	sw $t0, MEL
using_default_MEL:

#--- asking for default values, IEL -----#
	li $v0, 4 #print string syscall: IEL_input
	la $a0, IEL_input #loading address of IEL_input for syscall
	syscall #completes print
	  
	li $v0, 5 #read integer syscall: prompting user to enter an integar  
	syscall 
	beqz $v0, using_default_IEL
		
	add $t0, $v0, $zero # moving user input from $v0 into temp storage
	la $t1, IEL
	sw $t0, ($t1)
using_default_IEL:

#--- checking stored values (remove me) ---#
	li $v0, 1 # print integar syscall called
	la $t0, EDR #loading address of EDR
	lw $a0, ($t0)
	syscall
	
#--- inital text print ---#
	#inital_text A
	li $v0, 4 #print string syscall
	la $a0, initial_text_A #loading address 
	syscall #completes print
	
	#EDR Value
	li $v0, 1 # print integar syscall called
	la $t0, EDR #loading address of EDR
	lw $a0, ($t0)
	syscall
	
	#initial_text_B
	li $v0, 4 #print string syscall
	la $a0, initial_text_B #loading address 
	syscall #completes print
	
	#MEL Value
	li $v0, 1 # print integar syscall called
	la $t0, MEL #loading address of EDR
	lw $a0, ($t0)
	syscall
	
	#initial_text_C
	li $v0, 4 #print string syscall
	la $a0, initial_text_C #loading address 
	syscall #completes print
	
	#IEL Value
	li $v0, 1 # print integar syscall called
	la $t0, IEL #loading address of EDR
	lw $a0, ($t0)
	syscall
	
	#initial_text_D
	li $v0, 4 #print string syscall
	la $a0, initial_text_D #loading address 
	syscall #completes print
	
# --- Finding current time -- #
	
	#time syscall
	li $v0, 30 #retrieves number of seconds since Jan 1 1970 and stores it as a 64 bit using two registers a1:a0
	syscall
	
	
	#store the lsb to $t1
	move $t1, $a0 #only using the lower half of the time, means this works for up to 32,767 seconds
	sw $t1, previous_time

loop:
	#IEL reduced
	lw $t0, IEL
	ble $t0,0, exit_loop #branching if energy is less than or equal to zero to stop loop
	
	#finding total amount to reduce by (seconds)
	li $v0, 30 #current time in milliseconds 
	syscall
	
	#store the lsb to $t1
	move $t2, $a0
	lw $t1, previous_time #  getting previous number of milliseconds
	sub $t2, $t2, $t1 # elpased time stored in $t1
	div $t2, $t2, 1000 #dividing by 1000 to get seconds 
	sub $t0, $t0, $t2 #setting IEL to current - number of seconds that has elpased 
	sw $t0, IEL #storing IEL
	
	#updating previous time to current time in preparation for next loop iteration
	li $v0, 30 #current time in milliseconds 
	syscall
	sw $a0, previous_time 
	
	#print new line
	li $v0, 4
	la $a0, new_line
	syscall
	 
	#printing new IEL 
	li $v0, 1 
	move $a0, $t0
	syscall
	
	#timer loop ==> testing loop to see if changing time will affect how much the energy level is reduced by
	li $v0, 32 #sleep syscall
	li $a0, 2000 #loading sleep time amount in milliseconds to ao for syscall
	syscall 
	
	j loop
	
exit_loop:
			
	#exit
	li $v0, 10
	syscall	


	
	  