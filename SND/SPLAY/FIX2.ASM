;
;       use "port" as an address pointer
;       use "pindex" as an index to add to the value you want
;       use "portaddr" is the value to be used when completed

port_detect:
        mov     pindex, -2
nextport:
        mov     AB, 0
        inc     pindex
        inc     pindex
        add     port, pindex
        cmp     pindex, index_max
        ja      use_default
next_t:
        out     port, AB

        NOP                     ; use as many as needed
        NOP

        in      al, port
        test    al, AB
        jne     nextport
        inc     AB
        cmp     AB, terminalcount       ; terminal count == 3 ??
        jl      next_t

        mov     portaddr, port  ; <------these are pointers
portret:
        ret

use_default:
        move    portaddr, port  ; <------these are pointers
        ret


