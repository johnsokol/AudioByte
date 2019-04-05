;
;   Copyright (c) 1988-1990 by Zebra Research, Inc
;        All Rights Reserved.
;
;    File:        REL120.ASM
;    Program:     SPLAY.EXE  -  official release version
;    Description: splay for Audio Byte sound adapter
;                 stand alone, interupt driven 8 Bit Sound player;
;
; R here standands for released
; B here is Beta release
;
;
;    Revision 1.20 : 11-17-91 John L. Sokol
;                    Now using Bios Data segment for address
;                    of printer ports
;
; R  Revision 1.12 : 08-04-91 John L. Sokol
;                    Fixed bug that caused internal speaker to
;                    stay on after system bell is sounded.
;
; R  Revision 1.11 : 07-29-91 John L. Sokol
;                    Cleaned up help screen - based on complaints
;                    from several coustomers
;
;    Revision 1.10 : 07-22-91 Jessy Monroy
;                    Optomised Memory Management in interupt loop.
;
;    Revision 1.04 : 07-20-91 John L. Sokol & Jessy Monroy
;                    Improved user interface allow autoport detection
;                    override. Added a silent mode that is Default
;
;    Revision 1.03 : 07-18-91 John L. Sokol
;                    Fixed bug that dissabled all printers on system
;                    side effect of port detection
;
; B  Revision 1.02 : 07-15-91 John L. Sokol
;                    Added Automatic Port Detection
;
; R  Revision 1.01 : 05-06-91 John L. Sokol
;                    did major changed to interupt loop
;                    this allows for variable sample rates referenced
;                    from a look up table
;
;    Revision 1.00 : 05-05-91 John L. Sokol
;                    Fixed bug that caused system lockup on Slow
;                    computers
;
; B  Revision 0.90 : 04-28-91 John L. Sokol  &  Jessy Monroy
;                    full assembly only 4 sample rated
;
;    PLAY287       : 01-27-90 John L. Sokol
;                    last version of prototype driver in Pascal
;                    used inline assembly to do interupts
;
;
;
;


bios_seg        EQU  0040h
printer_base    EQU  0008h
portdelay       EQU  0020h


data_seg         SEGMENT   PARA   PUBLIC  'DATA'

ttitle   db     0dh,0ah
         db     'SPLAY '
version  db     'v1.20 '
descript db     '- Parellel Port Sound Player',0dh,0ah
         db     '    Copyright (c) 1991 J. Sokol & J. Monroy'
         db     0dh,0ah,0ah,'$'
thelp    db     'SPLAY '
         db     'v1.20 '
         db     '- Parellel Port Sound Player',0dh,0ah
         db     '    Copyright (c) 1991 J. Sokol & J. Monroy',0dh,0ah,0ah
         db     'Synopsis: SPLAY [options] soundfile',0dh,0ah
         db     'Options are:',0dh,0ah,0ah

         db     '      -S (Sample rate parameter) from 0 to 9',0dh,0ah
         db     '                  0 = 44000 Hz  |  5 = 8000 Hz',0dh,0ah
         db     '          Default 1 = 22000 Hz  |  6 = 7000 Hz',0dh,0ah
         db     '                  2 = 16000 Hz  |  7 = 6500 Hz',0dh,0ah
         db     '                  3 = 13500 Hz  |  8 = 5500 Hz',0dh,0ah
         db     '                  4 = 11000 Hz  |  9 = 5000 Hz',0dh,0ah,0ah

         db     '      -P (LPT port number)',0dh,0ah
         db     '          port number is from 1 to 4',0dh,0ah
         db     '          NOTE: On Audio byte adapters after 7/91 this will be AutoDetected',0Dh,0Ah,0Ah

         db     '      -V Verbose (Causes text output)',0dh,0ah
         db     '          NOTE: Errors will always be displayed',0dh,0ah,0ah

         db     ' EXAMPLE: SPLAY -S4 -V C:\SND\COKEISIT.SND',0dh,0ah
         db     '           will play file COKEISIT.SND at 11 KHZ',0dh,0ah,'$'

pdet     db     0dh,'Splay using Port '
portnum  db     '2' , 0dh,0ah,'$'

tload    db     0dh,'LOADING ....           ',0dh,'$'
tplay    db     0dh,'PLAYING ....           ',0dh,'$'
tend     db     0dh,'That''s all folks!     ',0dh,0ah,0ah,0ah,'$'

tfilerr   db '<<< ERROR >>> SOUND FILE NOT FOUND ',0dh,0ah,'$'
tspeederr db '<<< ERROR >>> INVALID SPEED - USE 0 TO 9 <DEFAULT IS 1>',0dh,0ah,'$'
tporterr  db '<<< ERROR >>> INVALID PORT  - USE 1 to 4 <DEFAULT IS 1>',0dh,0ah,'$'
tmisport  db '<<< ERROR >>> INVALID PORT SELECTED - USE VALID LPT PORT NUMBER',0dh,0ah,'$'

filename       dd 20h dup (00h)
filehandle     dw 0000h
numsegs        db 00h       ; number of segment used by recording
lastsegoffset  dw 0000h     ; offset into last segment of recording

speed          dw 0100h     ;22 Khz Default
speeds         dw 0200h     ;44 Khz
               dw 0100h     ;22 Khz
               dw 00BAh     ;16 Khz
               dw 009Dh     ;13.5 Khz
               dw 0080h     ;11 Khz
               dw 005Dh     ;8 Khz
               dw 0051h     ;7 Khz
               dw 004Bh     ;6.5 Khz
               dw 0040h     ;5.5 Khz
               dw 003Ah     ;5 Khz

portret        db 00h

;Ports          dw 03bch
;               dw 0278h
;               dw 0378h

Portaddr       dw 0278h

messages       db 00h       ; display messages flag

pspseg         dw (?)       ; save the old PSP segment address
int8           dd (?)

data_seg         ENDS

;-----------------

stack_seg         SEGMENT   PARA  STACK    'STACK'
                  db        100h dup(?)
stack_seg         ENDS

;*****************************************
;*                                       *
;*      M      A       I       N         *
;*                                       *
;*****************************************


code   segment  para public 'CODE'
       assume   ds:data_seg, ss:stack_seg, cs:code
my_proc  PROC

         mov     bx,ds                  ; save PSP address

         push    ds
         xor     ax,ax
         push    ax

         mov     ax,seg data_seg
         mov     ds,ax                 ; associate data segment for use

         mov     pspseg,bx

         CALL   commandline             ;Check Command line Params first

         CMP    messages, 00h           ; check for message supression
         JNZ    openf
         MOV    DX, OFFSET ttitle       ; copyright message
         MOV    AH, 09h
         INT    21h

         MOV    DX, OFFSET pdet
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
         MOV    CX, 08000h              ; number of bytes
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
         ADD    AX, 800h                ; increment segment index
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


; ******************** fix for loading  32K chunks to look like 64 K chunks


         mov    AX, word ptr lastsegoffset
         MOV    CH, BYTE PTR numsegs
         SHR    CH,1
         jnc    fseg1
         add    AX,08000h   ; pass remaining 1/2 seg to offset
         jnc    fseg1
         inc    CH


;******************** fix so theres no need to check offset in interupt
fseg1:
         add    AX,15
         jnc    fseg2
         inc    CH          ; if close to end of seg then push it over
fseg2:
         mov    CL,4
         SHR    AX,cl       ;  div AX by 4  to get number of blocks
         mov    DX,AX       ; make copy of ax

;        By moving the start seg down and the offset up
;        it will start at the same address but
;        will end at around 15 bytes to the end of the last segment

         MOV    BX, seg free           ; load free segment into ES

         ADD    BX,AX                  ; slide starting seg down
         SUB    BX,1000h
         MOV    ES,BX

         SHL    DX,cl       ; Multi by 16
         mov    ax,0ffffh
         sub    ax,dx

         MOV    SI,AX       ; offset start offset up

         INC    CH          ; add 1 more seg since we don't use offset anymore

         MOV    DX, Word Ptr Speed
         MOV    DI, 0000h
         MOV    BX, 0000h


; ****** trigger start of int routine

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

Iloop:   OR      DI,DI
         JZ      Iloop

;Reset hardware
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
         MOV    AL,AH
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

         MOV    DX, OFFSET tend               ; load done message
         MOV    AH, 09h
         INT    21h
Jmp10:
         MOV    AX, 4c00h
         INT    21h        ;Normal Exit(0)
ferror:                                  ; ERROR message
         MOV    DX, OFFSET tfilerr
         MOV    AH, 09h
         INT    21h
         MOV    AX, 4c01h
         INT    21h        ;File error Exit(1)


;

;*****************************************
;*
;*  Main interupt handler
;*         High     Low
;*  AX     out Data and  dither intermediate
;*  BX     Dither counter that overflows to AL
;*  CX     CH segment counter
;*  DX     Not used
;*  SI     Offset pointer
;*  DI     Speed incrament
;*
;*****************************************
;  Note:  To resolve last segment
;         Add segment by less than 1000 and start si off at a later
;         address then 0 ( muxt add si by value ) this can be
;         precomputed.
;
;
;


intr:    CLI

         MOV     AL,ES:[SI]
         SHR     AL,1
         SHR     AL,1
         INC     AL
                    ;store new count in timer (2)
         OUT     42h, AL
         XOR     AX,AX
         OUT     42h, AL

         add     BX,DX  ; Generate sample dithering
                        ; really want to add BH to SI
         Xchg    AL,BH  ; clears BH , AH now is carry to add to si
         add     SI,AX
    
         JC     endseg      ; test for end of segment

endint:  MOV     AL,20h      ; tell 8259A interupt done
         OUT     20h, AL
         STI
         IRET
                         
endseg:

; increment segment when SI wrappes around

         DEC     CH            ; dec number of segments
         JZ      lastseg
 
         MOV     AX,ES         ; 7-15-91  changed 'es' to 'ds'
         ADD     AX,1000h
         MOV     ES,AX         ; 7-15-91  changed 'es' to 'ds'
         JMP     endint
          
lastseg:
         not    di

         mov    AL,34h          ; 7-16-91  slow down timer
         out    43h,al          ;    "
         mov    AL,00h          ;    "
         out    40h,al          ;    "
         out    40h,al          ;    "
         jmp    endint


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
         mov    ax,pspseg               ; DS points to PSP
         mov    ds,ax                   ; ES points to Data area

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
         CMP    AL, ' '                 ; space -- filter 'em out
         JE     jgetchar
         CMP    AL, 0dh                 ; 0Dh = Carrige Return
         JE     jmphelp                 ; go to dummy jump spot
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
; ----------------------------------------------

jcommand:                               ; parse to correct routine
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
jmphelp: JMP    jhelp

jverbose:

         MOV    es:messages,00h     ;  toggle suppress message flag
         INC    SI
         JMP    jgetchar
jspeed:
         INC    SI
         MOV    AL, BYTE PTR [SI]
         CMP    AL, '0'-1               ; compare with ('0' - 1)
         JBE    jspeederr
         CMP    AL, '9'+1               ; compare with ('9' + 1)
         JGE    jspeederr
         MOV    AH, '0'
         SUB    AL, AH

         xor     ah,ah
         shl     al,1

         mov     di,offset speeds
         add     di,ax

         mov     ax,word ptr es:[di]
         mov     word ptr es:[speed],ax ;  save speed parameter

      ;MOV    es:speedcount, AL         ;  save speed parameter
         
         INC    SI
         JMP    jgetchar
jport:             ; entering this routines means
                   ; that the user requested port overide

;         mov     di,offset ports   

         mov     di,printer_base  ; in bios data segment

         inc     si                    
         mov     al, byte ptr [si]
         cmp     al, '0'
         jbe     jporterr
         cmp     al, '5'
         jge     jporterr
         mov     ah, '1'                ; convert ascii to int in AL
         sub     al,ah
         xor     ah,ah
         shl     al,1                   ; di = di +  ( AL * 2 )
         add     di,ax

         shr     al,01h                  ;output port address in ASCII
         add     al,'1'
         mov     es:byte ptr portnum,al


         push    ES
         mov     ax,bios_seg
         mov     es,ax                   ; ES points to bios data segment
         mov     ax,word ptr es:[di]    ; load in data
         pop     ES

         cmp     AX,0000h
         je      jporterr2

         mov     word ptr es:[portaddr],ax  ; save it out


         inc     si
         jmp     jgetchar
jhelp:

         MOV    DX, OFFSET thelp          ; display usage
         JMP    jerror

jporterr:
         MOV    DX, OFFSET tporterr       ; invalid port error
         JMP    jerror

jporterr2:
         MOV    DX, OFFSET tmisport       ; invalid port error
         JMP    jerror

jspeederr:
         MOV    DX, OFFSET tspeederr      ; invalid speed error
jerror:
         pop    ds              ; restore data segment
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






;;*****************************************
;;*                                       *
;;*  Main interupt handler                *
;;*                                       *
;;*                                       *
;;*****************************************
;
;intr:    CLI
;
;                                       ;store new count in timer (2)
;         MOV     AL,AH
;         OUT     42h, AL
;         XOR     AL,AL
;         OUT     42h, AL
;
;         DEC     CL
;         JNZ     endint
;         MOV     CL,BYTE PTR cs:speedcount
;                  
;         MOV     AH, ES:[SI]
;         SHR     AH,1
;         SHR     AH,1
;         INC     AH
;
;
;         INC     SI
;
;         OR      CH,CH       ; test if num segments = 0
;         JZ      lastseg
;
;        ; OR      SI,SI
;         cmp      SI, 0ffffh
;         JNZ     endint      ; test for SI wrap around
;         inc     si
;
;; increment segment when SI wrappes around
;         PUSH    AX
;         MOV     AX,ES
;         ADD     AX,1000h
;         MOV     ES,AX
;         POP     AX
;         DEC     CH          ; dec number of segments
;         JMP     endint
;
;lastseg: CMP     SI,BX
;         JNZ     endint
;
;         NOT     DI          ; Kill infinity loop
;
;endint:  MOV     AL,20h      ; tell 8259A interupt done
;         OUT     20h, AL
;         STI
;         IRET




;***********************************************************
;*
;*                     Setup hardware
;*
;*
;***********************************************************

;         IN     AL, 21h
;         OR     AL, 03h
;         OUT    21h,AL                 ; Stop Interupts
;
;         push   ds
;
;         MOV    DX, offset intr
;         mov    bx, seg intr
;         mov    ds, bx
;         MOV    AX, 2508h
;         INT    21h        ;Set int vector 0x08
;
;         pop    ds
;
;;        jmp    reset
;
;         MOV    SI, 0000h
;         MOV    BX, WORD PTR lastsegoffset
;         MOV    CH, BYTE PTR numsegs
;         mov    DX, word ptr portaddr
;
;         XOR    DI, DI                 ; zero the DI for infinity loop
;
;         MOV    AX, seg free           ; load free segment into ES
;         MOV    ES, AX
;
;         MOV    ah, 00h                ;timer load mode bcd
;         MOV    AL, 34h                ;   00   11  010   0
;         OUT    43h,AL                 ; Set timer 0 to mode 2
;
;;        MOV    AX,0036h                  ; 7-16-91   used to be "mov al,36h
;
;         MOV    AX, word PTR speed        ; 7-19-91 load speed from table
;
;         OUT    40h,AL
;         MOV    AL, AH
;         OUT    40h,AL                 ; set timer 0 to table value
;
;;        mov     al, 0b0h              ;   10   11 000 0
;;        out     43h,al
;
;;        in      al, 61h
;;        or      al, 03h
;;        out     61h,al
;
;         IN     AL, 21h                ; set interupt controller
;         AND    AL, 0feh
;         OUT    21h ,AL
;
;
;; infinity loop to run during playback
;
;
;Iloop:   OR     DI, DI
;         JZ     Iloop                   ;loop while di = 0
;
;
;;Reset hardware
;
;reset:
;         CLI                            ; CLear the Interrupt flag
;         IN     AL, 21h                 ;
;         OR     AL, 01h
;         OUT    21h, AL                 ; reset interupt controller
;         STI                            ; SeT (or STart) the Interrupt flag
;
;         MOV    AL, 34h                 ;timer load mode bcd
;         OUT    43h ,AL                 ;   00   11  010   0
;                                        ; Set timer 0 to mode 2
;         MOV    AL, 00h
;         OUT    40h, AL
;         OUT    40h, AL
;
;
;;         MOV    AL, 0b6h               ;timer load mode bcd
;;         OUT    43h, AL                ;   10   11  011   0
;                                       ; Set timer 2 to mode 3
;
;
;;        mov     ax, 0533h                         ; 7-16-91
;;        out     42h,al                            ;    "
;;        mov     al, ah                            ;    "
;;        out     42h ,al                           ;    "
;
;         PUSH   DS
;
;         LDS    DX,int8
;         MOV    AX, 2508h
;         INT    21h                     ; Re-Set int vector #8
;
;         POP    DS
;
;         IN     AL, 21h
;         AND    AL, 0fch
;         OUT    21h, AL                 ; set interupt controller
;
;; Display exit prompt
;         CMP    BYTE PTR messages, 00h   ; check for message suppresion
;         JNZ    Jmp10
;
;
;         MOV    DX, OFFSET tend         ; load done message
;         MOV    AH, 09h
;         INT    21h
;Jmp10:
;         MOV    AX, 4c00h
;         INT    21h                      ; Normal Exit(0)
;ferror:
;         MOV    DX, OFFSET tfilerr       ; ERROR message
;         MOV    AH, 09h
;         INT    21h
;         MOV    AX, 4c01h
;         INT    21h                      ;File error Exit(1)

