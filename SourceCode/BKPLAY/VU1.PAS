program sptimer;
uses dos,crt,graph,memory;

const spd = $500;

 var
  rec     :pointer;

var   f:file;

{ Needed for Linked in sound player }
      count:word;
      a,b     :word;
      x,nx,nnx,y   :word;

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

      c,npages,fsize : longint;
      sum:real;
      exitsave : pointer;


var mx,my:integer;



procedure g_int;
var gr_drv,gr_mode:integer;
    X,Y:WORD;
  begin
    directvideo := true;
    gr_drv := 1;
    gr_mode := 1;
    initgraph(gr_drv,gr_mode,'c:\tp\graph');
    mx := getmaxx;
    my := getmaxy;

  end;




{$L d:\bkplay\x.obj}

procedure settimer;
external;

procedure killtimer;
external;




PROCEDURE myexit;
BEGIN
  exitproc := exitsave;
  Deallocate_Pages;
  error_check;
  killtimer;
  closegraph;

END;





begin { main }




{ for graphics }
 g_int;

 cleardevice;


{ for ems }


exitsave := exitproc;
exitproc := @myexit;

 done := false;

 assign(f,'d:\x.snd');
 reset(f,1);
 fsize := filesize(f);
 npages := fsize div $4000 + 1;

{ Allocate all expanded memory pages for our usage }
  Allocate_Pages(nPages);
  error_check;

 IF error_code <> status_ok THEN
  begin
    Writeln(pages_available,' Ems pages free in not enough.');
    deallocate_pages;
    halt(1);
  end;

   a := 0;

   repeat
   put_page(a,0);
   rec := ptr(frame_seg,0);
   blockread(f,rec^,$4000,b);
   inc(a);

   until b = 0;



 coffset := $C000;
 cseg := frame_seg - $C00;

 nextseg := 0;
 nextoffset := 0;


 port := $378;


 settimer;

 count := 2;

 a := 0;
 b := 0;
 c := $C000;
 nnx := 1;
 nx := 1;
 sum := 1;
 y := 0;

 put_page(b,a); { page , frame }


  while b < npages do
  begin


  while keypressed do
   begin
    case readkey of
     '1' : inc(b);
     '2' : begin
             if b > 0 then
             dec(b);
           end;

     '3' : b := npages-1;

    end;

   end;


  if c > $C000 then c := c - $4000;

  repeat
   if coffset > c then
   begin
    x := round(sum / nnx * 2) ;
    setcolor(15);
    line(y,my, y,my - x);
    setcolor(0);
    line(y,0, y,my - x);
    c := c + $80;

    nnx := 1;
    sum := 1;
    inc(y);
    if y > mx then y := 0;

   end;

    nx := abs(integer(128) - mem[cseg:coffset] ) ;
{    if nx > sum then sum := nx;
 }
    sum := sum + nx;
    inc(nnx);

  until nextseg = 0;

   a := 1 - a;
   inc(b);


   put_page(b,a); { page , frame }

   nextseg := frame_seg - $C00 + (a * $400);
   nextoffset := $C000;

  end;


  repeat
  until nextseg = 0;


  repeat
  until cseg = 0;

  killtimer;

  closegraph;

end.


