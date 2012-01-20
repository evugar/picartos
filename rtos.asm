	list p=pic12f629
	#include p12f629.inc

	radix dec
	
	#include macros.inc

	extern TaskProcs

shared_vars	udata_ovr
temp1 res 1

shared_vars	udata_ovr
att_temp1 res 1

shared_vars	udata_ovr
addtsk_temp1 res 1


queue_size	equ	10

tskq_data		udata
offset_low	res	1

pq_temp res 1
task_queue_head	res 1
task_queue_tail	res 1
task_queue	res	queue_size

tskq_proc	code




;------------------------------------
do_task

                movwf offset_low
                movlw HIGH TaskProcs        ;get high 8 bits of TaskProcs address
                movwf PCLATH            ;save to PCLATH (may not be correct, yet)
                movlw LOW TaskProcs         ;get TaskProcs low address
                addwf offset_low,W          ;add value of offset, keep result in W
                                        ;if page is crossed, carry will be set
                sknc          ;check page crossed? Skip next if NO
                incf PCLATH             ;yes, increment PCLATH
                movwf PCL



;-------------------------
add_task
		movwf	addtsk_temp1
		movlw	task_queue
		addwf	task_queue_tail, w
		movwf	FSR
		movfw	addtsk_temp1
		movwf	INDF

		movfw	task_queue_tail
		xorlw	queue_size-1
		je		tail_at_end
		incf	task_queue_tail,f
		goto at_proceed
tail_at_end
		clrf	task_queue_tail
at_proceed

		retlw 0		


;------------------------------
process_queue
		movfw	task_queue_head
		subwf	task_queue_tail, w
		jne	pq_not_empty
		call do_task  ; W already = 0 so run idle process (TS_idle)
		retlw 0

pq_not_empty
		movlw	task_queue
		addwf task_queue_head, w
		movwf FSR
		movfw INDF
		call do_task
	
		incf task_queue_head, f
		movfw task_queue_head
		xorlw queue_size
		skne
		clrf task_queue_head
		
		retlw 0
;-------------------------------------


	global add_task, process_queue



timer_queue_size	equ	5

timq_data	udata
timer_delay res 1
timer_task res 1
tp_cur_entry res 1
tp_save_task_id res 1
timer_queue res timer_queue_size * 2  ; 1 byte for TASKID and 1 byte for timer delay value

	global timer_delay


timq_proc		code


;------------------------
add_timer_task
		movwf	timer_task
		movlw timer_queue
		movwf att_temp1
att_loop1
		movfw	att_temp1
		movwf	FSR
		movfw	INDF
		xorlw 0xff			;0xFF -> empty cell
		jne	att_next_cell
		movfw	att_temp1
;		bcf INTCON, GIE
		movwf FSR
		movfw timer_task
		movwf INDF
		incf FSR,f
		movfw timer_delay
		movwf INDF
;		bsf INTCON, GIE
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
		xorlw 0xff		;0xFF -> empty cell
		je tp_next_elem
		incf FSR,f
		decfsz INDF,f
		goto tp_next_elem
		decf FSR,f
		movfw INDF
		movwf tp_save_task_id
		movlw 0xff
		movwf INDF
		movfw tp_save_task_id
		call add_task
tp_next_elem
		incf tp_cur_entry, f
		incf tp_cur_entry, f
		movfw tp_cur_entry
		xorlw timer_queue+timer_queue_size*2
		jne tp_loop1
		retlw 0

;------------------
init_timer_queue
		movlw timer_queue
		movwf temp1
itq_loop1		
		movfw temp1
		movwf FSR
		movlw 0xff		; init with empty marker (0xFF)
		movwf INDF
		incf temp1, f
		movfw temp1
		xorlw timer_queue+timer_queue_size*2
		jne itq_loop1
		retlw 0
	

	global add_timer_task, timer_process, init_timer_queue


	end