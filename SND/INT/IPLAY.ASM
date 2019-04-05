; Interupt driven 6 Bit Sound player
;
;

masm

stack_seg         SEGMENT   PARA  STACK    'STACK'
                  db        64 dup(?)
stack_seg         ENDS


code   segment para public 'CODE'
       assume es:nothing, ds:code, ss:stack_seg, cs:code

               db 80h dup (00h)
numsegs:       db 00h       ; number of segment used by recording
speedcount:    db 01h       ; specifies numberer of rimes to replay
                            ; sample to drop sample rate
messages:      db 00h       ; display messages flag

lastsegoffset: dw 0000h     ; offset into last segment of recording
filehandle:    dw 0000h
int8           dd (?)


my_proc  PROC
Main:

         CALL   commandline             ;Check Command line Params first

         PUSH   CS
         POP    DS

         CMP    BYTE PTR messages, 00h  ; check for message supression
         JNZ    openf
         MOV    AH, 07h
         MOV    AL, 00h
         MOV    BH, 07h
         MOV    CH, 00h
         MOV    CL, 00h
         MOV    DH, 18h
         MOV    DL, 4fh
         INT    10h                    ;Scroll window down
         MOV    AH, 02h
         MOV    BH, 00h
         MOV    DH, 00h
         MOV    DL, 00h
         INT    10h                    ;Set cursor pos
         MOV    DX, OFFSET text1
         MOV    AH, 09h
         INT    21h
openf:

; Load Sound data

         MOV    DX, 0000h
         MOV    AX, 3d00h
         INT    21h                    ;Open file
         JNB    loadit
         JMP    ferror
loadit:
         MOV    WORD PTR filehandle, AX   ; save HANDLE

; dispay Loading prompt
         CMP    BYTE PTR messages, 00h  ; check for message supression
         JNZ    skip1
         MOV    DX, OFFSET text4              ; "loading" message
         MOV    AH, 09h
         INT    21h
skip1:

         PUSH   DS

    ; move ds to storage space
         MOV    AX, seg free            ; first free segment
         MOV    DS, AX                  ; buffer segment

         MOV    BX, WORD PTR cs:filehandle ; handle

         MOV    CX, 0ffffh               ; number of bytes
         MOV    DX, 0000h               ; buffer offset
         SUB    CX, DX                  ; CX = CX - DX
         MOV    AH, 3fh
         INT    21h        ;Read file   -- returns bytes transfered in AX
                           ;               if successful

         JNB    Jmp4                    ; if Carry Flag clear (CF = 0)
         JMP    ferror
Jmp6:
         MOV    DX, 0000h
         MOV    CX, 0ffffh
         MOV    AH, 3fh
         INT    21h        ;Read file
         JNB    Jmp4
         JMP    ferror
Jmp4:
         CMP    CX, AX                  ; check for partial read
         JNZ    Jmp5

         MOV    AX, DS
         ADD    AX, 1000h               ; increment segment index
         MOV    DS, AX

         INC    BYTE PTR cs:numsegs     ; increment segment counter
         JMP    Jmp6
Jmp5:
         OR     AX, AX                  ; check if it is zero
         JNZ    Jmp7

         DEC    BYTE PTR cs:numsegs
Jmp7:

    ; restore ds to cs ***************************************************
         POP    DS

         MOV    WORD PTR lastsegoffset, AX    ; save parital segment size
         MOV    BX, WORD PTR filehandle    ; load handle
         MOV    AH, 3eh
         INT    21h        ;Close file

; display playing prompt
         CMP    BYTE PTR messages, 00h   ; check for message suppression
         JNZ    skip2
         MOV    AH, 02h
         MOV    BH, 00h
         MOV    DH, 02h
         MOV    DL, 00h
         INT    10h        ;Set cursor pos
         MOV    DX, OFFSET text5               ; load play message
         MOV    AH, 09h
         INT    21h        ;""
skip2:

         MOV    AX, 3508h
         INT    21h        ;Get int vector 0x08

         MOV    WORD PTR int8, BX
         MOV    WORD PTR int8+2, ES

;Setup hardware
         IN     AL, 21h
         OR     AL, 03h
         OUT    21h,AL                 ; Stop Interupts

         MOV    DX, offset intr
         MOV    AX, 2508h
         INT    21h        ;Set int vector 0x08

         MOV    SI, 0000h
         MOV    BX, WORD PTR lastsegoffset
         MOV    CH, BYTE PTR numsegs
         MOV    CL, BYTE PTR speedcount
         MOV    DX, 0278h

         XOR    DI, DI                 ; zero the DI for infinity loop

         MOV    AX, seg free           ; load free segment into ES
         MOV    ES, AX

         MOV    AH, 00h
         MOV    AL, 34h                ; 00110100
         OUT    43h,AL                 ; Set timer 0 to mode 2

         MOV    AL, 36h
         OUT    40h,AL
         MOV    AL, AH
         OUT    40h,AL                 ; set timer 0 to 22Khz


         IN     AL, 21h                ; set interupt controller
         AND    AL, 0feh
         OUT    21h ,AL


; infinity loop to run during playback

Iloop:   OR     DI, DI
         JZ     Iloop                   ;loop while di = 0

;Reset hardware
         CLI                            ; CLear the Interrupt flag
         IN     AL, 21h                 ;
         OR     AL, 01h
         OUT    21h, AL                 ; reset interupt controller
         STI                            ; SeT (or STart) the Interrupt flag

         MOV    AL, 34h
         OUT    43h ,AL

         MOV    AL, 00h
         OUT    40h, AL
         OUT    40h, AL
         MOV    AL, 0b6h
         OUT    43h, AL

         PUSH   DS

         LDS    DX,int8
         MOV    AX, 2508h
         INT    21h        ;Set int vector #8
         POP    DS
         IN     AL, 21h
         AND    AL, 0fch
         OUT    21h, AL                 ; set interupt controller

; Display exit prompt
         CMP    BYTE PTR messages, 00h   ; check for message suppresion
         JNZ    Jmp10
         MOV    AH, 02h
         MOV    BH, 00h
         MOV    DH, 02h
         MOV    DL, 00h
         INT    10h                     ;Set cursor pos

         MOV    DX, OFFSET text6               ; load done message
         MOV    AH, 09h
         INT    21h
Jmp10:
         MOV    AX, 4c00h
         INT    21h        ;Normal Exit(0)
ferror:                                  ; ERROR message
         MOV    DX, OFFSET text3
         MOV    AH, 09h
         INT    21h
         MOV    AX, 4c01h
         INT    21h        ;File error Exit(1)


;*****************************************
;*                                       *
;*  Main interupt handler                *
;*                                       *
;*                                       *
;*****************************************

intr:    CLI

         DEC     CL
         JNZ     endint
         MOV     CL,BYTE PTR cs:speedcount

         MOV     Al, ES:[SI]
         out     DX,AL


         INC     SI

         OR      CH,CH       ; test if num segments = 0
         JZ      lastseg

         cmp     SI, 0ffffh
         JNZ     endint      ; test for SI wrap around
         inc     SI

; increment segment when SI wrappes around
         MOV     AX,ES
         ADD     AX,1000h
         MOV     ES,AX
         DEC     CH          ; dec number of segments
         JMP     endint

lastseg: CMP     SI,BX
         JNZ     endint

         NOT     DI          ; Kill infinity loop

endint:  MOV     AL,20h      ; tell 8259A interupt done
         OUT     20h, AL
         STI
         IRET


;*****************************************
;*                                       *
;*  Check C o m m a n d   L i n e        *
;*    drop out on error                  *
;*                                       *
;*****************************************

commandline:
         CLD                          ; CLear Direction flag
         MOV    SI, 0080h
         MOV    CL, BYTE PTR [SI]
         INC    SI
         OR     CL, CL
         JZ     Jmp11
Jmp12:
         MOV    AL, BYTE PTR [SI]
         INC    SI
         CMP    AL, ' '               ;space
         JZ     Jmp12
         CMP    AL, 0dh               ; 0Dh = Carrige Return
         JZ     Jmp11
         CMP    AL, '-'
         JZ     Jmp13
         CMP    AL, '/'
         JZ     Jmp13
         DEC    SI
         PUSH   CS
         POP    ES
         MOV    DI, 0000h
Jmp15:                                ; save data file name
         MOV    AL, BYTE PTR [SI]
         CMP    AL, 0dh              ; check for charage return
         JZ     Jmp14                ; if so then done parsing
         MOVSB
         JMP    Jmp15
Jmp14:   RET          ; RETURN TO main program

Jmp13:
         MOV    AL, BYTE PTR [SI]
         CMP    AL, 'S'
         JZ     Jmp16
         CMP    AL, 's'
         JZ     Jmp16
         CMP    AL, '@'
         JZ     Jmp17
         JMP    Jmp11

Jmp17:

         NOT    BYTE PTR cs:messages   ;  toggle suppress message flag
         INC    SI
         JMP    Jmp12
Jmp16:
         INC    SI
         MOV    AL, BYTE PTR [SI]
         CMP    AL, '0'
         JBE    Jmp19
         CMP    AL, '5'
         JGE    Jmp19
         MOV    AH, '5'
         SUB    AH, AL

         MOV    BYTE PTR cs:speedcount, AH    ;  save speed parameter
         INC    SI
         JMP    Jmp12
Jmp11:
         MOV    DX, OFFSET text2        ; display usage
         JMP    Jmp18
Jmp19:
         MOV    DX, OFFSET text7             ; invalid speed
Jmp18:
         PUSH   CS
         POP    DS
         MOV    AH, 09h                 ; print error message
         INT    21h
         MOV    AX, 4c01h
         INT    21h                  ;Command line error Exit(1)

my_proc  ENDP



text1:   db     '               '
         db     '8 Bit Sound player'
         db     0dh,0ah,0ah,'$'
text2:   db     0dh,0ah
         db     'USAGE: - IPLAY [-Sy][-@] <DATAFILE>',0dh,0ah
         db     '       - WHERE y IS PLAYBACK RATE FROM 1 - 4 <DEFAULT IS 3>'
         db     0dh,0ah
         db     '               1 - 5500  SAMPLES PER SECOND',0dh,0ah
         db     '               2 - 7333  SAMPLES PER SECOND',0dh,0ah
         db     '               3 - 11000 SAMPLES PER SECOND',0dh,0ah
         db     '               4 - 22000 SAMPLES PER SECOND',0dh,0ah
         db     '       - AND @ CAUSES TEXT OUTPUT TO BE SUPPRESSED',0dh,0ah
         db     '               NOTE: ERRORS WILL STILL BE DISPLAYED',0dh,0ah
         db     '       - AND <DATAFILE> IS THE PATH, FILENAME, AND EXTENSION'
         db     0dh,0ah
         db     '         OF FILE TO BE PLAYED BACK',0dh,0ah,0ah
         db     'EXAMPLE: IPLAY -S3 C:\SOUNDS\SPEAK.SND',0dh,0ah,'$'
text3:   db     'DATA FILE NOT FOUND',0dh,0ah,'$'
text4:   db     'LOADING DATA FILE....$'
text5:   db     'PLAYING DATA FILE....$'
text6:   db     'END     ',0dh,0ah,'$'
text7:   db     'INVALID SPEED - USE 1 TO 4 <DEFAULT IS 3>',0dh,0ah,'$'

code     ends

frs      segment  page
free     dw    ?
frs      ends


        end Main


