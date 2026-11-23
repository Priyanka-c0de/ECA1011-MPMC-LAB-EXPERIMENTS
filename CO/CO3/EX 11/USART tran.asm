; Program A - USART Initialisation and String Transmission
; 8086 Assembly (MASM/TASM-style source)
; Start address : 1100H
;
; I/O port map:
;   8253 control word register = FF06H
;   8253 counter 2             = FF04H
;   8251 status/control        = FF12H
;   8251 data                  = FF10H
;
; Transmits: "SIMATS" followed by CR and LF (8 bytes).
; Assumption: DS addresses the memory area containing offset 1650H.

        .8086

        ORG     1100H

START:  MOV     DX, 0FF06H       ; 8253 control word register
        MOV     AL, 0B6H         ; Counter 2, LSB/MSB, mode 3
        OUT     DX, AL

        MOV     DX, 0FF04H       ; 8253 counter 2
        MOV     AL, 27H          ; N = 39 (decimal)
        OUT     DX, AL
        MOV     AL, 00H          ; High byte of count = 00H
        OUT     DX, AL

        MOV     DX, 0FF12H       ; 8251 control/status port
        MOV     AL, 00H          ; Three dummy writes
        OUT     DX, AL
        OUT     DX, AL
        OUT     DX, AL

        MOV     AL, 40H          ; 8251 internal reset
        OUT     DX, AL
        MOV     AL, 4EH          ; Async, x16, 8 data bits, no parity, 1 stop
        OUT     DX, AL
        MOV     AL, 37H          ; RTS, error reset, Rx enable, DTR, Tx enable
        OUT     DX, AL

        MOV     SI, 1650H        ; SI points to message
        MOV     CX, 0008H        ; 8 characters: SIMATS + CR + LF

NEXTC:  MOV     DX, 0FF12H       ; 8251 status port
WAITT:  IN      AL, DX
        TEST    AL, 01H          ; TxRDY (status bit 0) set?
        JZ      WAITT            ; Wait until transmitter is ready

        MOV     AL, [SI]         ; Get next character
        MOV     DX, 0FF10H       ; 8251 data port
        OUT     DX, AL           ; Transmit character
        INC     SI
        LOOP    NEXTC

        HLT

; Message is placed at offset 1650H in the same data segment.
        ORG     1650H
MESSAGE DB      'SIMATS', 0DH, 0AH

        END     START
