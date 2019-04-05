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
   blockread(f,ps[a]^,$ffff,b);
   segs[a] := seg(ps[a]^);
 end;
 inc(a);
 until (a>10) or (b = 0);

 close(f);


 coffset := $0000;

 cseg := segs[1];

 nextseg := segs[2];
 nextoffset := $0000;


 port := $378;

 settimer;

 count := 2;

 repeat

 inc(count);
 b := 0;
 repeat
  inc(b);
  gotoxy(1,1);
  write(b:4,' offset = ',coffset,'  ');
 until (nextseg = 0 )or (b > 20000);

 nextseg := segs[count];
 dec(a);

 until (count > 10) or (a = 0);

 killtimer;


end.
