asm
; ============================================================
; Elevator controller - PIC18F4520 (MPASM)
; Translated from XC8 C code
; ============================================================
#include <p18f4520.inc>

; ---- Configuration bits ----
CONFIG OSC = XT
CONFIG WDT = OFF
CONFIG LVP = OFF

; ---- Constants ----
STEPS_PER_FLOOR EQU D'200'
UP_LED          EQU 0           ; LATB0
DOWN_LED        EQU 1           ; LATB1
DOOR_LED        EQU 2           ; LATB2

; ---- Variables (Access RAM) ----
UDATA_ACS
floor_now   res 1
req         res 1
direction   res 1
ph          res 1
mv_dir      res 1
s_cnt       res 1
i_cnt       res 1
t_cnt       res 1
dly_cnt     res 1
cnt_h       res 1
cnt_l       res 1

; ---- Reset vector ----
ORG 0x0000
    goto    Main

; ============================================================
; Lookup tables (keep each table inside one 256-byte page)
; ============================================================
seg_tab:
    addwf   PCL, F
    retlw   0x3F            ; floor 0
    retlw   0x06            ; floor 1
    retlw   0x5B            ; floor 2
    retlw   0x4F            ; floor 3

phase_tab:
    addwf   PCL, F
    retlw   0x09
    retlw   0x0C
    retlw   0x06
    retlw   0x03

; 1 << floor_now
bit_mask_tab:
    addwf   PCL, F
    retlw   0x01
    retlw   0x02
    retlw   0x04
    retlw   0x08

; 0x0F & ~((1 << (floor_now+1)) - 1)  -> bits above floor
above_mask_tab:
    addwf   PCL, F
    retlw   0x0E
    retlw   0x0C
    retlw   0x08
    retlw   0x00

; (1 << floor_now) - 1  -> bits below floor
below_mask_tab:
    addwf   PCL, F
    retlw   0x00
    retlw   0x01
    retlw   0x03
    retlw   0x07

; ============================================================
; delay_1ms : approx. 1 ms @ 4 MHz (1 MHz instruction clock)
; ============================================================
delay_1ms:
    movlw   D'332'
    movwf   dly_cnt
DLY_LOOP:
    decfsz  dly_cnt, F
    bra     DLY_LOOP
    return

; ============================
