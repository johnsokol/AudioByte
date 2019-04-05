program sptimer;
uses dos,crt,graph;


const  sinth = 0.707106781;
       costh = 0.707106781;


var  x1,x2,y1,y2:real;
     bd,plot,v,cnt,mask,mi:integer;


var
  GraphDriver : integer;  { The Graphics device driver }
  GraphMode   : integer;  { The Graphics mode value }
  MaxX, MaxY  : word;     { The maximum resolution of the screen }
  ErrorCode   : integer;  { Reports any graphics errors }
  MaxColor    : word;     { The maximum color value available }
  OldExitProc : Pointer;  { Saves exit procedure address }


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

{$L d:\bkplay\x.obj}

procedure settimer;
external;

procedure killtimer;
external;


procedure Initialize;
{ Initialize graphics and report any errors that may occur }
begin
  { when using Crt and graphics, turn off Crt's memory-mapped writes }
  DirectVideo := False;
  GraphDriver := 0;

                  { use autodetection }
  InitGraph(GraphDriver, GraphMode, 'c:\tp\graph');  { activate graphics }
  ErrorCode := GraphResult;               { error? }
  if ErrorCode <> grOk then
  begin
    Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
    Halt(1);
  end;
  Randomize;                { init random number generator }
  MaxColor := GetMaxColor;  { Get the maximum allowable drawing color }
  MaxX := GetMaxX;          { Get screen resolution values }
  MaxY := GetMaxY;
end; { Initialize }


Procedure CURV (x1,y1,x2,y2:real;c:integer);

  var mx,my,xdiff,ydiff,xdir,ydir:real;

  begin

     xdiff := x2-x1;
     ydiff := y2-y1;

     if c = mi then line (round(x1),round(y1),round(x2),round(y2))

     else begin

        xdir := xdiff / 2 / costh;
        ydir := ydiff / 2 / costh;
        mx   := x1 + xdir * costh - ydir * sinth;
        my   := y1 + xdir * sinth + ydir * costh;

        curv(x1,y1,mx,my,c+1);
        curv(mx,my,x2,y2,c+1);

     end;
   end;



begin { main }

 clrscr;
 gotoxy(1,3);

 assign(f,'d:\snd\darth.m11');
 reset(f,1);
 a := 1;

   getmem(ps[a],$ffff);
   blockread(f,ps[a]^,$ffff,b);
   segs[a] := seg(ps[a]^);

 close(f);


 coffset := 255;

 cseg := segs[1];

 nextseg := segs[1];
 nextoffset := 255;


 port := $378;




   graphmode := 0;

   initialize;


   x1 := 220;
   y1 := maxy div 3;
   x2 := maxx-220;
   y2 := maxy div 3;
   mi := 13;


 settimer;

 count := 2;


  while mi > 2 do
  begin
    setcolor(mi);
    curv (x1,y1,x2,y2,1);

    repeat until coffset > 60000;
    coffset := 255;

    nextseg := segs[1];
    dec(mi);
  end;

 killtimer;


end.
