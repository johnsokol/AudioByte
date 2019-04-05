program play_sound;

uses dos,crt,timer;
const bsiz = $ff00;
      lpt = $278;

type dta = array[1..bsiz] of byte;
     dta_ptr = ^dta;

var  arrs:array[1..200] of dta_ptr;
     memsiz,dtasiz:array[1..200] of word;
     i,par,blk:byte;
     err:integer;
     c:char;
     fn:string;
     mems,meml:longint;
     speed:byte;

    dirinfo:searchrec;



procedure play(dl:byte);
var a,c:byte;
    d:word;
    sdata :dta_ptr;
    t:real;
begin
    writeln('Play');
     mark;
     c := 1;
     repeat
       sdata := arrs[c];
       for d := 1 to dtasiz[c] do
         begin
           port[lpt] := sdata^[d];
           for a := 0 to dl do;
         end;
       inc(c);
    until dtasiz[c] = 0;
    t := elapse_minutes;
 writeln( meml/(t*60):5:2 ,' Samples per sec');
 writeln('length ',t*60:3:2,' Sec');
    port[lpt] := 128;
   writeln('done');
end;


procedure load(fl:string);
 var c:byte;
     e:word;
     f:file;
begin
meml := 0;
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
end else writeln('file no found');
  writeln( meml / 1000:3:3,' K loaded');
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

  writeln( mems ,' allocated for recording ,',memavail,' bytes remaining in system');

  for x := 1 to 200 do dtasiz[x] := 0;

end;


begin { main }
 meml := 0;
  clrscr;
  mem_manage;

 par := paramcount;

 if par > 1 then
  val(paramstr(2),speed,err)
 else
  speed := 8;

  if err <> 0 then speed := 8;



findfirst(paramstr(1),archive,dirinfo);
 while doserror = 0 do
  begin
    load(Dirinfo.name);
    play(speed);

    findnext(dirinfo);
  end;



end.