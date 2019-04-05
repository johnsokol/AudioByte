program jesse;

uses dos,crt;


const  boxcolor = 12;
       txtcolor = 7;
       tbkgcolor = 2;
       bbkgcolor = 3;
       outmsg = 'This is a mess';


var ox,oy,x,y,z,a,b:word;
    cx,cy:byte;

var scrn:array[0..64000] of byte;
    done:boolean;




procedure save_scrn;

begin
 cx := wherex;
 cy := wherey;


  for a := 0 to 25*80*2  do
   begin
    scrn[a] := mem[$b800:a]
   end;

end;

procedure rest_scrn;
begin
  for a := 0 to 25*80*2  do
   begin
     mem[$b800:a] := scrn[a];
   end;
   gotoxy(cx,cy);

end;


procedure outtbox(x,y,sx,sy:integer);
 var a,b:integer;
begin

  for a := x to x+sx do
   begin
     gotoxy(a,y);
     write(chr($cd));
     gotoxy(a,y+sy);
     write(chr($cd));
   end;

  for a := y to y+sy do
   begin
     gotoxy(x,a);
     write(chr($ba));
     gotoxy(x+sx,a);
     write(chr($ba));
   end;

     gotoxy(x,y);
     write(chr($c9));

     gotoxy(x,y+sy);
     write(chr($c8));

     gotoxy(x+sx,y);
     write(chr($bb));

     gotoxy(x+sx,y+sy);
     write(chr($bc));

end;

procedure wipe_box(x,y:integer);
var a:integer;
begin
x := x - 2;
y := y - 1;

 for a := 0 to 2 do
  begin
  gotoxy(x,y+a);
  writeln('                ');
  end;

end;

procedure out_txtb(x,y:integer;s:string);
 var l:integer;
begin
  l := length(s);

  textbackground(bbkgcolor);
  textcolor(boxcolor);
  outtbox(x-2,y-1,l+3,2);

  textbackground(tbkgcolor);
  textcolor(txtcolor);
  gotoxy(x,y);
  write(s);

  textbackground(0);

end;


procedure chk_lims;
begin
 if x < 3 then x := 3;
 if y < 3 then y := 3;
 if x + 4 + length(outmsg) > 80 then x := 80 - (4 + length(outmsg));
 if y > 25 - 3 then y := 25 - 3;

end;


procedure keyes;
var c:char;
begin
 repeat until keypressed;
 c := readkey;

 if ord(c) = 0 then
 case ord(readkey) of
 $48: begin
        y := y - 1;
      end;

 $49: begin
        y := y - 1;
        x := x + 1;
      end;

 $4D: begin
        x := x + 1;
      end;

 $51: begin
        y := y + 1;
        x := x + 1;
      end;

 $50: begin
        y := y + 1;
      end;

 $4f: begin
        y := y + 1;
        x := x - 1;
      end;

 $4b: begin
        x := x - 1;
      end;

 $47: begin
        x := x - 1;
        y := y - 1;
      end;
 end;

 if ord(c) = 27 then done := true;

end;


begin { MAIN }

done := false;
x := 20;
y := 20;

Save_scrn;

clrscr;

repeat
  clrscr;

{  wipe_box(ox,oy);
 } out_txtb(x,y,outmsg);
  ox := x;
  oy := y;
  keyes;
  chk_lims;
until done;

rest_scrn;
textcolor(7);

end.

