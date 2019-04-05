program sptimer;
uses dos,crt,graph;



var   f:file;

      count:word;
      a,b        :word;
      coffset    :word;
      cseg       :word;
      nextseg    :word;
      nextoffset :word;
      port       :word;

      segs:array[1..10] of word;
      offf:array[1..10] of word;
      ps:array[1..10] of pointer;
      cs:integer;
      done :boolean;

{$L d:\bkplay\x.obj}

procedure settimer;
external;

procedure killtimer;
external;


begin { main }

 done := false;

 clrscr;
 gotoxy(1,3);

 assign(f,'d:\x.snd');
 reset(f,1);

   a := 1;

   getmem(ps[1],$4000);
   getmem(ps[2],$4000);


   offf[1] := ofs(ps[1]^) div 16 ;
   offf[2] := ofs(ps[2]^) div 16 ;

   segs[1] := seg(ps[1]^) + offf[1] ;
   segs[2] := seg(ps[2]^) + offf[2] ;

   ps[1] := ptr(segs[1],$000);
   ps[2] := ptr(segs[2],$000);

   segs[1] := segs[1] - $C00;
   segs[2] := segs[2] - $C00;


   blockread(f,ps[a]^,$3fff,b);


 coffset := $C000;

 cseg := segs[1];

 nextseg := 0;
 nextoffset := 0;


 port := $378;


 settimer;

 count := 2;


  while not done do
  begin

    writeln('wait nextseg free');
    repeat until nextseg = 0;

   a := 3 - a;

   writeln('loading seg',a);

   blockread(f,ps[a]^,$3fff,b);
   writeln(b,' bytes loaded ');

   nextseg := segs[a];
   nextoffset := $C000;


   if b < $3fff then
   begin
    writeln('done loading ');
    done := true;
    close(f);
   end;

  end;

  writeln('wait nextseg free last');
  repeat until nextseg = 0;

  writeln('wait lastseg played out');
  repeat until coffset > b;

  killtimer;


end.
