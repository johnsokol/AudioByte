program x;


var f2:text;
    F1 : FILE;
    FN1,FN2:STRING;
    A,LOOPSIZE:WORD;
    ERR:WORD;
    B,C:BYTE;
    D:INTEGER;

    IC:CHAR;
    DONE:BOOLEAN;

    sbuff:array[0..60000] of byte;


begin { MAIN }
  FN1 := PARAMSTR(1);
  FN2 := PARAMSTR(2);
  VAL(PARAMSTR(3),LOOPSIZE,ERR);

  ASSIGN(F1,FN1);
  ASSIGN(F2,FN2);
  RESET(F1,1);
  REWRITE(F2);

  FOR A := 0 TO LOOPSIZE DO
   SBUFF[A] := 128;

  A := 0;

  { START REVERB }

  DONE := FALSE;

  WHILE NOT DONE DO
  BEGIN
    BLOCKREAD(F1,IC,1,D);
    IF D = 0 THEN DONE := TRUE;

    B := ORD(IC);
    B := (WORD(B) + SBUFF[A]) DIV 2;
    SBUFF[A] := B;
    INC(A);

    IF A > LOOPSIZE THEN A := 0;

    WRITE(F2,CHAR(B));


  END;

  C := 1;

  WHILE C < 7 DO
  BEGIN
    B := (WORD(128) + SBUFF[A]) DIV 2;
    SBUFF[A] := B;
    INC(A);

    IF A > LOOPSIZE THEN
    BEGIN
      A := 0;
      INC(C);
    END;

    WRITE(F2,CHAR(B));
  END;

  CLOSE(F1);
  CLOSE(F2);


END.


