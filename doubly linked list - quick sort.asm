#############################
# CODE BY JOZSEF NAGY, Dec 3rd 2023
#############################


# $s0 = Address of current node
# $s1 = Quick sort beginning index
# $s2 = quick sort loop / deleting node
# $s3 = quick sort j address/ loop counter for zeroing out elements
# $s4 = quick sort j value
# $s5 = loop counter in zeroing out datafields / quick sort end index
# $s6 = Quick sort tail node
# $s7 = Head node's address (STATIC))
# $t0 = Address of previous node / quicksort: boolan value  holder
# $t1 = Register used for printing / quick sort high
# $t2 = Register used for printing / traversing / quicksort
# $t3 = Register used for printing/ message printing / quick sort boolan value
# $t4 = Loop counter / quick sort j=low
# $t5 = used for zeroing out elements, it stores datafield address
# $t6 = node value to enter / Quick sort: i index
# $t7 =  Quick sort: j index
# $t8 = User menu choice / loop counter for +1o elements / quick sort pivot
# $t9 = List's size (STATIC)

.data
space: .asciiz ", "			# space for between list elements
prompt_menu: .asciiz "\n\nWhat do you want to do?\n\nI.     Push (Insert New Node to the end of list) = 1\nII.    Pop (Remove Last Node in list) = 2\nIII.   Zero out all elements = 3\nIV.    Add 10 random integer to list = 4\nV.     Quick Sort = 5\nVI.    Exit = -1\n"
user_message1: .asciiz "\nCurrent list: "
user_message2: .asciiz "\nWe popped the following item from the end of the list: "
user_message3: .asciiz "\nList is empty, there is nothing to pop / delete. We are going back to menu:"
user_message4: .asciiz "\nList is empty, there is nothing zero out. We are going back to menu:"
user_message5: .asciiz "\nWe set all element to be 0 in our list.\n"
user_message6: .asciiz "\nList is empty, there is nothing sort. We are going back to menu:"
user_prompt1: .asciiz "\nEnter an integer: \n"


.macro PRINT_STRING(%x)
	li $v0, 4			# Service call 4 = print string
	move $a0, %x			# we move contents from $t4 to $a0
	syscall
.end_macro

.macro PRINT_INT(%x)
	li $v0, 1			# Service call 1 = print signedint
	move $a0, %x			# we move contents to print to $a0
	syscall
.end_macro

.macro MENU()
	# Print menu uptions
  	li $v0, 4       	  		# System call 4 = print string
	la $a0, prompt_menu   	        	# Load the address of the menu string
    	syscall
    	# Read user input
    	li $v0, 5				# System call 5 = $v0 contains integer read
   	syscall
   	move $t8, $v0				# we store user choice in $t8
   	beq $t8, 1, LIST_ADD_NODE		# If user_menu_choice == 1 -> LIST_ADD_NODE
   	beq $t8, 2, LIST_POP			# If user_menu_choice == 2 -> LIST_POP
   	beq $t8, 3, LIST_CLEAR_ELEMENTS		# If user_menu_choice == 3 -> LIST_CLEAR_ELEMENTS
   	beq $t8, 4, MENU_LIST_ADD_TEN_ELEMENTS	# If user_menu_choice == 4 -> LIST_ADD_TEN_ELEMENTS
        beq $t8, 5, MENU_QUICKSORT		# If user_menu_choice == 5 -> QUICKSORT
   	beq $t8, -1, EXIT			# If user_menu_choice == -1 -> EXIT
   	
.end_macro 

.macro ENTER_NODE_VALUE(%entered_value)
  	li $v0, 4       	  		# System call 4 = print string
	la $a0, user_prompt1			# Load the address of the prompt string
    	syscall
   	li $v0, 5				# System call 5 = read signed int
   	syscall	
   	move %entered_value, $v0		# selected register = $v0 which contains user entered value

.end_macro 

.macro LIST_ADD_NODE(%entered_value)	
	li $a0, 12				# 12 bytes to allocate (4 previous address, 4 for string content, 4 for next address)
	li $v0, 9				# Service Call - 9 = sbrk (allocate heap memory)
	syscall					# $v0 contains address of allocated memory
	move $s0, $v0				# we move memory address requested to $s0	
	bgt $t9, $zero, LIST_NOT_EMPTY		# check if list is empty. $t9 is size of list. 		
	
	sw $zero, 0($s0)			# Headnode's previous node = Nullptr. Means we are the beginning of list
	#ENTER_NODE_VALUE($t6)
	sw %entered_value, 4($s0)		# we store read integer value
	sw $zero, 8($s0)			# Next node = Nullptr	
	add $t9, $t9, 1				# ++ list node counter
	move $s7, $s0				# creating head node's address
	move $t0, $s0				# This will be previous node's address when we create new node
	j DONE_ADDING_NODE			# we finished adding head node
	
	LIST_NOT_EMPTY:
	FIND_TAIL_NODE($t1)			# t1 has the address of tail node
	#ENTER_NODE_VALUE($t6)
	sw %entered_value, 4($s0)		# we store read integer value
	move $t0, $t1				# t0 = t1
	sw $t0, 0($s0)				# we store previous node pointer in current node
	sw $s0, 8($t0)				# we store current node's pointer in previous node	

   	sw $zero, 8($s0)			# Next node = Nullptr			
	add $t9, $t9, 1				# ++ list node counter
	move $t0, $s0				# This will be previous node's address when we create new node
	DONE_ADDING_NODE:
.end_macro 

.macro EXIT ()
	li $v0, 10				# Service call 10 = exit
	syscall
.end_macro

.macro LIST_PRINT
  	li $v0, 4       	  		# System call 4 = print string
	la $a0, user_message1  	        	# Load the address of the user_message string
    	syscall
    	move $t1, $s7				# Initialize t1 with head node's address
	list_print_loop:
	 	lw $a0, 4($t1)			# Load the address of the string in the current node to $t2
 		li $v0, 1       	  	# System call 1 = print signed int
		syscall
		
		la $a0, space			# Load the address of the space separator
		li $v0, 4       		# System call 4 = print string
		syscall
		
		lw $t3, 8($t1)
		
		beqz $t3, list_print_loop_done
		move $t1, $t3
		j list_print_loop
	list_print_loop_done:
.end_macro

.macro NODE_DELETE(%node_address)
	addi $t4, $t4, 5			# loop counter for zeroing out the node we are deleting
	move $s2, %node_address			# s2 = node address we want delete
	node_delete_loop:
	sw $zero, 0($s2)			# zeroing out all addresses of node
	addi $s2, $s2, 4			# increment address
	subi $t4, $t4, 1			# decreement loop counter
	bgtz $t4, node_delete_loop		# if loop counter > 0, we repeat loop
	subi $t9, $t9, 1			# we substract one from list size
.end_macro

.macro LIST_POP()
	beqz $t9, empty_list			# if list is empty there is nothing to delete
	FIND_TAIL_NODE($t1)			# t1 has the address of tail node
	la $t3, user_message2			# we load user message2
	PRINT_STRING($t3)			# we print user message2
	lw $t3, 4($t1)				# we load int that we are about to delete for printing
	PRINT_INT($t3)				# we print int we are about to delete
	lw $t1, 0($t1)				# we return to previous node
	beqz $t1, it_is_head_node		# if previous node pointer == 0, we delete headnode
	move $t2, $t1				# set up temp address $t2 = $t1
	lw $t1, 8($t1)				# we move to the next node
	sw $zero, 8($t2)			# setting up node as tail node. Next node's pointer = nullptr
	NODE_DELETE($t1)			# we are passing the register containg the address of the node we are deleting
	j node_pop_finish			# we jump to the end of the code, skipping rest of code
	it_is_head_node:
	NODE_DELETE($s7)			# we just pass address of head node for deletion
	j node_pop_finish			# we jump to the end of the code, skipping rest of code	
	empty_list:				# this code to execute if list size == 0
	la $t3, user_message3			# we load user message3
	PRINT_STRING($t3)			# we print user message3
	node_pop_finish:
	li $t1, 0				# we reset t1 register.
	
.end_macro

.macro LIST_CLEAR_ELEMENTS()
	beqz $t9, empty_list			# if list is empty there is nothing to zero out 
    	move $t1, $s7				# Initialize t1 with head node's address
    	move $t5, $s7				# initalize t5 with head node's address
    	move $s3, $t9				# we make $s3 equal to $t9, which is the size of the list

    	list_clear_elements_loop:
	jal LIST_CLEAR_NODE_DATA
	lw $t1, 4($t5)				# Load address of the next node into t1
	move $t5, $t1				# t5 = t1
	bnez  $t1, list_clear_elements_loop	# if next address != nullptr, we havent reached tail node yet
	j list_clear_elements_finish		# we finished zeroing out elements
	
	empty_list:				# this code to execute if list size == 0
	la $t3, user_message4			# we load user message4
	PRINT_STRING($t3)			# we print user message4
	list_clear_elements_finish:
	li $s5, 0				# we reset t5 register.
	li $t1, 0				# we reset t1 register.

.end_macro

.macro FIND_TAIL_NODE(%tail_node_addy)		# it returns tail_node_addy with tail node's address
    	move %tail_node_addy, $s7		# Initialize tail_node_addy with head node's address
    	beq $t9, 1, found_tail_node		# if list size == 1, head node = tail node
	list_traverse:				# we are looking for the tail node
	lw $t2, 8(%tail_node_addy)		# Load address of the next node into t2
	beqz $t2, found_tail_node
	move %tail_node_addy, $t2		# we set tail_node_addy equal to next node's address
	j list_traverse				# if next node's address > 0 -> not tail node, move to next node
	found_tail_node:
.end_macro
	
.macro GENERATE_RND_NUM(%generated_number)
	li $v0, 42				# 42 is system call code to generate random int
	li $a1, 1001				# $a1 is where we set the upper bound
	syscall					# generated number is at $a0
	move %generated_number, $a0
.end_macro

.macro GET_LIST_SIZE(%list_size)
	move %list_size, $t9			# we get the size of the list
.end_macro
.text 	
MENU:
	MENU()
LIST_ADD_NODE:
	ENTER_NODE_VALUE($t6)
	LIST_ADD_NODE($t6)
	LIST_PRINT()
	MENU()
LIST_POP:
	LIST_POP()
	beqz $t9, MENU				# if list is empty we are returning to menu	
	LIST_PRINT()
	MENU()
LIST_CLEAR_ELEMENTS:
	LIST_CLEAR_ELEMENTS()
	beqz $t9, MENU				# if list is empty we are returning to menu	
	LIST_PRINT()
	MENU()
MENU_LIST_ADD_TEN_ELEMENTS:
	li $t8, 10
	add_ten_loop:
	GENERATE_RND_NUM($t6)			# we generate random number to add
	LIST_ADD_NODE($t6)
	subi $t8, $t8, 1			# we substract 1 from loop coutbner
	bne $zero, $t8, add_ten_loop		# we repeat 10 times
	LIST_PRINT()
	MENU()
MENU_QUICKSORT:	
	beqz $t9, quick_sort_empty_list		# if list is empty there is nothing to sort
	move $a0, $s7				# Initialize a0 with head node's address
	GET_LIST_SIZE($a2)			# a2 has size of list; and this is also last index
	li $a1, 1				# a1 has starting index
    	li $v0, 0				# used in recursion: i+1
	jal QUICKSORT				# Call quicksort function
	

    
	LIST_PRINT()
	MENU()
EXIT:
	EXIT()
	
	
LIST_CLEAR_NODE_DATA:
	subi $sp, $sp, 4			# save space on the stack
 	sw $ra, 0($sp)				# save the return address
	addi $t5, $t5, 4			# we access datafield of node
	sw $zero, 0($t5)			# we store 0 
	lw $ra, 0($sp)				# restore the return address
	addi $sp, $sp, 4			# restore the stack pointer
	jr $ra	

# Everything belongs to quick sort below this:

QUICKSORT:					
	# a0 = tail node address
	# a1 = beginning index
	# a2/s5 = ending index
	# s0 = 
	# s3 = j address
	# s4 = j value
	# t0 = boolen value holder
	# $t1 = high - 1
	# $t2 = used in subroutines pulling addys / holding boolen value
	# $t4 = i - 1 
	# $t5 = j - 1
	# $t6 = i index
	# $t7 = j index
	# $t8 = pivot
	# t9 = pivot's address	
	subi $sp, $sp, 20			# we create room for 5 words
	sw $a0, 0($sp)				# starting addy
	sw $a1, 4($sp)				# low - A [ beginning index] 
	sw $a2, 8($sp)				# high - A[ last index]
	sw $t9, 12($sp)				# we store list size
	sw $ra, 16($sp)				# return address
	
	move $s5, $a2				# saving high ; A[ last index]
	
	slt $t3, $a1, $s5			# t3=1 if low < high, else 0
	beq $t3, $zero, QUICKSORT_DONE		# if low >= high, QUICKSORT_DONE
	
	jal QUICKSORT_PARTITION			# we are partitioning
						
	move $s0, $v0				# pivot, s0= v0, we keep track on pivot's position between calls

	lw $a1, 4($sp)				# a1 = low 
	subi $a2, $s0, 1			# a2 = pivot -1
	jal QUICKSORT				# call quicksort <- LEFT SUBARRAY CALL
						# so we partition from low index to pivot -1 

	addi $a1, $s0, 1			# a1 = pivot + 1 
	lw $a2, 8($sp)				# a2 = high
	jal QUICKSORT				# call quicksort <- RIGHT SUBARRAY CALL
    						# we partition from pivor +1 to high index
	QUICKSORT_DONE:
 	lw $a0, 0($sp)				# restore a0
 	lw $a1, 4($sp)				# restore a1
 	lw $a2, 8($sp)				# restore a2
 	lw $t9, 12($sp)				# restore list size
 	lw $ra, 16($sp)				# restore return address
 	addi $sp, $sp, 20			# restore the stack
 	jr $ra					# return to caller
      		
      	
      	
      	quick_sort_empty_list:			# this code to execute if list size == 0
	la $t3, user_message6			# we load user message4
	PRINT_STRING($t3)			# we print user message4
	li $s5, 0				# we reset t5 register.
	li $t1, 0				# we reset t1 register.
      	j MENU
      	
QUICKSORT_SWAP:
	# gotta pass addresses of data fields of $s2 = a[i] and $s3 = a[j].

	subi $sp, $sp, 20			# create space for 5 words on stack
	sw $s2, 0($sp)				# Store A[i]
	sw $s3, 4($sp)				# Store A[j]
	sw $ra, 8($sp)				# we store return address
	sw $t6, 12($sp)				# we store i
	sw $t7, 16($sp)				# we store j
 
 	lw $s2, 4($sp)				# we load the word stored in stack pointer sp(4) which is address of A[J]. So, A[i] = A]j]
 	lw $s3, 0($sp)				# we load the word stored in stack pointer sp(0) which is address of A[i]. So, A[j] = A[i]
 	# now $s2 and $s3 has addresses swapped
 	lw $t6, 0($s2)				# we load value of $s2 to $t6 => A[i]
	lw $t7, 0($s3)				# we load value of $s3 to $t7 => A[j]
	# now we swap values
	sw $t7, 0($s2)				# we store a[j] into a[i]
	sw $t6, 0($s3)				# we store a[i] into a[j]

	lw $s2, 0($sp)				# restore A[i]
	lw $s3, 4($sp)				# restore A[j]
	lw $ra, 8($sp)				# restore return address
	lw $t6, 12($sp)				# restore i
	lw $t7, 16($sp)				# restore j
	addi $sp, $sp, 20			# restore stack pointer
	
	jr $ra					# return to caller

QUICKSORT_PARTITION:
	subi $sp, $sp, 4				# we create space for 1 word on stack
	sw $ra, 0($sp)					# store return address
	
	move $t6, $a1					# t6 = low
	move $t7, $a2					# t7 = high
							# get high index element to make it pivot, put into t8	
	jal QUICKSORT_GET_PIVOT				# here we get pivot and put into t8

	addi $t3, $t6, -1 				# t3, i=low -1
	move $t4, $t6					# t4, j=low
	addi $t1, $t7, -1				# t1 = high - 1
							# we partition between these 2 indexes (i(t3) and j(t1)
	QUICKSORT_LOOP: 		
		slt $t0, $t1, $t4			# t0=1 if j>high-1, t0=0 if j<=high-1
							# here we check if j==i, if yes then we're done with partition
		bne $t0, $zero, QUICKSORT_PARTITION_END	# if t0=1 then branch to QUICKSORT_END

		jal QUICKSORT_GET_J			# we need to get node * j ($t4) and put the value into s4, so s4 = A[t4]

		slt $t2, $t8, $s4			# t2 = 1 if pivot(t8) < A[j](s4), t2=0 if A[j](s4)<=pivot(t8)
							# if pivot is smaller than A[j] skip, if A[j] is smaller than pivot then we've to swap
		bne $t2, $zero, QUICKSORT_SKIP		# if t2=1 then branch to endfif
		addi $t3, $t3, 1			# i=i+1; increment i index 
							
		jal QUICKSORT_GET_I_ADDRESS		# we are getting the address of A[i] and put it into s2
							#  s2 has address of A[i]
							#  s3 has address of A[j]
							# here we need to pass addresses of elements to swap
		
		jal QUICKSORT_SWAP			# swap A[i] with A[j]

		addi $t4, $t4, 1			# j++; increment j index
		j QUICKSORT_LOOP			# jump back to QUICKSORT_LOOP

	QUICKSORT_SKIP:
		addi $t4, $t4, 1			# j++
		j QUICKSORT_LOOP			# jump back to QUICKSORT_LOOP


	QUICKSORT_PARTITION_END:			# we're gona move pivot to place of i+1
		addi $a1, $t3, 1			# a1 = i+1
		move $a2, $t7				# a2 = high
		add $v0, $zero, $a1			# v0 = i+1 return (i + 1);
		jal QUICKSORT_GET_A1_ADDRESS		# we are getting the address of A[a1] and put it into s2
		move $s3, $t9				# s3 has pivot's address
		jal QUICKSORT_SWAP			# swap(A[i+1] , A[pivot]) so pivot is in correct position

		lw $ra, 0($sp)				# return address
		addi $sp, $sp, 4			# restore the stack
		jr $ra					# jump back to the caller

QUICKSORT_GET_PIVOT:
	subi $sp, $sp, 16			# we create space for 4 words on stack
	sw $ra, 0($sp)				# we store return address
	sw $t7, 4($sp)				# we store high in sp
	sw $t2, 8($sp)				# we store t2 as well
	sw $a0, 12($sp)				# we store head node address too
	
	subi $t7, $t7, 1			# we substract 1 from loop counter because head node's next address is 0
	pivot_list_traverse:			# we are looking for last node in range
	lw $t2, 8($a0)				# Load address of head node		
	move $a0, $t2				# we set a0 equal to next node's address
	subi $t7, $t7, 1			# we substract one from loop counter
	bne $t7, $zero, pivot_list_traverse	# we keep loading nodes until loop counter == 0
	lw $t8, 4($a0)				# we load content of last node into $t8, so this is pivot now
	la $t9, 4($a0)				# we load pivot's address to t9
	# we restore registers

	lw $ra, 0($sp)				# restore return address
	lw $t7, 4($sp)				# restore $t7 (high)
	lw $t2, 8($sp)				# restore $t2
	lw $a0, 12($sp)				# restore head node address
	
	addi $sp, $sp, 16			# adjust stack pointer to deallocate the saved space
	jr $ra					# return to caller
	
QUICKSORT_GET_J:
	subi $sp, $sp, 16			# we create space for 4 words on stack
	sw $ra, 0($sp)				# we store return address
	sw $t4, 4($sp)				# we store j index
	sw $t2, 8($sp)				# we store t2 as well
	sw $a0, 12($sp)				# we store head node address 
	
	subi $t4, $t4, 1			# we substract 1 from loop counter because head node's next address is 0
	beq  $t4, $zero, found_j		# we check if this is headnode
	j_list_traverse:			# we are looking for last node in range
	lw $t2, 8($a0)				# Load address of head node		
	move $a0, $t2				# we set a0 equal to next node's address
	subi $t4, $t4, 1			# we substract one from loop counter
	bne $t4, $zero,	j_list_traverse		# we keep loading nodes until loop counter <= 0
	found_j:
	lw $s4, 4($a0)				# we load content of last node into $s4, so this is A[j] now
	la $s3, 4($a0)				# we load address of J into s3
	
	
	# we restore registers
	lw $ra, 0($sp)				# restore return address
	lw $t4, 4($sp)				# restore j index
	lw $t2, 8($sp)				# restore $t2
	lw $a0, 12($sp)				# restore head node address
	
	addi $sp, $sp, 16			# adjust stack pointer to deallocate the saved space
	jr $ra					# return to caller
	
QUICKSORT_GET_I_ADDRESS:
	subi $sp, $sp, 16			# we create space for 4 words on stack
	sw $ra, 0($sp)				# we store return address
	sw $t3, 4($sp)				# we store i index
	sw $t2, 8($sp)				# we store t2 as well
	sw $a0, 12($sp)				# we store head node address 
	
	subi $t3, $t3, 1			# we substract 1 from loop counter because head node's next address is 0
	beq  $t3, $zero, found_i		# we check if this is headnode
	i_list_traverse:			# we are looking for last node in range
	lw $t2, 8($a0)				# Load address of head node		
	move $a0, $t2				# we set a0 equal to next node's address
	subi $t3, $t3, 1			# we substract one from loop counter
	bne $t3, $zero,	i_list_traverse		# we keep loading nodes until loop counter <= 0
	found_i:
	#lw $s4, 4($a0)				# we load content of last node into $s4, so this is A[j] now
	la $s2, 4($a0)				# we load address of J into s3
	
	
	# we restore registers
	lw $ra, 0($sp)				# restore return address
	lw $t3, 4($sp)				# restore j index
	lw $t2, 8($sp)				# restore $t2
	lw $a0, 12($sp)				# restore head node address
	
	addi $sp, $sp, 16			# adjust stack pointer to deallocate the saved space
	jr $ra					# return to caller

QUICKSORT_GET_A1_ADDRESS:
	subi $sp, $sp, 16			# we create space for 4 words on stack
	sw $ra, 0($sp)				# we store return address
	sw $a1, 4($sp)				# we store a1 index
	sw $t2, 8($sp)				# we store t2 as well
	sw $a0, 12($sp)				# we store head node address 
	
	subi $a1, $a1, 1			# we substract 1 from loop counter because head node's next address is 0
	beq  $a1, $zero, found_a1		# we check if this is headnode
	a1_list_traverse:			# we are looking for last node in range
	lw $t2, 8($a0)				# Load address of head node		
	move $a0, $t2				# we set a0 equal to next node's address
	subi $a1, $a1, 1			# we substract one from loop counter
	bne $a1, $zero,	a1_list_traverse	# we keep loading nodes until loop counter <= 0
	found_a1:
	#lw $s4, 4($a0)				# we load content of last node into $s4, so this is A[j] now
	la $s2, 4($a0)				# we load address of J into s3

	# we restore registers
	lw $ra, 0($sp)				# restore return address
	lw $a1, 4($sp)				# restore a1 index
	lw $t2, 8($sp)				# restore $t2
	lw $a0, 12($sp)				# restore head node address
	
	addi $sp, $sp, 16			# adjust stack pointer to deallocate the saved space
	jr $ra					# return to caller
	
