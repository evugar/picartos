jz macro label
			btfsc	STATUS, Z
			goto label
	endm

je macro label
			btfsc	STATUS, Z
			goto label
	endm

jnz macro label
			btfss	STATUS, Z
			goto label
	endm

jne macro label
			btfss	STATUS, Z
			goto label
	endm

skz macro
			btfss	STATUS, Z
	endm

ske macro
			btfss	STATUS, Z
	endm

sknz macro
			btfsc	STATUS, Z
	endm

skne macro
			btfsc	STATUS, Z
	endm
	
jc macro label
			btfsc	STATUS, C
			goto label
	endm

jnc macro label
			btfss	STATUS, C
			goto label
	endm

skc macro
			btfss	STATUS, C
	endm

sknc macro
			btfsc	STATUS, C
	endm
