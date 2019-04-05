program d_record;

uses dos,crt,timer;
const bsiz = $ff00;

type dta = array[1..bsiz] of byte;
     dta_ptr = ^dta;

var  arrs:array[1..200] of dta_ptr;
     memsiz,dtasiz:array[1..200] of word;
     blk:byte;
     c:char;
     fn:string;
     mems,meml:longint;
     speed:byte;

FUNCTION INADC:BYTE;
   INLINE( $BA/$7A/$02/
           $B1/$01/
           $B0/$02/
           $EE/
           $B0/$06/
           $EE/
           $BA/$79/$02/
           $EC/
           $D0/$D0/
           $D0/$D0/
           $D0/$D1/
           $BA/$7A/$02/
           $73/$EB/

           $B0/$00/
           $EE/

           $88/$C8
           );



procedure screen;
 begin
  textbackground(1);
  clrscr;
  gotoxy(1,10);
  writeln('                R       -      Record');
  writeln('                P       -      Play');
  writeln('                D       -      Enter playback delay count');
  writeln('                S       -      Save');
  writeln('                L       -      Load');
  writeln('                F       -      Enter filename');
  writeln;
  writeln('                Esc     -      Quit');
end;


procedure play(dl:byte);
var a,c:byte;
    d:word;
    sdata :dta_ptr;
    t:real;
begin
    clrscr;
    writeln('Play');
     mark;
     c := 1;
     repeat
       sdata := arrs[c];
       for d := 1 to dtasiz[c] do
         begin
           port[$278] := sdata^[d];
           for a := 0 to dl do;
         end;
       inc(c);
    until dtasiz[c] = 0;
    t := elapse_minutes;

    screen;
    gotoxy(1,20);
 writeln( meml/(t*60):5:2 ,' Samples per sec');
 writeln('length ',t*60:3:2,' Sec');
    port[$278] := 128;
   writeln('done');
end;

procedure rec;
var a,c:byte;
    d:word;
    sdata :dta_ptr;
    t : real;
begin
  mark;
  clrscr;
  writeln('recording');
     c := 1;
     repeat
       sdata := arrs[c];
       for d := 1 to memsiz[c] do
           sdata^[d] := inadc;
       inc(c);
    until memsiz[c] = 0 ;

    t := elapse_minutes;
    meml := mems;

    screen;
    gotoxy(1,20);
 writeln( meml/(t*60):5:2 ,' Samples per sec');
 writeln('length ',t*60:3:2,' Sec');
    for c := 1 to blk do dtasiz[c] := memsiz[c];
    dtasiz[blk+1] := 0;
 writeln('done');
end;

procedure load(fl:string);
 var c:byte;
     e:word;
     f:file;
begin
meml := 0;
  screen;
  gotoxy(1,20);
  writeln('Loading ',fl);
  assign(f,fl);
 {$I-}
  reset(f,1);
 {$I+}
 if ioresult = 0 then
begin
  c := 0;
  repeat
     inc(c);
     blockread(f,arrs[c]^,memsiz[c],e);
     dtasiz[c] := e;
     meml := meml + e;
{       writeln(dtasiz[c]);
 } until (e = 0) or (c = blk);

  dtasiz[c+1] := 0;
  close(f);
  gotoxy(1,20);
  clreol;
  writeln( meml / 1000:3:3,' K loaded');

end else
  begin
    gotoxy(1,20);
    clreol;
    writeln('file no found');
  end;

end;

procedure Save(fl:string);
 var c:byte;
     e:word;
     f:file;
begin
  screen;
  gotoxy(1,20);
  writeln('Saving ',fl);
  assign(f,fl);
  rewrite(f,1);
  c := 0;
  repeat
     inc(c);
     blockWrite(f,arrs[c]^,dtasiz[c],e);
{     writeln(dtasiz[c],',',e);
 } until (dtasiz[c+1] = 0) ;
  close(f);

 gotoxy(1,20);
 clreol;
 writeln('done');

end;

procedure mem_manage;
var a,b,c:longint;
    x:byte;
begin
  mems := 0;
  for x := 1 to 200 do memsiz[x] := 0;

  blk := 0;
  while maxavail > 200 do
    begin
      inc(blk);
      if maxavail < bsiz then
         begin
           memsiz[blk] := maxavail - 100;
           getmem(arrs[blk],maxavail-100);
         end
      else
         begin
           memsiz[blk] := bsiz;
           getmem(arrs[blk],bsiz);
         end;

      mems := mems + memsiz[blk];
    end;
   gotoxy(1,20);
  writeln( mems ,' allocated for recording ,',memavail,' bytes remaining in system');

  for x := 1 to 200 do dtasiz[x] := 0;

end;



procedure wait;
  var x,cn:byte;
begin
  writeln;
  cn := 0;
  repeat
    x := inadc;
    port[$278] := x;
    if (x = 0) or (x=255) then
          begin
           if cn = 0 then
             begin
               gotoxy(50,22);
               textcolor(12);
               write('Saturation');
               textcolor(7);
             end;
           cn := 255;
          end;

    if cn > 0 then
      begin
       dec(cn);
       if cn = 0 then
         begin
           gotoxy(50,22);
           write('            ');
         end;
      end;

  until keypressed;
 c := readkey;
 writeln;
end;


begin   {main}
 meml := 0;
  port[$27A] := 0;
  fn := 'test.snd';
  speed := 8;
  screen;
  mem_manage;


repeat

 wait;
  case c of
  'r','R':rec;
  'p','P':play(speed);
  'd','D':begin
            clrscr;
            writeln(' Old playback Speed = ',speed);
            write('Enter playback Speed >');
            readln(speed);
            screen;
          end;
  's','S':save(fn);
  'l','L':load(fn);
  'f','F':begin
            clrscr;
            write('Enter file name for load & save >');
            readln(fn);
            screen;
            gotoxy(1,20);
            writeln(' Filename --> ',fn);
          end;
  end;

until c = chr(27);

end.