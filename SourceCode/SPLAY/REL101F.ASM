; Interupt driven 8 Bit Sound player;
;
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
Ports          dw 03bch
               dw 0278h
               dw 0378h
Portaddr       dw 0378h

messages       db 00h       ; display messages flag

pspseg         dw (?)       ; save the old PSP segment address
int8           dd (?)
;
ttitle   db     '               '
         db     'SPLAY '
version  db     'v1.01f '
descript db     '- Parellel Port Sound Player',0dh,0ah
         db     '    Copyright (c) 1991 J. Sokol & J. Monroy',0dh,0ah,0ah
         db     0dh,0ah,0ah,'$'
thelp    db     'SPLAY '
         db     'v1.01e '
         db     '- Parellel Port Sound Player',0dh,0ah
         db     '    Copyright (c) 1991 J. Sokol & J. Monroy',0dh,0ah,0ah
         db     'Synopsis: SPLAY [options] soundfile',0dh,0ah
         db     'Options are:',0dh,0ah,0ah

         db     '      -S(Sample rate parameter)',0dh,0ah
         db     '         default 1 = 22  KHz',0dh,0ah
         db     '                 2 = 11  KHz',0dh,0ah
         db     '                 3 = 7.3 KHz',0dh,0ah
         db     '                 4 = 5.5 KHz',0dh,0ah,0ah

         db     '      -P(LPT port number)',0dh,0ah
         db     '          port number is from 1 to 3  Default (2)',0dh,0ah,0ah

         db     '      -V Verbose (Causes text output)',0dh,0ah
         db     '          NOTE: Errors will always be displayed',0dh,0ah,0ah

         db     ' EXAMPLE: SPLAY -S2 -V C:\SND\COKEISIT.SND',0dh,0ah
         db     '           will play file COKEISIT.SND at 11 KHZ',0dh,0ah,'$'

tload    db     0dh,'LOADING ....           ',0dh,'$'
tplay    db     0dh,'PLAYING ....           ',0dh,'$'
tend     db     0dh,'That''s all folks!     ',0dh,0ah,0ah,0ah,'$'

tfilerr   db '<<< ERROR >>> SOUND FILE NOT FOUND ',0dh,0ah,'$'
tspeederr db '<<< ERROR >>> INVALID SPEED - USE 1 TO 4 <DEFAULT IS 3>',0dh,0ah,'$'
tporterr  db '<<< ERROR >>> INVALID PORT  - USE 1 to 3 <DEFAULT IS 2>',0dh,0ah,'$'


data_seg         ENDS

; SPLAY v1.00b - Parellel Port Sound Player
;Copyright (c) 1991 J. Sokol & J. Monroy   $
;SPLAY v1.00b - Parellel Port Sound Player
;Copyright (c) 1991 J. Sokol & J. Monroy
;
;Synopsis:  SPLAY [options] soundfile  Options are:
;
;-S(Sample rate parameter)
;default 1 = 22  KHz
;        2 = 11  KHz
;        3 = 7.3 KHz
;        4 = 5.5 KHz
;
;-P (LPT port number)          port number is from 1 to 3  Default (2)
;-V Verbose (Causes text output)
;  NOTE: Errors will always be displayed
;
;  EXAMPLE: SPLAY -S2 -V C:\SND\COKEISIT.SND
;            will play file COKEISIT.SND at 11 KHZ   $
;
; LOADING      $
; PLAYING          $
; THATS ALL FOLKS!    $
;
;
;
;


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
         MOV    DX, OFFSET ttitle        ; copyright message
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
         MOV    DX, OFFSET tload              ; "loading" message
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
         MOV    DX, OFFSET tplay               ; load "play" message
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
         mov    DX, word ptr portaddr

         XOR    DI, DI                 ; zero the DI for infinity loop

         MOV    AX, seg free           ; load free segment into ES
         MOV    ES, AX

         MOV    ah, 00h                ;timer load mode bcd
         MOV    AL, 34h                ;   00   11  010   0
         OUT    43h,AL                 ; Set timer 0 to mode 2

         MOV    AX,0036h                  ; 7-16-91   used to be "mov al,36h
         OUT    40h,AL
         MOV    AL, AH
         OUT    40h,AL                 ; set timer 0 to 22Khz

        mov     al, 0b0h                  ; 7-16-91
        out     43h,al                    ;    "
        in      al, 61h                   ;    "
        or      al, 03h                   ;    "
        out     61h,al                    ;    "

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

         MOV    AL, 34h                 ;timer load mode bcd
         OUT    43h ,AL                 ;   00   11  010   0
                                        ; Set timer 0 to mode 2
         MOV    AL, 00h
         OUT    40h, AL
         OUT    40h, AL


         MOV    AL, 0b6h               ;timer load mode bcd
         OUT    43h, AL                ;   10   11  011   0
                                       ; Set timer 2 to mode 3


        mov     ax, 0533h                         ; 7-16-91
        out     42h,al                            ;    "
        mov     al, ah                            ;    "
        out     42h ,al                           ;    "

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

         MOV    DX, OFFSET tend         ; load done message
         MOV    AH, 09h
         INT    21h
Jmp10:
         MOV    AX, 4c00h
         INT    21h                      ; Normal Exit(0)
ferror:                                  
         MOV    DX, OFFSET tfilerr       ; ERROR message
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

         DEC     CL
         JNZ     endint
         MOV     CL,BYTE PTR  speedcount   ;

         MOV     Al, ES:[SI]
         out     dx,al
                              ; 7-15-91
         INC     SI

         OR      CH,CH       ; test if num segments = 0
         JZ      lastseg

         cmp     SI,0ffh
         JNZ     endint      ; test for SI wrap around
         inc     SI

; increment segment when SI wrappes around
         MOV     AX,ES         ; 7-15-91  changed 'es' to 'ds'
         ADD     AX,1000h
         MOV     ES,AX         ; 7-15-91  changed 'es' to 'ds'
         DEC     CH          ; dec number of segments
         JMP     endint

lastseg: CMP     SI,BX
         JNZ     endint

         NOT     DI          ; Kill infinity loop

         mov    AL,34h          ; 7-16-91
         out    43h,al          ;    "
         mov    AL,00h          ;    "
         out    40h,al          ;    "
         out    40h,al          ;    "

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

         CLD                          ; Clear Direction flag
         MOV    SI, 0080h
         MOV    CL, [SI]
         INC    SI
         OR     CL, CL
         JNZ    jgetchar
         Jmp    jhelp
jgetchar:
         MOV    AL, BYTE PTR [SI]
         INC    SI
         CMP    AL, ' '               ; space
         JE     jgetchar
         CMP    AL, 0dh               ; 0Dh = Carrige Return
         JE     jhelp
         CMP    AL, '-'
         JE     jcommand
         CMP    AL, '/'
         JE     jcommand
         DEC    SI

         MOV    DI, offset filename
jfilename:                                ; save data file name
         MOV    AL, BYTE PTR [SI]
         CMP    AL, 0dh              ; check for carrige return
         JE     jendparse                ; if so then done parsing
         MOVSB
         JMP    jfilename
jendparse:
         pop    ds
         RET          ; RETURN TO main program

jcommand:
         MOV    AL, BYTE PTR [SI]
         CMP    AL, 'S'
         JE     jspeed
         CMP    AL, 's'
         JE     jspeed
         CMP    AL, 'V'
         JE     jverbose
         CMP    AL, 'v'
         JE     jverbose
         CMP    AL, 'P'
         JE     jport
         CMP    AL, 'p'
         JE     jport
         JMP    jhelp

jverbose:

         MOV    es:messages,8eh   ;  toggle suppress message flag
         INC    SI
         JMP    jgetchar
jspeed:
         INC    SI
         MOV    AL, BYTE PTR [SI]
         CMP    AL, '0'
         JBE    jspeederr
         CMP    AL, '5'
         JGE    jspeederr
         MOV    AH, '0'
         SUB    AL, AH

         MOV    es:speedcount, AL    ;  save speed parameter
         INC    SI
         JMP    jgetchar
jport:
         mov     di,offset ports
         inc     si
         mov     al, byte ptr [si]
         cmp     al, '0'
         jbe     jporterr
         cmp     al, '4'
         jge     jporterr
         mov     ah, '1'
         sub     al,ah
         xor     ah,ah
         shl     al,1
         add     di,ax
         mov     ax,word ptr es:[di]
         mov     word ptr es:[portaddr],ax
         inc     si
         jmp     jgetchar
jhelp:
         MOV    DX, OFFSET thelp       ; display usage
         JMP    jerror

jporterr:
         MOV    DX, OFFSET tporterr       ; display usage
         JMP    jerror

jspeederr:
         MOV    DX, OFFSET tspeederr             ; invalid speed
jerror:
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


                                                                                                                     
