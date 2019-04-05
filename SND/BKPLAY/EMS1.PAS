program sptimer;
uses dos,crt,graph,memory;

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

      npages,fsize : longint;

      exitsave : pointer;


{$L d:\bkplay\x.obj}

procedure settimer;
external;

procedure killtimer;
external;




PROCEDURE myexit;
BEGIN
  exitproc := exitsave;
{  Deallocate_Pages;
  error_check;
 }
END;





begin { main }


exitsave := exitproc;
exitproc := @myexit;

 done := false;

 clrscr;
 gotoxy(1,3);

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
   writeln('loading page ', a);
   put_page(a,0);
   rec := ptr(frame_seg,0);
   blockread(f,rec^,$4000,b);
   inc(a);

   until b = 0;

   writeln('done loading ',a,',',npages);


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

  while b < npages do
  begin


    writeln('wait nextseg free');
    repeat until nextseg = 0;

   a := 1 - a;
   inc(b);

   writeln('putting frame',a,'  Page ',b);

   put_page(b,a); { page , frame }

   nextseg := frame_seg - $C00 + (a * $400);
   nextoffset := $C000;

  end;

  writeln('wait nextseg free last');
  repeat until nextseg = 0;

  writeln('wait lastseg played out');
  repeat until cseg = 0;

  killtimer;


end.
