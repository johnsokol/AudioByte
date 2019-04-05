
program cap_test;

uses dos,crt,graph;

var centy,mx,my:integer;
    cg,ch:char;
    E,adjx:real;
    a,b,c:byte;
    d:INteger;
    fo,f:text;
    done :boolean;


procedure transform;
var s,c,ampl:real;
begin

{for freq := 0 to 500 do begin
  if freq = 0 then b := 0 else
     b := pi*2/(1000/freq);
  c := 0;
  s := 0;
   for a := 1 to 1000 do begin
     e := a*b;
     c := c+cos(e)*tme[a];
     s := s + sin (e) * tme[a];
   end;
  ampl := sqrt(sqr(s)+sqr(c))/10;
line(freq*2,round(ampl),freq*2,0);

if ampl > 0.1 then writeln(freq,' ',ampl:4:2);

end;
}end;




function hex(num:integer):string;
const
   hx:array[0..15] of char = '0123456789ABCDEF';
var result:string;
    digit:integer;

begin


result := '';
if num >= 0 then
  repeat
    digit := num mod 16;
    num := num div 16;
    result := hx[digit] + result;
  until num = 0
else
result := 'Error';

hex := result;
end;



procedure g_int;
var gr_drv,gr_mode:integer;
  begin
    directvideo := false;
    gr_drv := 4;
    gr_mode := 0;
    initgraph(gr_drv,gr_mode,'c:\tp\graph');
    writeln(graphresult);
    settextstyle(2,0,4);
    mx := getmaxx;
    my := getmaxy;
    adjx := mx/1000;
    centy := my div 2;
end;

begin

g_int;

{
  assign(fo,paramstr(1));
  rewrite(fo);
 }

  assign(f,paramstr(1));
  reset(f);

d := 0;
e := 0;
done := false;

  while not done do
   begin
     d := TRUNC(E);
     E := E + 1.0;
     read(f,ch);
     a := ord(ch)  ;


{     read(f,cg);

     a := word( ord(ch) ) ;


       if (a >= $80 ) then
         a := a - $80
       else
         a := a + $80;

     write(fo,chr(a));




    write(hex(a),',');
 }


     if d > mx then
      begin
        D := ORD(READKEY);
        IF D = 27 THEN done := true;
        E := 0;
        D := 0;
        cleardevice;
        moveto(0,round(my*(a/255)));

      end;
     lineto(d,round( my* (a/255) ) );
   end;


close(f);
{close(fo);}

closegraph;

end.


