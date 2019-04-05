; 
; Interupt driven 6 Bit Sound player
;
;
                  page 60,132
stack_seg         SEGMENT   PARA  STACK    'STACK'
                  db        100h dup(?)
stack_seg         ENDS

;-----------------
data_seg         SEGMENT   PARA   PUBLIC  'DATA'
filename       dd 20h dup (00h)
filehandle     dw 0000h
numsegs        db 00h       ; number of segment used by recording
lastsegoffset  dw 0000h     ; offset into last segment of recording
speedcount     db 01h       ; specifies numberer of times to replay
                            ; sample to drop sample rate
messages       db 00h       ; display messages flag

pspseg         dw (?)       ; save the old PSP segment address
int8           dd (?)
;
text1    db     '               '
         db     'rePC v1.00b - COPYRIGHT (c) 1991 J. Sokol & J. Monroy'
         db     0dh,0ah,0ah,'$'
text2    db     0dh,0ah
         db     'USAGE: - rePC [-Sy][-@] <DATAFILE>',0dh,0ah
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
         db     'EXAMPLE: rePC -S3 C:\SOUNDS\SPEAK.SND',0dh,0ah,'$'
text3    db     'DATA FILE NOT FOUND',0dh,0ah,'$'
text4    db     0dh,'LOADING DATA FILE....$'
text5    db     0dh,'PLAYING DATA FILE....$'
text6    db     0dh,'END - rePC           ',0dh,0ah,0ah,0ah,'$'
text7    db     'INVALID SPEED - USE 1 TO 4 <DEFAULT IS 3>',0dh,0ah,'$'


data_seg         ENDS

;*****************************************
;*                                       *
;*      M      A       I       N         *
;*                                       *
;*****************************************


code   segment  para public 'CODE'
       assume   ds:data_seg, ss:stack_seg, cs:code
my_proc  PROC

         mov     bx,ds

         push    ds
         xor     ax,ax
         push    ax

         mov     ax,seg data_seg
         mov     ds,ax
         mov    pspseg,bx

         CALL   commandline             ;Check Command line Params first

         CMP    messages, 00h  ; check for message supression
         JNZ    openf
         MOV    DX, OFFSET text1        ; copyright message
         MOV    AH, 09h
         INT    21h
openf:

; Load Sound data

         MOV    DX, offset filename
         MOV    AX, 3d00h
         INT    21h                    ;Open file
         JNC    loadit
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


 ; move segment address to storage space
         mov    bx, ds
         mov    es, bx
         MOV    BX, WORD PTR  filehandle ; handle
         MOV    AX, seg free            ; first free segment
         MOV    DS, AX                  ; buffer segment

         MOV    DX, 0000h               ; buffer offset
         MOV    CX, 0ffffh              ; number of bytes
Jmp6:
         MOV    AX, 3f00h
         INT    21h         ;Read file   -- returns bytes transfered in AX
                            ;               if successful
         JNC    jmp4                    ; if Carry Flag set (CF = 1)
         JMP    ferror
Jmp4:                 
         CMP    CX, AX                  ; check for partial read
         JNZ    Jmp5

         MOV    AX, DS
         ADD    AX, 1000h               ; increment segment index
         MOV    DS, AX

         INC    BYTE PTR  es:numsegs     ; increment segment counter
         JMP    Jmp6
Jmp5:
         OR     AX, AX                  ; check if it is zero
         JNZ    Jmp7

         DEC    BYTE PTR numsegs
Jmp7:
         mov    bx, es
         mov    ds, bx

         MOV    WORD PTR lastsegoffset, AX    ; save parital segment size
         MOV    BX, WORD PTR filehandle    ; load handle
         MOV    AH, 3eh
         INT    21h        ;Close file

; display playing prompt
         CMP    BYTE PTR messages, 00h   ; check for message suppression
         JNZ    skip2
         MOV    DX, OFFSET text5               ; load "play" message
         MOV    AH, 09h
         INT    21h
skip2:

         MOV    AX, 3508h
         INT    21h        ;Get int vector 0x08

         MOV    WORD PTR int8, BX
         MOV    WORD PTR int8+2, ES

;Setup hardware
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

;        jmp    reset

         MOV    SI, 0000h
         MOV    BX, WORD PTR lastsegoffset
         MOV    CH, BYTE PTR numsegs
         MOV    CL, BYTE PTR speedcount

         XOR    DI, DI                 ; zero the DI for infinity loop

         MOV    AX, seg free           ; load free segment into ES
         MOV    ES, AX
                                       ;timer load mode bcd
         MOV    AL, 34h                ;   00   11  010   0
         OUT    43h,AL                 ; Set timer 0 to mode 2

         MOV    AX, 0036h
         OUT    40h,AL
         MOV    AL, AH
         OUT    40h,AL                 ; set timer 0 to 22Khz

                                       ;timer load mode bcd
         MOV    AL, 0B0h                ;   10   11  000   0
         OUT    43h,AL                 ;set timer 2 to mode 0

         IN     AL, 61h
         OR     AL, 03h
         OUT    61h, AL                ;set speaker to output timer 2

         IN     AL, 21h                ; set interupt controller
         AND    AL, 0feh
         OUT    21h ,AL


; infinity loop to run during playback

Iloop:   OR     DI, DI
         JZ     Iloop                   ;loop while di = 0

;Reset hardware

reset:
         CLI                            ; CLear the Interrupt flag
         IN     AL, 21h                 ;
         OR     AL, 01h
         OUT    21h, AL                 ; reset interupt controller
         STI                            ; SeT (or STart) the Interrupt flag
         IN     AL, 61h                 ;
         AND    AL, 0fch
         OUT    61h, AL                 ; reset speaker output

         MOV    AL, 34h
         OUT    43h ,AL
         MOV    AL, 00h
         OUT    40h, AL
         OUT    40h, AL
         MOV    AL, 0b6h
         OUT    43h, AL

         MOV    AX, 0533h
         OUT    42h, AL
         MOV    AL, AH
         OUT    42h, AL                 ; set timer 2 to 896 Hz
         PUSH   DS

         LDS    DX,int8
         MOV    AX, 2508h
         INT    21h                     ; Re-Set int vector #8

         POP    DS
         IN     AL, 21h
         AND    AL, 0fch
         OUT    21h, AL                 ; set interupt controller

; Display exit prompt
         CMP    BYTE PTR messages, 00h   ; check for message suppresion
         JNZ    Jmp10

         MOV    DX, OFFSET text6         ; load done message
         MOV    AH, 09h
         INT    21h
Jmp10:
         MOV    AX, 4c00h
         INT    21h                      ; Normal Exit(0)
ferror:                                  
         MOV    DX, OFFSET text3         ; ERROR message
         MOV    AH, 09h
         INT    21h
         MOV    AX, 4c01h
         INT    21h                      ;File error Exit(1)



;*****************************************
;*                                       *
;*  Main interupt handler                *
;*                                       *
;*                                       *
;*****************************************

intr:    CLI


         MOV     AL,AH
         OUT     42h, AL
         XOR     AL,AL    ;store new count in timer (2)
         OUT     42h, AL

         DEC     CL
         JNZ     endint
         MOV     CL,BYTE PTR  speedcount

         MOV     AH, ES:[SI]

         SHR     AH,1
         SHR     AH,1
         INC     AH

         INC     SI

         OR      CH,CH       ; test if num segments = 0
         JZ      lastseg

         cmp     SI,0ffffh
         JNZ     endint      ; test for SI wrap around
         inc     SI

; increment segment when SI wrappes around
         PUSH    AX
         MOV     AX,ES
         ADD     AX,1000h
         MOV     ES,AX
         POP     AX
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
         mov    bx,ds
         mov    es,bx
         push   ds
         mov    ax,pspseg
         mov    ds,ax

         CLD                          ; CLear Direction flag
         MOV    SI, 0080h
         MOV    CL, [SI]
         INC    SI
         OR     CL, CL
         JZ     Jmp11
Jmp12:
         MOV    AL, BYTE PTR [SI]
         INC    SI
         CMP    AL, ' '               ; space
         JE     Jmp12
         CMP    AL, 0dh               ; 0Dh = Carrige Return
         JE     Jmp11
         CMP    AL, '-'
         JE     Jmp13
         CMP    AL, '/'
         JE     Jmp13
         DEC    SI

         MOV    DI, offset filename
Jmp15:                                ; save data file name
         MOV    AL, BYTE PTR [SI]
         CMP    AL, 0dh              ; check for charage return
         JE     Jmp14                ; if so then done parsing
         MOVSB
         JMP    Jmp15
Jmp14:
         pop    ds
         RET          ; RETURN TO main program

Jmp13:
         MOV    AL, BYTE PTR [SI]
         CMP    AL, 'S'
         JE     Jmp16
         CMP    AL, 's'
         JE     Jmp16
         CMP    AL, '@'
         JE     Jmp17
         JMP    Jmp11

Jmp17:

         NOT    es:messages   ;  toggle suppress message flag
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

         MOV    es:speedcount, AH    ;  save speed parameter
         INC    SI
         JMP    Jmp12
Jmp11:
         MOV    DX, OFFSET text2        ; display usage
         JMP    Jmp18
Jmp19:
         MOV    DX, OFFSET text7             ; invalid speed
Jmp18:
         pop    ds
         MOV    AH, 09h                 ; print error message
         INT    21h
         MOV    AX, 4c01h
         INT    21h                  ;Command line error Exit(1)

my_proc  ENDP
code     ends
;-----------------
frs      segment  page
free     dw    ?
frs      ends

          end my_proc


