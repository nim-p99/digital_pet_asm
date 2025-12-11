# ==============================================================
# DIGITAL PET SIMULATOR (MIPS32) — INITIAL SETUP PHASE
# ==============================================================
.data
# --- Programme Messages ---
welcomeMessage:      .asciiz "=== Digital Pet Simulator (MIPS32) ===\n"
initMessage:         .asciiz "Initialising system...\n\n"
setParamMsg:         .asciiz "Please set parameters (press Enter for default): \n"
successMsg:          .asciiz "\nParameters set successfully!\n"
initStatusAlive:     .asciiz "\nYour Digital Pet is alive! Current status:\n"
initStatusDead:      .asciiz "Error, energy level less than or equal 0. Your pet is dead :(  "
goodbyeMsg:          .asciiz "Saving session... goodbye! Thanks for playing."
energyDepleteMsg:    .asciiz "Time +1s... Natural energy depletion!\n"
maxEnergyErrMsg:     .asciiz "Error, maximum energy level reached! Capped to the Max."
feedMsg:             .asciiz "\nCommand recognised: Feed "
entertainMsg:        .asciiz "\nCommand recognised: Entertain "
petMsg:              .asciiz "\nCommand recognised: Pet "
ignoreMsg:           .asciiz "\nCommand recognised: Ignore "
quitMsg:             .asciiz "\nCommand recognised: Quit.\n"
depleteString1:      .asciiz "time +"
depleteString2:      .asciiz "s ... natural energy depletion!\n"
death_message1:      .asciiz "Error, energy level equal or less than 0. Your pet is dead :(  \n"
death_message2:      .asciiz "*** your digital pet has died! ***\nWhat's your next move? (R,Q) >"
energy_inc_msg:	     .asciiz "Energy increased by "
energy_dec_msg:	     .asciiz "Energy decreased by "
units_paren_msg:      .asciiz " units ("
units_only_msg:      .asciiz " units.\n"
multiplied:          .asciiz "x"
close_paren: 	     .asciiz ").\n"

# --- Prompts ---
edrPrompt: .asciiz "Enter Natural Energy Depletion Rate (EDR) [Default: 1]: "
melPrompt: .asciiz "Enter Maximum Energy Level (MEL) [Default: 15]: "
ielPrompt: .asciiz "Enter Initial Energy Level (IEL) [Default: 5]: "
gameCommandPrompt: .asciiz "\nEnter a command (F, E, P, I, R, Q) > "
energyActionPrompt: .asciiz "Press 'R' to reset your pet to its initial energy level, or 'Q' to quit the game.:"


# --- Errors / Misc ---
invalidInitLevelMsg:     .asciiz "\nInvalid input - programme only accepts positive integers. Please try again:\n"
invalidEnergyRelationMsg:.asciiz "Invalid relation - initial energy cannot exceed maximum. Please try again.\n"
invalidCommandMsg:       .asciiz "Invalid command - plase try again.\n"
unrecognisedCmdMsg:      .asciiz "Unknown command - please try again.\n"
todoMsg: .asciiz "Command recognised - feature not yet implemented.\n"




# --- Energy Values ---
EDR: .word 1
MEL: .word 15
IEL: .word 5
currentEnergy: .word 0

buffer: .space 20

# -- Display labels for Initial Parameters --
edrLabel:   .asciiz "- EDR: "
edrUnits:   .asciiz " units/sec\n"
melLabel:   .asciiz "- MEL: "
melUnits:   .asciiz " units\n"
ielLabel:   .asciiz "- IEL: "
ielUnits:   .asciiz " units\n"


# HAVENT GROUPED THE BELOW CONSTANTS INTO NICE FORMATTED SCETIONS YET
energyLabel:     .asciiz " Energy: "
slashSymbol:     .asciiz "/"
barLeftBracket:  .asciiz "["
barRightBracket: .asciiz "]"
filledUnit:      .asciiz "#"
emptyUnit:       .asciiz "-"
BAR_WIDTH: .word 20

spaceStr:  .asciiz " "

newline:   .asciiz "\n"

fullstop:  .asciiz ".\n"


feedCount: .word 0
petCount: .word 0
ignoreCount: .word 0
entertainCount: .word 0
resetCount: .word 0
# THINK ABOVE LOGIC COULD BE IF USER INPUT = "{SPECIFIC LETTER}" THEN DO A BRANCH TO BASICALLY ADD ONE TO WHICHEVER COMMAND INPUT CORRESPONDED TO 

# time related 
initial_time: .word 0 
end_time: .word 0
elapsed_time: .word 0 
time_interval: .word 1000


.text
.globl main

# ==============================================================
# MAIN ROUTINE
# ==============================================================
main:
    jal initSystem
    jal initParam
    
gameLoop:
    jal checkEnergyLevel
    jal healthBar
    jal displayEnergyStatus
    jal getSysTime
    sw $v0, initial_time 
    la   $a0, gameCommandPrompt
    jal  printString
    la   $a0, buffer   # buffer address
    li   $a1, 20     # max length
    jal  readUserInput
    jal  stripWhiteSpace
    jal processUserCommand
    jal getSysTime
    sw $v0, end_time
    jal checkTime
    j gameLoop 

 # Exit programme cleanly
    li $v0, 10
    syscall

# ==============================================================
# STUFF TO IMPLEMENT
# ==============================================================
checkEnergyLevel: 
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  
  lw $t1, currentEnergy
  lw $t2, MEL
  # If currentEnergy > MEL --> cap at MEL
  bgt $t1, $t2, maxEnergy 
  # if currentEnergy <= 0 --> pet is dead
  ble $t1, $0, petDead
  jr $ra
  
maxEnergy:
  add $t1, $t2, $0
  sw $t1, currentEnergy
  jr $ra 

checkTime:
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  
  lw $t0, initial_time
  lw $t1, end_time
  lw $t2, time_interval
  sub $t3, $t1, $t0
  sw $t3, elapsed_time
  # if elapsed time > time interval --> deplete 
  bgt $t3, $t2, handleDeplete
  b checkTimeDone

handleDeplete:
  jal deplete

checkTimeDone:
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra


deplete:
  addi $sp, $sp, -16
  sw $ra, 12($sp)
  sw $s0, 8($sp)
  sw $s1, 4($sp)
  sw $s2, 0($sp)

  # calculates how many seconds elapsed 
  lw $t0, elapsed_time
  lw $t1, time_interval
  div $t0, $t1 
  mflo $s1  # value needs to be preserved 
  
  li $s0, 0 # loop counter - value needs to be preserved

depleteLoop:
  beq $s0, $s1, depleteDone
  
  # print Time +1s... etc
  la $a0, energyDepleteMsg
  jal printString

  # deplete currentEnergy 
  lw $t3, currentEnergy
  lw $s2, EDR
  sub $t3, $t3, $s2 # subtract according to EDR entered by user
  # If result will be negative --> set to zero 
  bltz $t3, setZero
  sw $t3, currentEnergy
  j afterDecr

setZero:
  li $t3, 0
  sw $t3, currentEnergy

afterDecr:
  #if energy hits zero stop
  lw $t3, currentEnergy
  beqz $t3, depleteDone
  #otherwise print bar and continue
  jal healthBar
  jal displayEnergyStatus
  addi $s0, $s0, 1
  j depleteLoop
  
depleteDone:
  jal getSysTime
  sw $v0, initial_time
  lw $s2, 0($sp)
  lw $s1, 4($sp)
  lw $s0, 8($sp)
  lw $ra, 12($sp)
  addi $sp, $sp, 16
  jr $ra


processUserCommand:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    #Step one – identify whether the command is a single character or multiple characters.
    #Step two – if single, branch to a future routine that handles single-character commands.
    #Step three – if multiple, branch to a future routine that validates and parses the command.
    #Step four – if valid, branch to a future routine that dispatches the command to the correct action.
    #Step five – return control to the game loop.
    

    jal getCommandLength
    # command length = 0
    beq $v0, $0, emptyCommandError
    li $t0, 1
    # command length = 1
    beq $t0, $v0, handleSingleCharCommand
    # command length > 1
    bgt $v0, $t0, handleMultiCharCommand

handleSingleCharCommand:
    # load 1st char into $t1
    lb $t1, 0($a0)
    # load 'R' into $t2 
    li $t2, 82
    # if 'R' --> call reset 
    beq $t1, $t2, reset 
    # load 'Q' into $t2 
    li $t2, 81
    # if 'Q' --> call quit
    beq $t1, $t2, quit 
    # neither --> error message + return 
    la $a0, unrecognisedCmdMsg
    jal printString
    b processUserCommandDone


handleMultiCharCommand:
    # load 1st char into $t0
    lb $t0, 0($a0)
    # check 1st is valid 
    li $t1, 70 #'F'
    li $t2, 69 #'E'
    li $t3, 73 #'I'
    li $t4, 80 #'P'
    # direct to appropriate function 
    beq $t0, $t1, handleF 
    beq $t0, $t2, handleE 
    beq $t0, $t3, handleI 
    beq $t0, $t4, handleP
    # if 1st char invalid 
    la $a0, unrecognisedCmdMsg
    jal printString
    b processUserCommandDone

emptyCommandError:
  #TODO: to implement


processUserCommandDone:
# --- Restore stack and return ---
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# --------------------------------------------------------------
# Purpose - Counts the number of characters in a string
# Input   - $a0 = address of null-terminated string
# Output  - $v0 = number of non-null characters
# --------------------------------------------------------------
# Register usage
#   $t0 = pointer to current character
#   $t1 = current character byte
#   $t2 = counter
# --------------------------------------------------------------
getCommandLength:
    # --- Stack frame setup ---
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # --- Initialise registers ---
    move $t0, $a0          # $t0 = pointer to string
    li   $t2, 0            # $t2 = counter initialised to 0

countLoop:
    lb   $t1, 0($t0)       # load current byte
    beqz $t1, lengthDone   # stop when null terminator (0x00)
    addi $t2, $t2, 1       # increment counter
    addi $t0, $t0, 1       # move pointer to next byte
    j    countLoop

lengthDone:
    move $v0, $t2          # move final count into return register

    # --- Restore stack and return ---
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# -----------------------------------------------------------

reset:
  # increment resetCount 
  lw $t3, resetCount
  addi $t3, $t3, 1
  sw $t3, resetCount
  
  # reset 
  j main


quit: 
  # TODO:- print stats (feedCount etc.)

  # print quit message
  la $a0, quitMsg
  jal printString
  la $a0, goodbyeMsg
  jal printString
  li $v0, 10
  syscall

# ------------------------------------------------------------------
handleF:
  # check substring after 'F'
  addi $a1, $a0, 1
  move $a0, $a1
  jal checkInputNumeric
  beq $v0, $0, numericError
  # convert numeric substring to int
  move $a0, $a1
  jal convertStrToInt
  move $t5, $v0
  # pass int to feed function 
  move $a0, $t5
  jal feed
  b processUserCommandDone


handleE:
  # check substring after 'E'
  addi $a1, $a0, 1
  move $a0, $a1
  jal checkInputNumeric
  beq $v0, $0, numericError
  # convert numeric substring to int
  move $a0, $a1
  jal convertStrToInt
  move $t5, $v0
  # pass int to entertain function 
  move $a0, $t5
  jal entertain
  b processUserCommandDone


handleP:
  # check substring after 'P'
  addi $a1, $a0, 1
  move $a0, $a1
  jal checkInputNumeric
  beq $v0, $0, numericError
  # convert numeric substring to int
  move $a0, $a1
  jal convertStrToInt
  move $t5, $v0
  # pass int to pet function 
  move $a0, $t5
  jal pet
  b processUserCommandDone

handleI:
  # check substring after 'I'
  addi $a1, $a0, 1
  move $a0, $a1
  jal checkInputNumeric
  beq $v0, $0, numericError
  # convert numeric substring to int
  move $a0, $a1
  jal convertStrToInt
  move $t5, $v0
  # pass int to ignore function 
  move $a0, $t5
  jal ignore
  b processUserCommandDone

numericError:
    la $a0, unrecognisedCmdMsg
    jal printString
    b processUserCommandDone

#------------------------------------------------------------------------
#                      MAIN FUNCTIONS - Feed, Entertain, Pet, Ignore
# Integer (n) is kept in $a0 (and $t5) 
#------------------------------------------------------------------------
feed:
  # set up stack 
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  # print feed message - command recognised
  la $a0, feedMsg
  li $v0, 4
  syscall

  move $a0, $t5
  li $v0, 1
  syscall

  la $a0, fullstop
  li $v0, 4
  syscall 
  
  # Energy increased by n units
  la $a0, energy_inc_msg
  jal printString
  
  move $a0, $t5
  jal printInt
  
  la $a0, units_only_msg
  jal printString

  #Updating Current energy
  move $a0, $t5   # a0 = count (n feed actions)
  li   $a1, 1     # a1 = per-pet value (e.g., +1 energy per feed)
  jal  increase_energy
  
  # Print updated bar for energy
  jal healthBar
  jal displayEnergyStatus
  la $a0, newline
  jal printString
  
  # reallocate stack and return
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra

entertain:
  #stack setup 
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  # print entertain message - command recognised
  la $a0, entertainMsg
  li $v0, 4
  syscall

  move $a0, $t5
  li $v0, 1
  syscall

  la $a0, fullstop
  li $v0, 4
  syscall
  
  # Energy increased by 2*n units
  li $t6, 2
  mul $t7, $t5, $t6
  
  la $a0, energy_inc_msg
  jal printString
  move $a0, $t7
  jal printInt
  
  la $a0, units_paren_msg
  jal printString
  
  li $a0, 2
  jal printInt
  la $a0, multiplied
  jal printString
  
  move $a0, $t5
  jal printInt
  la $a0, close_paren
  jal printString
  
  #Updating Current energy
  move $a0, $t5   # a0 = count (n feed actions)
  li   $a1, 2     # a1 = per-enterain value (e.g., +1 energy per feed)
  jal  increase_energy
  
  # Print updated bar for energy
  jal healthBar
  jal displayEnergyStatus

  # reallocate stack and return
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra  

pet:
  # stack setup
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  # print pet message - Command recognised
  la $a0, petMsg
  li $v0, 4
  syscall

  move $a0, $t5
  li $v0, 1
  syscall

  la $a0, fullstop
  li $v0, 4
  syscall
  
  # Energy increased by 2*n
  li $t6, 2
  mul $t7, $t5, $t6
  
  la $a0, energy_inc_msg
  jal printString
  move $a0, $t7
  jal printInt
   
  la $a0, units_paren_msg
  jal printString
  
  li $a0, 2
  jal printInt
  la $a0, multiplied
  jal printString
  
  move $a0, $t5
  jal printInt
  la $a0, close_paren
  jal printString

  #Increase energy
  move $a0, $t5   # a0 = count (n feed actions)
  li   $a1, 2     # a1 = +2 energy per pet
  jal  increase_energy
  
  # Print updated bar for energy
  jal healthBar
  jal displayEnergyStatus
  
  # reallocate stack and return
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra

ignore:
  # stack setup
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  # print ignore message - command recognised
  la $a0, ignoreMsg
  li $v0, 4
  syscall

  move $a0, $t5
  li $v0, 1
  syscall

  la $a0, fullstop
  li $v0, 4
  syscall
  
  # Energy decreased by 3*n
  li $t6, 3
  mul $t7, $t5, $t6
  
  la $a0, energy_dec_msg
  jal printString
  move $a0, $t7
  jal printInt
  
  la $a0, units_paren_msg
  jal printString
  
  li $a0, 3
  jal printInt
  la $a0, multiplied
  jal printString
  
  move $a0, $t5
  jal printInt
  la $a0, close_paren
  jal printString 

  #Decrease Energy
  move $a0, $t5   # a0 = count (n feed actions)
  li   $a1, -3     # a1 = -3 energy per ignore
  jal  increase_energy
  
  # Print updated bar for energy
  jal healthBar
  jal displayEnergyStatus
  
  # reallocate stack and return
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra


#----------------------------------------------------------------
# increase_energy
# Inputs:
#   $a0 = count  (number of repetitions)
#   $a1 = inc    (value to add to currentEnergy each repetition)
# Behavior: adds (inc * count) to currentEnergy by looping count times.
#----------------------------------------------------------------
increase_energy:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    move $t5, $a0    # t5 = loop counter from action
    move $t1, $a1    # t1 = increment per iteration

ie_loop:
    lw   $t0, currentEnergy
    add  $t0, $t0, $t1
    sw   $t0, currentEnergy
    addi $t5, $t5, -1
    bgtz $t5, ie_loop
    
    lw $t0, currentEnergy
    #if <=0 -> set to 0
    blez $t0, ie_set_zero
    
    #if > MEL -> set to MEL
    lw $t1, MEL
    ble $t0, $t1, ie_store_done
    move $t0, $t1

ie_store_done:
    sw $t0, currentEnergy
    j ie_done

ie_set_zero:
    li $t0, 0
    sw $t0, currentEnergy

ie_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ==============================================================
# END OF  TO IMPLEMENY
# ==============================================================

# initSystem — Displays start-up messages
initSystem:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $a0, welcomeMessage
    jal printString

    la $a0, initMessage
    jal printString

    la $a0, setParamMsg
    jal printString

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ==============================================================
# initParam — Initialises EDR, MEL, and IEL using getInitParamValue
# Includes loop to re-prompt on invalid input
# Includes validation ensuring IEL ≤ MEL
# ==============================================================
initParam:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # --- Get EDR ---
    la   $a0, edrPrompt
    la   $a1, EDR
    li   $a2, 1
    la   $a3, buffer        # pass the buffer address as an extra argument
    jal  getInitParamValue

checkMEL_and_IEL:
    # --- Get MEL ---
    la   $a0, melPrompt
    la   $a1, MEL
    li   $a2, 15
    la   $a3, buffer   
    jal  getInitParamValue

    # --- Get IEL ---
    la   $a0, ielPrompt
    la   $a1, IEL
    li   $a2, 5
    la   $a3, buffer 
    jal  getInitParamValue

    # --- Validate logical relationship IEL ≤ MEL ---
    lw   $t0, IEL        # load IEL value
    lw   $t1, MEL        # load MEL value

    ble  $t0, $t1, initParamsValid   # if IEL ≤ MEL → continue
    la   $a0, invalidEnergyRelationMsg
    jal  printString             # show error message
    j    checkMEL_and_IEL        # re-enter loop for MEL and IEL

initParamsValid:
    # --- All parameters valid ---
    # Set currentEnergy = IEL
    la   $t0, IEL             # load address of IEL
    lw   $t1, 0($t0)          # load IEL value
    la   $t2, currentEnergy   # load address of currentEnergy
    sw   $t1, 0($t2)          # store IEL value into currentEnergy
    
     # Display success message
    la   $a0, successMsg
    jal  printString
    jal displayConfig
    jal checkEnergyStatus
    la   $a0, initStatusAlive  # Load alive message
    jal  printString  

    # Restore and return
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# readUserInput — Reads a string into buffer
# $a0 = buffer address, $a1 = max length
readUserInput:
    li $v0, 8
    syscall
    jr $ra
    
# getInitParamValue
# $a0 = address of prompt string
# $a1 = address of variable to store result
# $a2 = default value (integer)
getInitParamValue:
    addi $sp, $sp, -20
    sw   $ra, 16($sp)        # save return
    sw   $a0, 12($sp)        # save prompt
    sw   $a1, 8($sp)         # save dest address
    sw   $a2, 4($sp)         # save default value
    sw   $a3, 0($sp)         # save buffer address

initPromptLoop:
    # show prompt
    lw   $a0, 12($sp)        # prompt
    jal  printString

    # read input into buffer
    lw   $a0, 0($sp)         # buffer address
    li   $a1, 20   # max length
    jal  readUserInput

    # blank check
    lw   $a0, 0($sp)
    jal  checkBlankInput
    beq  $v0, 1, useDefaultParams

    # numeric check
    lw   $a0, 0($sp)
    jal  checkInputNumeric
    beq  $v0, $zero, invalidInitParamInput

    # convert buffer -> int
    lw   $a0, 0($sp)
    jal  convertStrToInt

    # store to destination address saved on stack
    lw   $t0, 8($sp)         # dest pointer
    sw   $v0, 0($t0)
    j    initParamComplete

invalidInitParamInput:
    la   $a0, invalidInitLevelMsg
    jal  printString
    j    initPromptLoop

useDefaultParams:
    lw   $t1, 4($sp)         # default
    lw   $t0, 8($sp)         # dest pointer
    sw   $t1, 0($t0)

initParamComplete:
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra


# checkBlankInput — Returns 1 if input only newline, else 0
# $a0 = buffer address, $v0 = result
checkBlankInput:
    lb $t0, 0($a0)  # load first byte
    li $t1, 10  # newline ASCII code
    beq $t0, $t1, isBlank
    li $v0, 0          # not blank
    jr $ra

isBlank:
    li $v0, 1          # blank input
    jr $ra

# checkInputNumeric — Checks if string contains only digits 0–9
# Input  $a0 = string address
# Output $v0 = 1 if all digits, 0 otherwise
checkInputNumeric:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    move $t0, $a0          # move string address to temporary register

checkNumericLoop:
    lb   $t1, 0($t0)       # load current byte
    # changed these as not compatible with stripWhiteSpace
    # li   $t2, 10  # load newline ASCII code
    # beq  $t1, $t2, isAllDigits  # if newline → done
    beqz $t1, isAllDigits
    li $t2, 10 #'\n'
    beq $t1, $t2, isAllDigits

    blt  $t1, '0', notAllDigits   # below '0'? invalid
    bgt  $t1, '9', notAllDigits   # above '9'? invalid

    addi $t0, $t0, 1        # move to next char
    j    checkNumericLoop

notAllDigits:
    li   $v0, 0
    j    endNumericInputCheck

isAllDigits:
    li   $v0, 1

endNumericInputCheck:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# convertStrToInt — Converts a numeric string (only digits) to integer
# Input  $a0 = string address
# Output $v0 = integer value (safe, overflow-protected)
convertStrToInt:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    move $t0, $a0          # pointer to string
    li   $t4, 0            # accumulator = 0

convertStr2IntLoop:
    lb   $t1, 0($t0)       # load current character
    beq  $t1, $zero, convertStr2IntDone
    li   $t2, 10
    beq  $t1, $t2, convertStr2IntDone

    li   $t2, 48
    sub  $t1, $t1, $t2     # convert ASCII → numeric digit (0–9)

    move $t3, $t4          # save current accumulator before multiply
    mul  $t4, $t4, 10      # shift previous digits left by one decimal place

    # --- Overflow check (approximation via comparison) ---
    blt  $t4, $t3, overflow   # if new value < old value → overflow occurred

    add  $t4, $t4, $t1     # add new digit to accumulator
    blt  $t4, $t3, overflow # check again after addition

    addi $t0, $t0, 1        # move to next char
    j    convertStr2IntLoop

overflow:
    li   $t4, 0             # reset accumulator to safe zero
    j    convertStr2IntDone

convertStr2IntDone:
    move $v0, $t4           # move accumulator into return register
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra



# checkInitEnergyStatus — Determines if the pet is alive or dead based on user inputs upon app startup
# and displays the appropriate status message accoridngly 
checkEnergyStatus:
    addi $sp, $sp, -4        # Allocate stack space
    sw   $ra, 0($sp)         # Save return address

    # --- Load current energy value ---
    la   $t0, currentEnergy  # Load address of currentEnergy
    lw   $t1, 0($t0)         # Load its value into $t1

    # --- Compare with zero ---
    blez $t1, petDead        # If currentEnergy ≤ 0 → dead
    # otherwise, exit
    lw   $ra, 0($sp)          # Restore return address
    addi $sp, $sp, 4          # Deallocate stack
    jr   $ra                  # Return to caller
 
petDead:
    # set currentEnergy to 0 
    lw $t1, currentEnergy
    add $t1, $0, $0 
    sw $t1, currentEnergy
    # print death message and healthBar
    la $a0, death_message1
    jal  printString 
    jal healthBar
    la $a0, death_message2
    #TODO: give option to enter R or Q here 
    j quit


healthBar:
  addi $sp, $sp, -4
  sw $ra, 0($sp)

  lw $t0, currentEnergy
  lw $t1, MEL
  li $t2, 0
  li $t4, 0

  sub $t3, $t1, $t0

  li $v0, 11
  li $a0, 91 #'['
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
  addi $t4, $t4, 1
  j dash_loop 
end_health_bar:
  li $v0, 11
  li $a0, 93 # ']'
  syscall

  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra 


# displayEnergyStatus - shows numeric energy state as “Energy: current/max”
displayEnergyStatus:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    move $t0, $a0              # save original $a0 in a temporary register

    # --- Print label ---
    la   $a0, energyLabel
    jal  printString
    move $a0, $t0              # restore $a0

    # --- Print current energy value ---
    lw   $a0, currentEnergy
    jal  printInt
    move $a0, $t0

    # --- Print slash separator ---
    la   $a0, slashSymbol
    jal  printString
    move $a0, $t0

    # --- Print maximum energy value ---
    lw   $a0, MEL
    jal  printInt
    move $a0, $t0

    # --- Print newline ---
    la   $a0, newline
    jal  printString

    # --- Restore and return ---
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

     
# ==============================================================
# OUTPUT UTILITIES — Handles all display and printing routines
# ==============================================================
# printString — Prints a string whose address is in $a0
printString:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 4
    syscall

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# printInt - prints the integer value stored in $a0
printInt:
    # --- Save return address on stack (safety) ---
    addi $sp, $sp, -4      # make space on the stack
    sw $ra, 0($sp)         # store return address

    # --- Perform the print syscall ---
    li $v0, 1              # service code for print integer
    syscall                # print the integer stored in $a0

    # --- Restore return address and stack ---
    lw $ra, 0($sp)         # load saved return address
    addi $sp, $sp, 4       # free the stack space

    jr $ra                 # return to caller
    
# displayConfig - displays EDR, MEL, and IEL configuration values
displayConfig:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $a0, edrLabel
    lw $a1, EDR
    la $a2, edrUnits
    jal printLabelAndValue

    la $a0, melLabel
    lw $a1, MEL
    la $a2, melUnits
    jal printLabelAndValue

    la $a0, ielLabel
    lw $a1, IEL
    la $a2, ielUnits
    jal printLabelAndValue
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# printLabelAndValue - prints a label, an integer, and a unit string
# Arguments -
#   $a0 - address of label string
#   $a1 - integer value to print
#   $a2 - address of unit string
printLabelAndValue:
    addi $sp, $sp, -16     
    sw $ra, 0($sp)         
    sw $a0, 4($sp)          # save label address
    sw $a1, 8($sp)          # save integer value
    sw $a2, 12($sp)         # save unit string

    # --- Print label ---
    lw $a0, 4($sp)
    jal printString

    # --- Print integer value ---
    lw $a0, 8($sp)
    jal printInt

    # --- Print unit string ---
    lw $a0, 12($sp)
    jal printString

    lw $ra, 0($sp)         
    addi $sp, $sp, 16     
    jr $ra

# ===================================================================================================================
# GAME COMMAND STUFF - FIND A BETTER NAME FOR THIS SECTION LATER BUT INCLUDES SUBROUTINES FOR FEED, ENTERTAIN ETC.
# ====================================================================================================================
resetEnergy:
    la   $t0, IEL            # Load address of IEL
    lw   $t1, 0($t0)         # Load IEL value
    la   $t2, currentEnergy  # Load address of currentEnergy
    sw   $t1, 0($t2)         # Store IEL value into currentEnergy
    jr   $ra                 # Return to caller

   
   
# ===================================================================================================================
# TIME RELATED STUFF - FIND A BETTER NAME FOR THIS SECTION LATER BUT INCLUDES SUBROUTINES FOR FEED, ENTERTAIN ETC.
# ====================================================================================================================
getSysTime:
    addi $sp, $sp, -8        # create space for $ra and $a0
    sw $ra, 4($sp)
    sw $a0, 0($sp)

    li $v0, 30               # syscall 30 - get system time
    syscall

    move $v0, $a0            # move system time into return register

    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra
    
   
# ===================================================================================================================
# OTHER PROCEDURES CALLED IN GAME LOOP 
# ====================================================================================================================
stripWhiteSpace:
    # preserve registers
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)

    move $s0, $a0        # $s0 = read pointer
    move $s1, $a0        # $s1 = write pointer

strip_loop:
    lb $t0, 0($s0)       # load next byte
    beqz $t0, strip_done # stop at null terminator

    # check for space (0x20), tab (0x09), newline (0x0A)
    li $t1, 32
    beq $t0, $t1, skip_char
    li $t1, 9
    beq $t0, $t1, skip_char
    li $t1, 10
    beq $t0, $t1, skip_char

    # not whitespace → keep it
    sb $t0, 0($s1)
    addi $s1, $s1, 1

skip_char:
    addi $s0, $s0, 1
    j strip_loop

strip_done:
    sb $zero, 0($s1)     # null-terminate the cleaned string

    # restore registers
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    
