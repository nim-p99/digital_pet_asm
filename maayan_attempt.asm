.data
welcomeMessage: .asciiz "=== Digital Pet Simulator (MIPS32) ===\n"
initMessage:    .asciiz "Initialising system...\n\n"

edrPrompt: .asciiz "Enter Natural Energy Depletion Rate (EDR) [Default: 1]: "
melPrompt: .asciiz "Enter Maximum Energy Level (MEL) [Default: 15]: "
ielPrompt: .asciiz "Enter Initial Energy Level (IEL) [Default: 5]: "
invalidInitLevelMsg: .asciiz "Invalid input - programme only accepts positive integers.\nPlease try again: "
invalidEnergyRelationMsg: .asciiz "Invalid relation - initial energy cannot exceed maximum. Please try again.\n"
successMsg: .asciiz "\nParameters set successfully!\n"

edrLabel:   .asciiz "- EDR: "
edrUnits:   .asciiz " units/sec\n"
melLabel:   .asciiz "- MEL: "
melUnits:   .asciiz " units\n"
ielLabel:   .asciiz "- IEL: "
ielUnits:   .asciiz " units\n"

buffer: .space 20
newline: .asciiz "\n"


# Global default variables (persistent state)
EDR: .word 1        # Default value for Natural Energy Depletion Rate
MEL: .word 15       # Default value for Maximum Energy Level
IEL: .word 5        # Default value for Initial Energy Level
currentEnergy: .word 0     # Tracks live energy level during the game


initStatusAlive: .asciiz "Your Digital Pet is alive! Current status:\n"
initStatusDead:  .asciiz "Error, energy level less than or equal 0. Your pet is dead :("

slashSymbol:     .asciiz "/"
barLeftBracket:  .asciiz "["
barRightBracket: .asciiz "]"
filledUnit:      .asciiz "#"
emptyUnit:       .asciiz "-"
energyLabel:     .asciiz "Energy: "
BAR_WIDTH: .word 20
spaceStr:  .asciiz " "

commandPromptStr: .asciiz "\nEnter a command (F, E, P, I, R, Q) > "
todoMsg: .asciiz "Command recognised - feature not yet implemented.\n"
unrecognisedCmdMsg: .asciiz "Unknown command - please try again.\n"

goodbyeMsg: .asciiz "Goodbye! Thanks for playing.\n"



# ========================================================================
# NOTE FOR MAINTAINERS –
# Newline printing currently uses two different methods –
# (1) the defined 'newline' label printed via printString
# (2) the direct ASCII method using syscall 11 with ASCII code 10
#
# Both approaches are functionally correct but stylistically inconsistent.
# The plan is to standardise this later for uniformity and clarity.
# The recommended long-term approach is to use the defined 'newline'
# label with printString for all newline output unless performance testing
# indicates a real-time requirement that benefits from the direct ASCII method.
# ========================================================================


.text
.globl main

main:
    jal initSystem
    jal validateMELIEL
    la  $a0, successMsg
    jal printString
    jal displayConfig
    jal displayStatus
    jal displayEnergyStatus

mainLoop:                     # start of persistent command loop
    jal displayCommandPrompt  # show "Enter a command ..."
    jal readCommandInput      # read into buffer
    jal processCommand        # handle it or print error
    j   mainLoop              # always loop back for now

programExit:
    li  $v0, 10               # reserved for future Quit
    syscall


# ==========================================================
# Subroutine - getInputOrDefault
# Purpose - reads user input or applies default if none given
# Arguments -
#   $a0 - address of prompt string
#   $a1 - default value
#   $a2 - address of input buffer
# Returns -
#   $v0 - integer value entered or default
# ==========================================================
getInputOrDefault:
    # --- Save return address ---
    addi $sp, $sp, -4
    sw $ra, 0($sp)

inputPrompt:
    # --- Display prompt once ---
    jal printString

readInput:
    # --- Read user input as string ---
    li $v0, 8
    move $a0, $a2          
    li $a1, 20              # maximum input length
    syscall

    # --- Check if user pressed only Enter ---
    lb $t0, 0($a2)          # load first character from buffer
    li $t1, 10              
    beq $t0, $t1, useDefaultValue

    # --- Convert string to integer ---
    jal strToInt
    move $t2, $v0           # store result temporarily

    # --- Check for invalid input (-1) ---
    li $t3, -1
    beq $t2, $t3, invalidInputValue

    # --- Valid input path ---
    move $v0, $t2           # return converted integer
    j inputEnd

invalidInputValue:
    # --- Display invalid input message ---
    la $a0, invalidInitLevelMsg
    jal printString

    # --- Re-read input (do not reprint prompt) ---
    j readInput

useDefaultValue:
    move $v0, $a1           # return default value

inputEnd:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# ==========================================================
# Subroutine - strToInt
# Purpose - Converts a numeric string into an integer
# Arguments -
#   $a0 - address of input string
# Returns -
#   $v0 - integer result, or -1 if invalid
# ==========================================================
strToInt:
    # --- Save return address (for consistency) ---
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # --- Initialise result and flags ---
    li $v0, 0               # result = 0
    li $t0, 0               # flag = 0 (no error)

readDigitLoop:
    lb $t1, 0($a0)          
    beqz $t1, conversionEnd 
    li $t2, 10              
    beq $t1, $t2, conversionEnd # stop if newline

    # --- Validate that character is a digit ---
    li $t3, '0'
    blt $t1, $t3, invalidInput
    li $t4, '9'
    bgt $t1, $t4, invalidInput

    # --- Convert ASCII to integer ---
    sub $t1, $t1, 48       
    mul $v0, $v0, 10        
    add $v0, $v0, $t1       

    addi $a0, $a0, 1       
    j readDigitLoop

invalidInput:
    li $v0, -1              
    j conversionEnd

conversionEnd:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ==========================================================
# Subroutine - validateMELIEL
# Purpose - Ensures IEL <= MEL, else re-prompts both
# ==========================================================
validateMELIEL:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

retryRelation:
    lw $t0, MEL
    lw $t1, IEL

    # --- Check relation (IEL <= MEL) ---
    ble $t1, $t0, relationOK

    # --- Relation invalid ---
    la $a0, invalidEnergyRelationMsg
    jal printString

    # --- Prompt user for new MEL ---
    la $a0, melPrompt
    lw $a1, MEL
    la $a2, buffer
    jal getInputOrDefault
    sw $v0, MEL

    # --- Prompt user for new IEL ---
    la $a0, ielPrompt
    lw $a1, IEL
    la $a2, buffer
    jal getInputOrDefault
    sw $v0, IEL

    # --- Retry the validation ---
    j retryRelation

relationOK:
    # --- Update currentEnergy for consistency ---
    lw $t2, IEL
    sw $t2, currentEnergy

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
# ==========================================================
# Subroutine - printString
# Purpose - prints the string stored at the address in $a0
# Arguments -
#   $a0 - address of the null-terminated string to print
# ==========================================================
printString:
    # --- Save return address on stack (safety) ---
    addi $sp, $sp, -4      # make space on stack
    sw $ra, 0($sp)         # store return address

    # --- Perform the print syscall ---
    li $v0, 4              # service code for print string
    syscall                # print the string at $a0

    # --- Restore return address and stack ---
    lw $ra, 0($sp)         # load saved return address
    addi $sp, $sp, 4       # free the stack space

    jr $ra                 # return to caller

# ==========================================================
# Subroutine - printInt
# Purpose - prints the integer value stored in $a0
# Arguments -
#   $a0 - integer value to print
# ==========================================================
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

# ==========================================================
# Subroutine - printLabelAndValue
# Purpose - prints a label, an integer, and a unit string
# Arguments -
#   $a0 - address of label string
#   $a1 - integer value to print
#   $a2 - address of unit string
# ==========================================================
printLabelAndValue:
    addi $sp, $sp, -12     
    sw $ra, 0($sp)         
    sw $a1, 4($sp)        
    sw $a2, 8($sp)         

    # --- Print label ---
    jal printString        

    # --- Print integer value ---
    lw $a0, 4($sp)        
    jal printInt          

    # --- Print unit string ---
    lw $a0, 8($sp)         
    jal printString        

    lw $ra, 0($sp)         
    addi $sp, $sp, 12     
    jr $ra                 

# ==========================================================
# Subroutine - initSystem
# Purpose - performs all programme initialisation tasks
# ==========================================================

initSystem:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # --- Display welcome and initialisation messages ---
    la $a0, welcomeMessage
    jal printString

    la $a0, initMessage
    jal printString

    la $a0, edrPrompt       
    li $a1, 1               
    la $a2, buffer          
    jal getInputOrDefault   
    sw $v0, EDR             

    la $a0, melPrompt
    li $a1, 15
    la $a2, buffer
    jal getInputOrDefault
    sw $v0, MEL             

    la $a0, ielPrompt
    li $a1, 5
    la $a2, buffer
    jal getInputOrDefault
    sw $v0, IEL            

    # --- Set current energy equal to IEL ---
    lw $t0, IEL
    sw $t0, currentEnergy

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
# ==========================================================
# Subroutine - displayConfig
# Purpose - displays EDR, MEL, and IEL configuration values
# ==========================================================
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
    
# ==========================================================
# Subroutine - displayStatus
# Purpose - checks if the Digital Pet is alive or dead and displays the result
# ==========================================================
displayStatus:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, IEL             

    blez $t0, petDead       

    la $a0, initStatusAlive
    jal printString
    j statusEnd

petDead:
    la $a0, initStatusDead
    jal printString

statusEnd:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
# ========================================================================
# NOTE FOR MAINTAINERS –
# This subroutine is intentionally kept separate from displayEnergyStatus
# even though both are currently always called together.
# The separation preserves modularity and future flexibility –
# if the simulator later includes real-time updates or graphical changes,
# this function can be reused independently.
# If the system remains static and no independent usage arises,
# it may be safely merged into displayEnergyStatus for simplicity.
# ========================================================================


# =======================================================================================
# Subroutine - displayEnergyBar
# Purpose - prints a fixed-width bar scaled to IEL/MEL
# Behaviour - prints "[" then filled "#" then empty "-" then "]" and a trailing space
#             does NOT print a newline so caller can add text on the same line
# ======================================================================================

displayEnergyBar:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, IEL           # current energy
    lw   $t1, MEL           # maximum energy
    lw   $t2, BAR_WIDTH     # desired on-screen width

    # Guard against zero or negative MEL
    blez $t1, bar_all_empty   # if MEL <= 0 show empty bar
    mul  $t3, $t0, $t2
    div  $t3, $t1
    mflo $t4                
    bltz $t4, bar_fill_zero
    bgt  $t4, $t2, bar_fill_max
    j    bar_print

bar_fill_zero:
    li   $t4, 0
    j    bar_print

bar_fill_max:
    move $t4, $t2

bar_all_empty:
    li   $t4, 0
    lw   $t2, BAR_WIDTH

bar_print:
    la   $a0, barLeftBracket
    jal  printString
    move $t5, $zero
    
bar_loop_filled:
    beq  $t5, $t4, bar_filled_done
    la   $a0, filledUnit
    jal  printString
    addi $t5, $t5, 1
    j    bar_loop_filled

bar_filled_done:
    # emptyUnits = BAR_WIDTH - filledUnits
    sub  $t6, $t2, $t4
    move $t7, $zero
    
bar_loop_empty:
    beq  $t7, $t6, bar_right
    la   $a0, emptyUnit
    jal  printString
    addi $t7, $t7, 1
    j    bar_loop_empty

bar_right:
    # Print right bracket and a trailing space
    la   $a0, barRightBracket
    jal  printString
    la   $a0, spaceStr
    jal  printString

    # Restore and return
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ==========================================================
# Subroutine -  displayEnergyStatus
# Purpose - prints energy bar and numeric values on one line
# ==========================================================
displayEnergyStatus:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  displayEnergyBar

    la   $a0, energyLabel
    jal  printString
    lw   $a0, IEL
    jal  printInt
    la   $a0, slashSymbol
    jal  printString
    lw   $a0, MEL
    jal  printInt
    la   $a0, newline
    jal  printString

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
displayCommandPrompt:
    addi $sp, $sp, -4       # Save return address
    sw   $ra, 0($sp)

    la   $a0, commandPromptStr
    jal  printString

    lw   $ra, 0($sp)        # Restore return address
    addi $sp, $sp, 4
    jr   $ra

# ==========================================================
# Subroutine - readCommandInput
# Purpose - reads a command string from user into buffer
# ==========================================================
readCommandInput:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $v0, 8             # syscall for read string
    la   $a0, buffer        # store input here
    li   $a1, 20            # max input length
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# =================================================================================================
# Subroutine - processCommand
# Purpose - interprets first character of user command and maps to correct corresponding action
# ==================================================================================================
processCommand:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    la   $t0, buffer        # address of input string
    lb   $t1, 0($t0)        # load first character

    # --- Recognised commands ---
    li   $t2, 'F'
    beq  $t1, $t2, handleTodo
    li   $t2, 'E'
    beq  $t1, $t2, handleTodo
    li   $t2, 'P'
    beq  $t1, $t2, handleTodo
    li   $t2, 'I'
    beq  $t1, $t2, handleTodo
    li   $t2, 'R'
    beq  $t1, $t2, handleTodo
    li   $t2, 'Q'
    beq  $t1, $t2, handleQuit

    # --- Anything else is unrecognised ---
    la   $a0, unrecognisedCmdMsg
    jal  printString
    j    endProcess

handleTodo:
    la   $a0, todoMsg
    jal  printString
    j    endProcess

endProcess:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
# ==========================================================
# Subroutine - handleQuit
# Purpose - cleanly terminates the programme when user enters Q
# ==========================================================
handleQuit:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # --- Optional goodbye message ---
    la   $a0, newline
    jal  printString
    la   $a0, goodbyeMsg
    jal  printString

    li   $v0, 10
    syscall
    
# ========================================================================
# NOTE FOR MAINTAINERS –
# Although the stack operations (saving and restoring $ra) appear redundant
# because this subroutine ends the programme with a syscall, they are kept
# deliberately for consistency with all other subroutines.
# This design choice ensures safe extensibility –
# if future updates add shutdown routines such as saving state data,
# writing logs, or displaying summary statistics, $ra preservation
# will already be in place to prevent unintended return-address corruption.
# If the quit routine permanently remains a single syscall with no further
# operations, these stack steps may later be safely removed for simplicity.
# ========================================================================







