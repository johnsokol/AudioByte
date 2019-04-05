Itnr:
        cli
        mov     al, es:[si]
        out     dx, al
        inc     si

        cmp     si, bx  ; <----------------- check clock cycles
        jz      endseg

endint:
        mov     al, 20h
        out     20h, al
        sti
        iret
;----------------------------------------------
endseg:
        or      ch,ch   ; <---------------- check segmentation
        jz      fixups  ; <----------------

        mov     ax, es
        add     ax,1000h
        mov     es,ax
        dec     ch
        or      ch, ch                          ; <----look for last segment
        jnz     endint                          ; <----back for more
        mov     bx, word ptr lastsegoffsett     ; <---- only new line in code
        jmp     endint

fixups:
         NOT     DI          ; Kill infinity loop

         mov    AL,34h          ; 7-16-91  slow down timer
         out    43h,al          ;    "
         mov    AL,00h          ;    "
         out    40h,al          ;    "
         out    40h,al          ;    "
         jmp    endint

