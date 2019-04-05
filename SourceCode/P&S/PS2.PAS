Program Point_Shoot;
{
 *    Point and shoot sound file player
 *
 *
 *
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

       portstr :array[0..3,0..1] of string[10] = (
                                                 ('Autodetect',''),
                                                 ('LPT 1     ','-p1 '),
                                                 ('LPT 2     ','-p2 '),
                                                 ('LPT 3     ','-p3 ')  );



type slist = record
             name:string[12];
             speed:byte;
             size:integer;
             end;


var
    dirinfo:searchrec; { Needed for directory operations }

    Splay: PathStr; { the path and filename to SPLAY.EXE }

    sl:array[1..numfiles] of slist; { main storage array }


    top,    { this is record number at top of window }
    slect,  { the selected record number }
    sli:    { this is and index when loadinf dir and max record # afterwards }
            integer;

    schange,        { indicted if there has been changes mode to sample rates}
    done:boolean;
    port:integer;   { points ti entry in portstr }




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


{ CALLS EXTERNALY SPLAY.EXE
  this sets up the command line parameters for speed and port useage also }

procedure playit(fn:string;speed:integer);
var oper,sp:string;
begin
   gotoxy(50,8);
   write('Playing ',fn,'       ');

   str(speed,sp);
   oper  := '-s'+sp+' '+portstr[port,1] + fn ; { assemble command line }

      {$M 15000,0,64000}           { Leave memory for child process }
      SwapVectors;
        Exec( Splay, oper );        { Call it }
      SwapVectors;

      gotoxy(50,8);

      if DosError <> 0 then
        WriteLn('Could not execute SPLAY.EXE');

      write('                          ');



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

function fixdn(s:string):string;
var b,e:string;
begin
  s := s + '                 ';
  s[0] := chr(12);
  fixdn := s;
end;


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



procedure find_splay;
begin
{ find SPLAY path to save loading time }

  Splay := FSearch('SPLAY.EXE',GetEnv('PATH'));
    if Splay = '' then
      begin
        WriteLn('SPLAY.EXE not found in path');
        halt(1);
      end;

  splay := FExpand(splay);

end;



procedure disp_port;
begin
  gotoxy(50,5);
  write('Port to use');
  gotoxy(50,6);
  write(portstr[port,0] );;
end;



procedure disp_list;
var a,speed,start:integer;
begin
 start := top;
 for a := 0 to 22 do
 begin
  gotoxy(1,a+3);

  if (a+start) < sli then
   begin

     if a + start = slect then
       begin
         TextBackground(3);
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
         TextBackground(1);
         TextColor(7);
       end;


   end
   else
     write('-----------------------------');

 end;
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
begin

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

begin
  a := ord(readkey);

  if a <> 0 then
  begin
   case a of

     CR  : dobutton;
     esc : done := true;

     ord('P'),ord('p') : begin
                           inc(port);
                           if port > 3 then port := 0;
                           disp_port;
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

end;




procedure menu;
begin

  slect := 1;
  top := 1;

  TextBackground(3);
  TextColor(9);

  gotoxy(20,1);
  write('Zebra Reasearch Point and Shoot sound player');

  TextBackground(1);
  TextColor(14);

  gotoxy(1,2);
  write('File name   | speed   | Size');

  TextBackground(1);
  TextColor(7);

  loaddir;
  disp_port;
  disp_list;

  while not done do
    keyboard;

end;




begin { MAIN }

done := false;
port := 0;

textmode(CO80);
TextBackground(0);
TextColor(7);
clrscr;

writeln('Searching Directory');

find_splay;

TextBackground(1);
TextColor(15);
clrscr;

{
writeln(sli -1 ,' Identified');
repeat until keypressed;
  }

menu;

if schange then savespeedfile;

clrscr;

end.

