Program Point_Shoot;
{
     Point and shoot sound file player

 R Release
 B Beta

   PS4.pas  02/09/92  John L. Sokol
            Added support of SPLAYER.EXE Internal speaker sound player
            Fixed monochrome video mode


   PS3.pas  02/01/92  John L. Sokol

            This is really the first operational version

            This is designed to be a front end to SPLAY.EXE
              it Generates a Data base of sample rate for sound
              files and allows easy playing of samples
              and Transparent Data Base control

            Supports :
              Mouse and Keyboard
              Text Mode only

            Requirements:
              SPLAY.EXE and Audio Byte Sound Adapter

            Bugs Noticed:
              colors have a problem on Mono monitor

            ( Not really in Point and shoot )
              SPLAY.EXE can not be stopped playing till it has reached
                end of file.


}



uses dos,crt;


const  numfiles = 200;
       defspeed = 1;    { 22 KHZ }

       { This is used to indicate directories and unknown speeds
         in the speed field on slist }

       vnul = 255;
       vdir = 250;
       vunk = 20;


       speedstr:array[0..9] of string[8] =
       ('44000 Hz','22000 Hz','16000 Hz','13500 Hz','11000 Hz',
        ' 8000 Hz',' 7000 Hz',' 6500 Hz',' 5500 Hz',' 5000 Hz');

       portstr :array[0..4,0..1] of string[10] = (
                                                 ('Autodetect',''    ),
                                                 ('LPT 1     ','-p1 '),
                                                 ('LPT 2     ','-p2 '),
                                                 ('LPT 3     ','-p3 '),
                                                 ('PC Speaker',''    )
                                                                     );

type slist = record
             name:string[12];
             speed:byte;
             size:integer;
             end;

     carray = array[1..2000] of char;

var
    plug : ^carray;
    regs : Registers;
    dirinfo:searchrec; { Needed for directory operations }

    SOUNDPLAYER,Splayer,Splay: PathStr; { the path and filename to SPLAY.EXE }

    sl:array[1..numfiles] of slist; { main storage array }


    top,    { this is record number at top of window }
    mslect, { to tell if mouse did selection }
    slect,  { the selected record number }
    sli:    { this is and index when loadinf dir and max record # afterwards }
            integer;

    mmouse,         { if mouse is present it's true }
    schange,        { indicted if there has been changes mode to sample rates}
    mono,done:boolean;
    PRTS,port:integer;   { points ti entry in portstr }



{$L d:\src\p&s\screen.obj }
procedure screen;
external;



{ ******************** mouse code ************************** }

{  INITIALIZE MOUSE  and set flags if not detected }
procedure m_int;
var   regs : Registers;
begin

   mmouse := true;

    regs.AX := 0;
    regs.BX := 0;
    regs.CX := 0;
    regs.DX := 0;
    Intr($33,regs); { Call MOUSE driver }

   if regs.AX <> $FFFF then
   begin
     mmouse := false;
  {   writeln('MOUSE NOT detected'); }
   end;

end;


procedure m_on;
var   regs : Registers;
begin
    regs.AX := 1;
    regs.BX := 0;
    regs.CX := 0;
    regs.DX := 0;
    Intr($33,regs); { Call MOUSE driver }

     {mouse cursor on}
end;

procedure m_off;
var   regs : Registers;
begin
    regs.AX := 2;
    regs.BX := 0;
    regs.CX := 0;
    regs.DX := 0;
    Intr($33,regs); { Call MOUSE driver }
        {mouse cursor off}
end;

procedure m_stat(var x,y,button:word);
var   regs : Registers;
begin
    regs.AX := 3;
    regs.BX := 0;
    regs.CX := 0;
    regs.DX := 0;
    Intr($33,regs); { Call MOUSE driver }

    button := regs.BX;
    x      := regs.CX;
    y      := regs.DX;
end;

{ Moves location on mouse cursor on screen }
procedure move_m(x,y:word);
var   regs : Registers;
begin
    regs.AX := 4;
    regs.BX := 0;
    regs.CX := x;
    regs.DX := y;
    Intr($33,regs); { Call MOUSE driver }
end;

procedure m_move(var x,y:word);
var   regs : Registers;
begin
    regs.AX := 11;
    regs.BX := 0;
    regs.CX := 0;
    regs.DX := 0;
    Intr($33,regs); { Call MOUSE driver }
    x      := regs.CX;
    y      := regs.DX;

 {gets mouse movement in mickies 1/100 of an inch}
end;


{ ************************** main code **************************}


function base(s:string):string;  { pulls out the BASE of a filename }
var a:integer;
    o:string;
begin

 o := '';
 a := 1;
 while (a <= length(s)) and ( s[a] <> '.' ) do
 begin
   o := o + s[a];
   inc(a);
 end;
 base := o;
end;


function extn(s:string):string;  { pulls out the EXTENTION of a filename }
var a:integer;
    o:string;
begin

 o := '';
 a := length(s);
 while (a >= 1 ) and ( s[a] <> '.' ) do
 begin
   o := s[a] + o;
   dec(a);
 end;
 extn := o;
end;


{ CALLS EXTERNALY SPLAY.EXE or SPLAYER.EXE
  this sets up the command line parameters for speed and port usage also }

procedure playit(fn:string;speed:integer);
var oper,sp:string;
begin
   if mmouse then m_off;

   gotoxy(50,8);
   write('Playing ',fn,'       ');

   str(speed,sp);
   oper  := '-s'+sp+' '+portstr[port,1] + fn ; { assemble command line }

      {$M 15000,0,64000}           { Leave memory for child process }
      SwapVectors;
        Exec( SOUNDPLAYER, oper );        { Call it }
      SwapVectors;

      gotoxy(50,8);

      if DosError <> 0 then
        WriteLn('Could not execute SPLAY.EXE');

      write('                          ');

   if mmouse then m_on;

end;



function fixfn(s:string):string;  { fixup of filename to look good on screen}
var b,e:string;
begin
  b := base(s) + '            ';
  e := extn(s) + '    ';
  b[0] := chr(8);
  e[0] := chr(3);
  fixfn := b + '.' + e;
end;

function fixdn(s:string):string;  { fixes up directory name to 12 chars }
var b,e:string;
begin
  s := s + '                 ';
  s[0] := chr(12);
  fixdn := s;
end;


{ ************************ SOUND DATA BASE FUNCTIONS ************** }

procedure savespeedfile;
var f:text;
    err,a,speed:integer;
    fn:string;
begin

  assign(f,'speeds.txt');
  {$I-}
  rewrite(f);
  err := ioresult;

  if err = 0 then
  begin
    gotoxy(50,3);
    write('SAVING Speed database  ');

      a := 1;
      while (a < sli) do
      begin

        if sl[a].speed < 10 then
        begin
          writeln(f,sl[a].name);
          err := ioresult;
          writeln(f,sl[a].speed);
          err := ioresult;
        end;

        inc(a);
      end;
    close(f);
  end
  else
  begin
    gotoxy(50,3);
    write('Error writeln database  ');
  end;

  {$I+}
end;


procedure chkspeedfile;
var f:text;
    err,a,speed:integer;
    fn:string;
begin

  schange := false;
  assign(f,'speeds.txt');
  {$I-}
  reset(f);
  err := ioresult;

  if err = 0 then
  begin
    gotoxy(50,3);
    write('Speed database found  ');

    while (not eof(f)) and (err = 0) do
    begin
      readln(f,fn);
      readln(f,speed);
      err := ioresult;

      a := 1;
      while (a < sli) and (fn <> sl[a].name ) do
        inc(a);

      if fn = sl[a].name then
        sl[a].speed := speed;
    end;
   close(f);
  end
  else
  begin
    gotoxy(50,3);
    write('                      ');
  end;

  {$I+}
end;




procedure loadsfiles(ext:string;speed:integer);
begin

 findfirst('*.'+ext ,archive,dirinfo);

 while (doserror = 0) and (sli < numfiles) do
  begin

     sl[sli].name := fixfn(dirinfo.name);
     sl[sli].speed := speed;
     sl[sli].size := dirinfo.size div 1000 ; { IN K Byte units }
     inc(sli);

    findnext(dirinfo);
  end;

end;



{ LOAD DIRECTORY AND SOUND FILE LIST }

procedure loaddir;
begin

for sli := 1 to numfiles do
 begin
  sl[sli].name := '';
  sl[sli].speed := vnul;
  sl[sli].size := 0;
 end;

 sli := 1;
{ load sound file list }


findfirst('*.*',directory,dirinfo);

 while (doserror = 0) and (sli < numfiles) do
  begin
  if dirinfo.attr and directory <> 0 then
   if dirinfo.name <> '.' then
    begin
      sl[sli].name := dirinfo.name;
      sl[sli].speed := vdir;
      inc(sli);
    end;

    findnext(dirinfo);
  end;

  loadsfiles('M44',0);
  loadsfiles('M22',1);
  loadsfiles('M16',2);
  loadsfiles('M11',4);
  loadsfiles('M8' ,5);
  loadsfiles('M7' ,6);
  loadsfiles('M55',8);
  loadsfiles('SND',vunk);
  loadsfiles('VOC',vunk);

  chkspeedfile;

end;


 { ************************** find players ******************** }

procedure find_soundplayers;
begin
{ find SPLAY path to save loading time }

  PRTS := 0;

  Splay := FSearch('SPLAY.EXE',GetEnv('PATH'));
  Splayer := FSearch('SPLAYER.EXE',GetEnv('PATH'));

    if (Splay = '') and (Splayer = '') then
      begin
        WriteLn('SPLAY.EXE and SPLAYER not found in path');
        halt(1);
      end;

  if Splayer <> '' then
      prts := prts or 2;

  SOUNDPLAYER := splayer;

  if Splay <> '' then
  begin
    splay := FExpand(splay);
    SOUNDPLAYER := splay;
    prts := prts or 1;
  end
  else
   port := 4;

end;


{ ************************* screen display primitives ***************** }

procedure disp_port;
begin
  gotoxy(50,5);
  write('Output to use');
  gotoxy(50,6);
  write(portstr[port,0] );;
end;



procedure disp_list;
var a,speed,start:integer;
begin
 if mmouse then m_off;

 start := top;
 for a := 0 to 22 do
 begin
  gotoxy(1,a+3);

  if (a+start) < sli then
   begin

     if a + start = slect then
       begin
         TextBackground(7);
         TextColor(0);
       end;

     speed := sl[a+start].speed;

     if speed = vdir then
         write(fixdn(SL[a+start].name):12,'       Directory ');
     if speed = vunk then
         write(SL[a+start].name:12,'  Unknown   ',SL[a+start].size:3,' K');
     if speed = vnul then
         write(SL[a+start].name:12,'  Null            ');
     if speed < 10 then
         write(SL[a+start].name:12,'  ',speedstr[speed]:8 ,'  ',
                                                   SL[a+start].size:3,' K');


     if a + start = slect then
       begin
         if mono then
           TextBackground(0)
         else
           TextBackground(1);

         TextColor(7);
       end;


   end
   else
     write('-----------------------------');

 end;
 if mmouse then m_on;
end;

procedure fixslc;
begin
 if slect < top then slect := top;
 if slect > top+22 then slect := top + 22;
end;


procedure fixtop;
begin
 if slect < top then top := slect;
 if slect > top+22 then top := slect - 22;
end;


{
  Perform action when Charage return is pressed on a selected item
  this can be a Directory to change to is play a sample
 }
procedure dobutton;
 var a,speed:integer;
     c :char;
begin
  mslect := 0;

   speed := sl[slect].speed;

   if speed < 10 then
      playit( sl[slect].name, speed );

   if speed = vdir then
     begin
       if schange then savespeedfile;
       chdir( sl[slect].name );
       loaddir;
       slect := 1;
       top := 1;
       disp_list;
     end;

   if speed = vunk then
      playit( sl[slect].name, defspeed );

   if speed = vnul then
     begin
        gotoxy(1,1);
        write('  Null  ENTRY  ');
     end;

  while keypressed do  { wipe buffer }
    c := readkey;


end;



procedure chkmouse;
var x,y,b,ox,oy:word;
    play:boolean;
    speed:byte;
begin
 m_stat(x,y,b);
 if b <> 0 then
 begin
   x := (x div 8)+1;
   y := (y div 8)+1;
   ox := x;
   oy := y;


{*********** in file name area ************}
   if (x < 13) and (y > 2) then
    begin
      play := false;
      slect := (y - 3 )+ top;
      if slect > sli - 1 then slect := sli - 1;
      disp_list;

      if mslect = slect then play := true;  { allows to 2 click before playing}
      mslect := slect;


     { test for button release and scrolling }
      m_move(x,y);
      while b <> 0 do
       begin
         m_stat(x,y,b);
         m_move(x,y);

         if y > 0 then  { scroll here }
         begin
         if y > $7fff then    { this is because it is a int in word form  }
           begin
             if slect > 1    then dec(slect);
             fixtop;
             disp_list;
             play := false;
           end;

         if y <= $7fff then
           begin
             if slect < sli - 1 then inc(slect);
             fixtop;
             disp_list;
             play := false;
           end;

          move_m((ox - 1) * 8,( (slect - top) + 2) * 8); { position mouse }

         end;
       end;

      if play then dobutton;

    end;

{************************* in speed listing area (change speed) ********}

   if (x >= 14) and (x < 23) and (y > 2) then
    begin
      slect := (y - 3 )+ top;
      if slect > sli - 1 then slect := sli - 1;
      disp_list;

      if mslect = slect then
      begin
      if b >= 2 then   { most if this logic if for wrapping around numbers }
            begin
              speed := sl[slect].speed;
              if speed = 9 then
                speed := 0
               else
                if speed < 9 then inc(speed);
              if speed = vunk then speed := defspeed;
              sl[slect].speed := speed ;
              disp_list;
              schange := true;
            end;
      if b = 1 then
            begin
              speed := sl[slect].speed;
              if speed = 0 then
                speed := 9
              else
                if (speed < 10) and (speed > 0) then dec(speed);
              if speed = vunk then speed := defspeed;
              sl[slect].speed := speed ;
              disp_list;
              schange := true;
            end;

      end;

      mslect := slect;

      while b <> 0 do
       begin
         m_stat(x,y,b);
       end;

    end;


{******************* in END and port select area *************}
   if x >= 50 then
   begin

{ end area }
     if y = 20 then done := true;

{ PORT Select area }
     if (y = 5) or (y = 6) then
     begin
      if PRTS <> 2 then
       begin
         inc(port);
         if port > 4 then
         begin
          port := 0;
          SOUNDPLAYER := splay;
         end;
         if port = 4 then
           begin
             if PRTS = 1 then
               port := 0
             else
               SOUNDPLAYER := splayer;
           end;
         disp_port;
       end;

     end;

      while b <> 0 do
       begin
         m_stat(x,y,b);
       end;

   end; { >50 }


 end; { if button pressed }

end;



procedure keyboard;
const   up = $48;
      down = $50;
      left = $4B;
     right = $4D;
      pgup = $49;
      pgdn = $51;
     cpgup = $84;
     cpgdn = $76;
      eend = $4F;
        CR = $0D;
       ESC = $1B;


var speed,a:byte;
    c:char;

begin
  a := ord(readkey);

  if a <> 0 then
  begin
   case a of

     CR  : dobutton;
     esc : done := true;

     ord('P'),ord('p') : begin
                           if PRTS <> 2 then
                           begin
                             inc(port);
                             if port > 4 then
                             begin
                              port := 0;
                              SOUNDPLAYER := splay;
                             end;
                             if port = 4 then
                               begin
                                 if PRTS = 1 then
                                   port := 0
                                 else
                                   SOUNDPLAYER := splayer;
                               end;
                             disp_port;
                           end;
                         end;

   end; { case }
  end
  else
  begin
    a := ord(readkey);

    case a of

    cpgup : begin
             if top > 1       then dec(top);
             fixslc;
             disp_list;
            end;

    cpgdn : begin
             if top < sli - 1 then inc(top);
             fixslc;
             disp_list;
            end;

    pgup  : begin
             if top > 22 then
               top := top - 22
             else
               begin
                 if top = 1 then slect := 1;
                 top := 1;
               end;

             fixslc;
             disp_list;
            end;

    pgdn  : begin
             if top < sli - 44 then
               top := top + 22
             else
              begin
               if top >= sli - 23 then slect := sli - 1;

               if sli - 23 >= 1 then top := sli - 23;

              end;

             fixslc;
             disp_list;
            end;

    up    : begin
             if slect > 1    then dec(slect);
             fixtop;
             disp_list;
            end;

    down  : begin
             if slect < sli - 1 then inc(slect);
             fixtop;
             disp_list;
            end;

    right : begin
              speed := sl[slect].speed;
              if speed < 9 then inc(speed);
              if speed = vunk then speed := defspeed;
              sl[slect].speed := speed ;
              disp_list;
              schange := true;
            end;

    left  : begin
              speed := sl[slect].speed;
              if (speed < 10) and (speed > 0) then dec(speed);
              if speed = vunk then speed := defspeed;
              sl[slect].speed := speed ;
              disp_list;
              schange := true;
            end;



    eend  : done := true;

   end; { case }
 end;

  while keypressed do  { wipe buffer }
    c := readkey;

end; { keyboard }



procedure setup_screen;
begin

  if mono then
    TextBackground(0)
  else
    TextBackground(1);
TextColor(7);
clrscr;

  mslect := 0;
  slect := 1;
  top := 1;

  TextBackground(3);
  TextColor(9);

  gotoxy(20,1);
  write('PC Audio - Point and Shoot sound player');

  if mono then
    TextBackground(0)
  else
    TextBackground(1);
  TextColor(14);

  gotoxy(1,2);
  write('File name   | speed   | Size');

  if mono then
    TextBackground(0)
  else
    TextBackground(1);
  TextColor(7);

  if mmouse then
  begin
    gotoxy(50,20);
    write('Click here to END');

  end;

  disp_port;


end; { setup_screen}


procedure putplug;
var a:word;
begin
 plug := @screen;
 a := 1;
 while plug^[a] <> chr(26) do
   begin
    write(plug^[a]);
    inc(a);
   end;

writeln;

end;



procedure menu;
begin

  setup_screen;

  loaddir;
  disp_list;

  while not done do
   begin
    if keypressed then keyboard;
    if mmouse then chkmouse;
   end;

end;




begin { MAIN }

done := false;
port := 0;
mono := false;

    regs.ah := $F;  { Get video mode}
    Intr($10,regs);
    if  regs.AL = 7 then mono := true;

textmode(CO80);
TextBackground(0);
TextColor(7);
clrscr;

writeln('Searching Directory');

find_soundplayers;

m_int; { initialize mouse driver and detect mouse existance }

if mmouse then m_on;

menu;

if mmouse then m_off;

if schange then savespeedfile;

TextBackground(0);
TextColor(7);
clrscr;

putplug;

end.

