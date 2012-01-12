	list p=pic12f629
	#include p12f629.inc

	__config _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_OFF & _CP_OFF & _CPD_OFF
	radix dec

	#include macros.inc

	extern add_task, process_queue

	extern timer_delay
	extern add_timer_task, timer_process, init_timer_queue
	

	
pin_LED			equ 0

reset_vector	code	0x0
		goto start

int_save_reg		udata
_save_w res 1
_save_FSR res 1
_save_STATUS res 1

		
int_vector		code	0x4
		
		movwf _save_w ;copy W to temp register, could be in either bank
		swapf STATUS, w ;swap status to be saved into W
		movwf _save_STATUS ;save status to bank 0 register
		movfw FSR
		movwf _save_FSR

		call timer_process

		movfw _save_FSR
		movwf FSR
		swapf _save_STATUS, w ;swap STATUS_TEMP register into W, sets bank to original state
		movwf STATUS ;move W into STATUS register
		swapf _save_w,F ;swap W_TEMP
		swapf _save_w,W ;swap W_TEMP into W		

		bcf INTCON, T0IF
		
		retfie

main_prog	code

;--------------------------------
task_idle
		retlw 0

;-----------------------------
task_pin_LED_on
		bsf		GPIO, pin_LED
		movlw	150  ; delay 150 ticks
		movwf	timer_delay
		movlw TASKID_pin_LED_off
		call	add_timer_task
		retlw 0
		
;-----------------------------
task_pin_LED_off
		bcf		GPIO, pin_LED
		movlw	150  ; delay 150 ticks
		movwf	timer_delay
		movlw TASKID_pin_LED_on
		call	add_timer_task
		retlw 0
		

;--------------------------------------
;  Table of tasks
;--------------------------------------
TaskProcs

TASKID_idle equ 0	; idle task with id=0 must always be present
		goto	task_idle

TASKID_pin_LED_on equ 1
		goto	task_pin_LED_on
		
TASKID_pin_LED_off equ 2
		goto	task_pin_LED_off
		

	global TaskProcs


		
				
;----------------------------------
init_hw
	bsf		STATUS, RP0

	movlw b'00000000'		; prescaler 
	banksel OPTION_REG
	movwf	OPTION_REG

	clrf TRISIO				; all GPx is output
	movwf TRISIO				

	banksel GPIO
	
	bsf INTCON, T0IE
	bsf INTCON, GIE
	retlw 0
	

;---------------------------------
start
		call init_timer_queue
		
		movlw TASKID_pin_LED_on
		call add_task
			
			
		call init_hw
			
loop_forever
		call process_queue
		goto loop_forever
		end