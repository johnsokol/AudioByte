;*******************************************************************;*
;*
;*     1 Millisecond Timer for Turbo Pascal Ver 5.5
;*     Written By John L. Sokol 2/20/92
;*
;*******************************************************************
;
;
;  Interupt code taken from  SPLAYER  sound playback code from
;
;   Copyright (c) 1988-1992 by Zebra Research, Inc
;        All Rights Reserved.
;
;    File:        REL090B.ASM
;    Program:     SPLAYER.EXE  -  official release version
;    Description: splay for Internal Speaker
;                 stand alone, interupt driven 6 Bit Sound player;
;                 Fully compatable with SPLAY for Audio Byte Parrallel
;                 port audio output software
;
;


        TITLE   MSTIMER

DATA    SEGMENT WORD PUBLIC

        EXTRN   COUNT:word       ;COUNTER inc every 1 Millisecond
        EXTRN   coffset:word
        EXTRN   cseg:word
        EXTRN   nextseg:word
        EXTRN   nextoffset:word
        EXTRN   port:word

                dithcount  dw   0000h

DATA    ENDS

CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE,DS:DATA

        PUBLIC  SETTIMER
        PUBLIC  KILLTIMER

Vec08      label   dword   ; the old tick vector
Vec08O     dw      ?
Vec08S     dw      ?


; SET TIMER
; Procedure settimer;

SETTIMER     PROC FAR

        mov ax,3508h    ; get vector for int 08h
        int 21h
        mov cs:vec08S   ,es ; save old vector
        mov cs:vec08O   ,bx


;***********************************************************
;*
;*                     Setup hardware
;*
;*
;***********************************************************



         IN     AL, 21h
         OR     AL, 03h
         OUT    21h,AL                 ; Stop Interupts

         push   ds

         MOV    DX, offset intr
         mov    bx, seg intr
         mov    ds, bx
         MOV    AX, 2508h
         INT    21h        ;Set int vector 0x08

         pop    ds

; ****** trigger start of int routine

                                       ;timer load mode bcd
         MOV    AL, 34h                ;   00   11  010   0
         OUT    43h,AL                 ; Set timer 0 to mode 2

         MOV    AX, 0095h  ; 8KHz
         OUT    40h,AL
         MOV    AL, AH
         OUT    40h,AL                 ; set timer 0 to 1000 Hz

                                         ;timer load mode bcd
         AND    AL, 0feh
         OUT    21h ,AL



        RETF

settimer          ENDP




; Kill TIMER ***********************************************************
; Procedure killttimer;

KILLTIMER     PROC FAR


;Reset hardware
         CLI                            ; CLear the Interrupt flag
         IN     AL, 21h                 ;
         OR     AL, 01h
         OUT    21h, AL                 ; reset interupt controller
         STI                            ; SeT (or STart) the Interrupt flag

         MOV    AL, 34h
         OUT    43h ,AL

         MOV    AL, 00h                  ; reset speed to 18.2 ms
         OUT    40h, AL
         OUT    40h, AL


         PUSH   DS

         LDS    DX,CS:VEC08
         MOV    AX, 2508h
         INT    21h                     ; Re-Set int vector #8

         POP    DS

         IN     AL, 21h
         AND    AL, 0fch
         OUT    21h, AL                 ; set interupt controller


        RETF

Killtimer          ENDP


;**************************************************************************



tintr    PROC FAR


;*****************************************
;*
;*  Main interupt handler
;*
;*****************************************




intr:
         cli
         push    DS
         push    AX
         push    ES
         push    BX
         PUSH    DX

         mov     AX,seg DATA
         mov     DS,AX

         mov     AX,[ CSEG ]
         mov     ES,AX

         mov     DX,[ port ]
         mov     BX,[ coffset ]
 
         MOV     Al, ES:[BX]
         out     DX,AL  ; PLAY SAMPLE

         INC     BX
         JZ      ENDSEG
endsegret:

         mov     [ coffset ],BX

         pop    DX
         pop    BX
         pop    ES

iend:
         ;********* Generate sample dithering 18.2 ms

         add     [ dithcount ], 0095h
         jc      Doit


         MOV     AL,20h      ; tell 8259A interupt done
         OUT     20h, AL

         pop     AX
         POP     DS
         STI

         IRET
                         

endseg:  mov     AX,[ nextseg ]
;         JZ      killintr
         mov     [ cseg ], AX
         mov     [ nextseg ], 0000h
         mov     BX,[ nextoffset ]

         jmp     endsegret


killintr:
;         call   killtimer
;         jmp    endsegret


       ; pass through to time of day clock
doit:
          pop     AX
          POP     DS
          JMP      cs:[Vec08]

; ***** old int

;intr:
;         push    DS
;         push    AX
;
;         mov     AX,seg DATA
;         mov     DS,AX
;
;         INC     DS:count
;
;                  ;Generate sample dithering 18.2 ms
;         add     Word Ptr dithcount, 0095h
;         jc      Doit
;
;
;         MOV     AL,20h      ; tell 8259A interupt done
;         OUT     20h, AL
;
;         POP     AX
;         POP     DS
;
;         STI
;         IRET
;
;
;doit:
;         POP     AX
;         POP     DS
;
;         JMP      cs:[Vec08]
;


tintr    ENDP


code     ends
         end

