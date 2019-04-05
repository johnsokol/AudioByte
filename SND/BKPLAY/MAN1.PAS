program DRAW;
uses dos,crt,graph;
const
     conv = 3.14159265 / 180;

var mx,my:integer;
    n:array[1..18] of byte;     { NUm Of points }
    la,lo:array[1..70,1..18] of integer;  { LAtitude LOngitude }
    col:array[1..70,1..18] of boolean;
    j:integer;
    images:array[1..18] of pointer;
    im_siz:word;

procedure loaddata;
var f:text;
    z:string;
    a,b:integer; { counters }
begin
clrscr;
{  writeln('45,40,43,20,20,46,69,44,25,15,10,18,17,42,63,27,11,36');
 }
  assign(f,'c:\earth\drw.dat');
  reset(f);
  a := 1;
  b := 1;
  while not( seekeof(f) ) do
  begin
   repeat
       read(f,la[a,b],lo[a,b]);
       inc(a);
   until seekeoln(f) ;
   dec(a);
    n[b] := a;
{    write(a,',');
 }   inc(b);
    a := 1;
  end;
  close(f);
end;

procedure fix_data;
 var  a,b:integer;
begin
   for a := 1 to 18 do
     for b := 1 to n[a] do
      begin

       if lo[b,a] > 20 then
         begin
           lo[b,a] := lo[b,a] - 100;
           col[b,a] := false;
         end
       else
         col[b,a] := true;

       la[b,a] := 90 - la[b,a];
     end;

   for a := 1 to 18 do
     col[1,a] := false;

end;


procedure g_int;
var gr_drv,gr_mode:integer;
    X,Y:WORD;
  begin
    directvideo := false;
    gr_drv := 1;
    gr_mode := 1;
    initgraph(gr_drv,gr_mode,'c:\tp\graph');
    settextstyle(2,0,4);
    mx := getmaxx;
    my := getmaxy;

  end;

{
function xlatx(lat,lon:real):integer;
begin
   Xlatx := round( 100 + 50 * SIN(LAt) * SIN(LOn)) ;
end;

function xlaty(lat,lon:real):integer;
begin
   Xlaty := round( 100 + 50 *  -COS(LAt)  );
end;
 }


function xlatx(lat,lon:real):integer;
begin
   Xlatx := round( 100 + 50 * cos(LAt) * SIN(LOn) ) ;
end;

function xlaty(lat,lon:real):integer;
begin
   Xlaty := round( 100 + 50 *  -COS(LAt)  );
end;

procedure draw_it(j:integer);
 var a,i,k,x,y:integer;
     lat,lon:real;
begin

FOR K := 18 downTO 1 do
 begin
   I := J+K-1;
   IF I>18 THEN  I := I-18;

   for a := 1 to n[i] do
   begin
     LOn := ( LO[a,i]-110+20*K ) * conv;
     LAt := LA[a,i]*conv;

     x := xlatx(lat,lon);
     y := xlaty(lat,lon);

 {    y := 50 + round(lat * 25);
     x := 100 + round(lon * 25);

  }
     if k >= 9 then setcolor(2) else
     setcolor(15);

     if col[a,i] then
       LINETO (X,Y)
     else
       moveto(x,y);
   end;
 end;
end;


{

CIRCLE(128,96),96,15
PAINT(240,190),15,15
PAINT(20,190),15,15
SAVEM "PAGE" + MID$(STR$(19-J),2),&H0E00,&H19FF,&HB44A

NEXT J
}


begin {MAIN}
 loaddata;
 fix_data;
 g_int;
 im_siz := imagesize(0,0,200,100);
 writeln(im_siz);

 for j := 1 to 18 do
   getmem(images[j],im_siz);

 for j := 18 downto 1 do
  begin
   cleardevice;
   draw_it(j);
   getimage(50,50,250,150,images[19-j]^);
  end;

 cleardevice;
  j := 1;
  repeat
   putimage(50,50,images[j]^,0);
   delay(50);
   inc(j);
   if j > 18 then J := 1;
  until keypressed;


end.