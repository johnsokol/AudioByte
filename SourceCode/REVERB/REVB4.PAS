program Reverb;
{   10/08/91  John L. Sokol
              Software Sound Reverb

}

var f2:text;
    F1 : FILE;
    FN1,FN2:STRING;
    sbuff_count,a2,LOOPSIZE:WORD;
    ERR:WORD;
    C:BYTE;
    D:INTEGER;

    IC:byte;
    z,DONE:BOOLEAN;

    sbuff:array[0..60000] of byte;


function echo(Sample:byte):byte;
var temp:word;
begin

    temp := ((sample + SBUFF[sbuff_count]) div 2) and $ff;

    SBUFF[sbuff_count] := temp ;

    inc(sbuff_count);

    IF sbuff_count > LOOPSIZE THEN
    BEGIN
      sbuff_count := 0;
      INC(C);
    END;

    echo := temp ;

end;



procedure do_reverb;
begin

  c := 0;
  sbuff_count := 0;

  { START REVERB }

  DONE := FALSE;


  WHILE NOT DONE DO
  BEGIN
    BLOCKREAD(F1,IC,1,D);
    IF D = 0 THEN DONE := TRUE;

    WRITE(F2,CHAR( echo(IC) ) );

  END;


  { ********* continue echo output after input is finished *********** }


  C := 1;

  WHILE C < 7 DO
    WRITE(F2,CHAR( echo($80) ) );

end;





begin { MAIN }

  if paramcount <> 3 then
  begin
    writeln;
    writeln(' Reverb  - utility to add a reverb to unsigned sound files ');
    writeln('           (c) 1991 Zebra Research ');
    writeln;
    writeln(' Usage REVERB infile outfile [echo count]');
    writeln(' echo count is the number of samples to echo over');
    writeln('             the maximun number for this is 60000 ');
    writeln;
    writeln(' Example REVERB darth.m11 d.m11 11000 ');
    writeln('   This will use darth.m11 and 11 Khz sound file and create d.m11');
    writeln('   with a 1 second delay echo introduced ');
    halt(0);
  end;

  FN1 := PARAMSTR(1);
  FN2 := PARAMSTR(2);
  VAL(PARAMSTR(3),LOOPSIZE,ERR);

  if err <> 0 then
    begin
      writeln('ERROR echo count must be an whole number ');
      halt(1);
    end;

  if (loopsize < 1) or (loopsize > 60000 ) then
   begin
      writeln('ERROR echo count must be between 1 and 60000');
      halt(1);
   end;

 err := 0;

 {$I-}

  err := err and ioresult;

  ASSIGN(F1,FN1);
  err := err or ioresult;

  ASSIGN(F2,FN2);
  err := err or ioresult;

  RESET(F1,1);
  err := err or ioresult;

  REWRITE(F2);
  err := err or ioresult;

  if err <> 0 then
   begin
      writeln('ERROR OPENING FILES');
      halt(1);
   end;

  {$I+}

  FOR sbuff_count := 0 TO LOOPSIZE DO
   SBUFF[sbuff_count] := 128;

  writeln(' PLEASE WAIT - Computing reverb ');

  do_reverb;

  CLOSE(F1);
  CLOSE(F2);


END.


