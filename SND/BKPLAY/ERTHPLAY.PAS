program sptimer;
uses dos,crt,graph,memory;

const spd = $20;

 var
  rec     :pointer;

var   f:file;

{ Needed for Linked in sound player }
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

      c,npages,fsize : longint;

      exitsave : pointer;


var mx,my:integer;
    j:integer;
    images:array[1..18] of pointer;
    im_siz:word;


procedure loadimg;
var f:file;
    a,e:word;
    fl:string;
begin
  for a := 1 to 18 do
   begin
     str(a,fl);
     fl := 'c:\bkplay\earth'+fl+'.img';
     assign(f,fl);
     reset(f,1);
     blockread(f,images[a]^,im_siz,e);
     close(f);
   end;
end;


procedure g_int;
var gr_drv,gr_mode:integer;
    X,Y:WORD;
  begin
    directvideo := true;
    gr_drv := 1;
    gr_mode := 1;
    initgraph(gr_drv,gr_mode,'c:\bkplay');
    mx := getmaxx;
    my := getmaxy;

  end;




{$L C:\bkplay\x.obj}

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
 im_siz := imagesize(0,0,100,100);
 if IM_siz <> 2632 then halt(1);

 for j := 1 to 18 do
   getmem(images[j],im_siz);

  loadimg;

 cleardevice;
  j := 1;


{ for ems }


exitsave := exitproc;
exitproc := @myexit;

 done := false;

 assign(f,'c:\bkplay\x.snd');
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

 put_page(b,a); { page , frame }

 c := $BFFF ;

  while b < npages do
  begin

  if c > $C000 then c := c - $4000;

  repeat
   if coffset > c then
   begin
     putimage(50,50,images[j]^,0);
     inc(j);
     if j > 18 then J := 1;
     c := c + spd;
   end;
  until nextseg = 0;

   a := 1 - a;
   inc(b);


   put_page(b,a); { page , frame }

   nextseg := frame_seg - $C00 + (a * $400);
   nextoffset := $C000;

  end;


  repeat
     putimage(50,50,images[j]^,0);
     inc(j);
     if j > 18 then J := 1;
  until nextseg = 0;


  repeat
   putimage(50,50,images[j]^,0);
   inc(j);
   if j > 18 then J := 1;
  until cseg = 0;

  killtimer;

  closegraph;

end.


