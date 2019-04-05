program sptimer;
uses dos,crt,timer;

var count:word;

{$L d:\bktimer\tick.obj}

procedure settimer;
external;

procedure killtimer;
external;


begin { main }

 clrscr;
 settimer;


 mark;
 count := 0;
 repeat
 gotoxy(1,1);
 write(count,'  ');
 until count > 60000;

 writeln(elapse_minutes);

 killtimer;

end.
