program sptimer;
uses dos,crt,timer;

var a,count:word;

{$L d:\bktimer\x.obj}

procedure settimer;
external;

procedure killtimer;
external;


begin { main }

 clrscr;
 settimer;


 mark;

 for a := 1 to 8 do
 begin
    count := 0;
    repeat
    gotoxy(1,1);
    write((count +( (a-1) * 60000.0))/8000:2:3,'  ');
    until count > 60000;
 end;

 writeln(elapse_minutes*60:2:3);

 killtimer;

end.
