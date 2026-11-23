; Program B - Reception with Echo and Error Detection
; 8086 Assembly (MASM/TASM-style source)
; Start address : 1200H
;
; I/O port map:
;   8253 control word register = FF06H
;   8253 counter 2             = FF04H
;   8251 status/control        = FF12H
;   8251 data                  = FF10H
;
; Receives 8 characters, stores them from offset 1700H, echoes each one,
; and stores the error count at offset 1710H.
; Assumption: DS addresses the memory area containing offsets 1700H-1710H.

        .8086

        ORG     1200H

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

        MOV     DI, 1700H        ; DI points to receive buffer
        MOV     CX, 0008H        ; Receive 8 characters
        MOV     BL, 00H          ; Clear error counter

NEXTR:  MOV     DX, 0FF12H       ; 8251 status port
WAITR:  IN      AL, DX
        TEST    AL, 02H          ; RxRDY (status bit 1) set?
        JZ      WAITR            ; Wait for received character

        TEST    AL, 38H          ; Check FE, OE, or PE (bits 5, 4, 3)
        JZ      NOERR
        INC     BL               ; Count one character with an error
        MOV     AL, 37H          ; Error reset command
        OUT     DX, AL

NOERR:  MOV     DX, 0FF10H       ; 8251 data port
        IN      AL, DX           ; Read received character
        MOV     [DI], AL         ; Store character in receive buffer
        INC     DI
        MOV     AH, AL           ; Preserve character while polling TxRDY

        MOV     DX, 0FF12H       ; 8251 status port
WAITE:  IN      AL, DX
        TEST    AL, 01H          ; TxRDY (status bit 0) set?
        JZ      WAITE            ; Wait until transmitter is ready

        MOV     AL, AH           ; Restore received character
        MOV     DX, 0FF10H       ; 8251 data port
        OUT     DX, AL           ; Echo character
        LOOP    NEXTR

        MOV     [1710H], BL      ; Store final error count
        HLT

; Reserve the receive buffer and error-count byte at the specified offsets.
; These ORG directives describe the memory layout for a flat/absolute layout.
        ORG     1700H
RXBUFFER DB      8 DUP (?)

        ORG     1710H
ERRORCOUNT DB   ?

        END     START
