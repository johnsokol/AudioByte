program sptimer;
uses dos,crt;

var   f:file;

      count:word;
      a,b          :word;
      coffset    :word;
      cseg       :word;
      nextseg    :word;
      nextoffset :word;
      port       :word;

      segs:array[1..10] of word;
      ps:array[1..10] of pointer;
      cs:integer;

{$L d:\bp\v.obj}

procedure settimer;
external;

procedure killtimer;
external;




procedure gen1;
var
    sintab:array[0..255] of BYTE;
    os,ss,cnt,delay,b,a,c,d,e:word;

begin
randomize;

  for a := 0 to 255 do sintab[a] := 128+trunc(124*cos(a*pi/128));
  for a := 0 to 255 do write(',',sintab[a]);

  e := 1;

 ss := 1 ;


 for os := 0 to $ffff do
  begin

    b :=e;
    e := 1 + random(5);
    c := $2000;


    while (c > 0) and (os < $ffff) do
    begin
       dec(c);
       inc(d);
     mem[segs[ss]:os] :=
   (  (sintab[ (d * b) and 255] * (c div $40))+(sintab[ (d * e) and 255]* (($2000-c) div $40)) )  div 256   ;
      inc(os);
      if os = $8000 then  settimer;

    end;
  end;

 ss := 2;

 writeln('next bank');

 if nextseg = 0 then
 begin
   writeln('fb done');
 end;

  for os := 0 to $ffff do
  begin

    b :=e;
    e := 1 + random(5);
    if c = 0 then c := $2000;

    while (c > 0) and (os < $ffff) do
    begin
       dec(c);
       inc(d);
     mem[segs[ss]:os] :=
   (  (sintab[ (d * b) and 255] * (c div $40))+(sintab[ (d * e) and 255]* (($2000-c) div $40)) )  div 256   ;
      inc(os);
    end;
  end;


 repeat
  inc(b);
  gotoxy(1,1);
  write(b:4,' offset = ',coffset,'  ');
 until (cseg = 0 )or (b > 20000);



 killtimer;


end;


begin { main }

 clrscr;
 gotoxy(1,3);

 assign(f,'d:\x.snd');
 reset(f,1);
 a := 1;
 repeat

 b := 0;
 if maxavail > $00ffff then
 begin
   getmem(ps[a],$ffff);
   segs[a] := seg(ps[a]^);
 end;
 inc(a);
 until (a>3) ;

 close(f);


 coffset := $0000;

 cseg := segs[1];

 nextseg := segs[2];
 nextoffset := $0000;


 port := $378;

 gen1;



end.
