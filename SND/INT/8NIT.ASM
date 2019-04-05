        MOV     DX,027Ah
        MOV     CL,01          ; Set finished flag bit

rloop:  MOV     AL,02
        OUT     DX,AL          ; 27A = 010b  ( toggle clock line low )

        MOV     AL,06
        OUT     DX,AL          ; 27A = 110b  ( toggle clock line hi )

        MOV     DX,0279h
        IN      AL,DX          ; read in bit

        RCL     AL,1
        RCL     AL,1
        RCL     CL,1           ; shift bit 2 into CL

        MOV     DX,027Ah
        JNB     rloop          ; See if FLAG bit was shifted out of CL

        MOV     AL,00h
        OUT     DX,AL          ; 27A = 000b  ( chip unselected )

        MOV     AL,CL

