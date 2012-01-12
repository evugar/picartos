	list p=pic12f629
	#include p12f629.inc

	__config _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_OFF & _CP_OFF & _CPD_OFF
	radix dec

	#include macros.inc


pin_DEBUG		equ 	5
pin_LED			equ 4
pin_LED2		equ 2

queue_size	equ	10
timer_queue_size	equ	10

		udata 0x20
_save_w res 1
_save_FSR res 1
_save_STATUS res 1
temp1 res 1
att_temp1 res 1
pq_temp res 1
reg_TIMESTAMP res 1
offset_low	res	1

timer_delay res 1
timer_task res 1

queue_head	res 1
queue_tail	res 1
task_queue	res	queue_size

timer_queue res timer_queue_size * 2
tp_cur_entry res 1
tp_save_task_id res 1


reset_vector	code	0x0
		goto start

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
idle
		retlw 0
;------------------------------
delay
	decf TMR0, w
	movwf reg_TIMESTAMP
delay_loop_1
	movf TMR0, w
	subwf reg_TIMESTAMP, w
	btfss STATUS, Z	
	goto delay_loop_1
	retlw 0

;--------------------
delay_3x
		call delay
		call delay
		call delay
		retlw 0

;-----------------------------
pin_debug_on
		bsf		GPIO, pin_DEBUG
		movlw	0x20
		movwf	timer_delay
		movlw TS_pin_debug_off
		call	add_timer_task
		retlw 0
		
;-----------------------------
pin_debug_off
		bcf		GPIO, pin_DEBUG
		movlw	0x20
		movwf	timer_delay
		movlw TS_LED_on
		call	add_timer_task
		retlw 0

;-----------------------------
LED_on
		bsf		GPIO, pin_DEBUG
		movlw	0x20
		movwf	timer_delay
		movlw TS_LED_off
		call	add_timer_task
		retlw 0
		
;-----------------------------
LED_off
		bcf		GPIO, pin_DEBUG
		movlw	0x40
		movwf	timer_delay
		movlw TS_pin_debug_on
		call	add_timer_task
		retlw 0

;-----------------------------
LED2_on
		bsf		GPIO, pin_LED2
		movlw	0x30
		movwf	timer_delay
		movlw TS_LED2_off
		call	add_timer_task
		retlw 0
		
;-----------------------------
LED2_off
		bcf		GPIO, pin_LED2
		movlw	0x30
		movwf	timer_delay
		movlw TS_LED2_on
		call	add_timer_task
		retlw 0

;--------------------------------------
TaskProcs

TS_idle equ 0
		goto	idle

TS_delay equ 1
		goto	delay
		
TS_pin_debug_on equ 2
		goto	pin_debug_on
		
TS_pin_debug_off equ 3
		goto	pin_debug_off

TS_delay_3x equ 4
		goto	delay_3x

TS_LED_on equ 5
		goto	LED_on
		
TS_LED_off equ 6
		goto	LED_off

TS_LED2_on equ 7
		goto	LED2_on
		
TS_LED2_off equ 8
		goto	LED2_off

;------------------------------------
do_task
		movwf	offset_low
		movlw 	LOW TaskProcs
		addwf	offset_low, f
		movlw	HIGH TaskProcs
		btfsc	STATUS, C
		addlw	1
		movwf	PCLATH
		movfw	offset_low
		movwf	PCL


;-------------------------
add_task
		movwf	temp1
		movlw	task_queue
		addwf	queue_tail, w
		movwf	FSR
		movfw	temp1
		movwf	INDF

		movfw	queue_tail
		xorlw	queue_size-1
		je		tail_at_end
		incf	queue_tail,f
		goto at_proceed
tail_at_end
		clrf	queue_tail
at_proceed

		retlw 0		

process_queue
		movfw	queue_head
		subwf	queue_tail, w
		jne	pq_not_empty
		call do_task  ; W already = 0
		retlw 0

pq_not_empty
		movlw	task_queue
		addwf queue_head, w
		movwf FSR
		movfw INDF
		call do_task
	
		incf queue_head, f
		movfw queue_head
		xorlw queue_size
		skne
		clrf queue_head
		
		retlw 0

;------------------------
add_timer_task
		movwf	timer_task
		movlw timer_queue
		movwf att_temp1
att_loop1
		movfw	att_temp1
		movwf	FSR
		movfw	INDF
		xorlw 0xff
		jne	att_next_cell
		movfw	att_temp1
		bcf INTCON, GIE
		movwf FSR
		movfw timer_task
		movwf INDF
		incf FSR,f
		movfw timer_delay
		movwf INDF
		bsf INTCON, GIE
		retlw 0
att_next_cell
		incf att_temp1, f
		incf att_temp1, f
		movfw att_temp1
		xorlw timer_queue+timer_queue_size*2
		jne att_loop1
		retlw 0
		
;---------------------------------
timer_process
		movlw timer_queue
		movwf tp_cur_entry
		
tp_loop1
		movfw tp_cur_entry
		movwf FSR
		movfw INDF
		xorlw 0xff
		je tp_wait_more
		incf FSR,f
		decfsz INDF,f
		goto tp_wait_more
		decf FSR,f
		movfw INDF
		movwf tp_save_task_id
		movlw 0xff
		movwf INDF
		movfw tp_save_task_id
		call add_task
tp_wait_more
		incf tp_cur_entry, f
		incf tp_cur_entry, f
		movfw tp_cur_entry
		xorlw timer_queue+timer_queue_size*2
		jne tp_loop1
		retlw 0
		
				
;----------------------------------
init
	bsf		STATUS, RP0

	movlw b'00000011'		; prescaler 
	banksel OPTION_REG
	movwf	OPTION_REG

	clrf TRISIO				;GP0 - strobe
	movlw b'11001011'		;GP1 - data
	movwf TRISIO				;GP2 - clock

	bcf		STATUS, RP0
	
	bsf INTCON, T0IE
	bsf INTCON, GIE
	retlw 0
	
	

;------------------
init_timer_queue
		movlw timer_queue
		movwf temp1
itq_loop1		
		movfw temp1
		movwf FSR
		movlw 0xff
		movwf INDF
		incf temp1, f
		movfw temp1
		xorlw timer_queue+timer_queue_size*2
		jne itq_loop1
		retlw 0
;---------------------------------
start
		call init
		call init_timer_queue
		
		movlw TS_pin_debug_on
		call add_task
			
;		movlw TS_LED_on
;		call add_task
			
		movlw TS_LED2_on
		call add_task
			
loop_forever
		call process_queue
		goto loop_forever
		end