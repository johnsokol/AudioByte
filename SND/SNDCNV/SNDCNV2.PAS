program convert_sign;
uses dos,crt;
var  dirinfo:searchrec;
     fn1,fn2:string;


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




procedure copy(fn1,fn2:string);
var
    b1,b2:file;
    e1,e2:integer;
    buff:array[0..$7FFF] of byte;
begin

 { Copy File BACK }

 assign(b1,fn1);
 assign(b2,fn2);
 reset(b1,1);
 rewrite(b2,1);

  repeat

  blockread(b1,buff,$7FFF,e1);

  for e2 := 0 to e1 do                       { flip from signed to unsigned}
    buff[e2] := (word(buff[e2]) + $80) and $ff;

  blockwrite(b2,buff,e1,e2);

  until ( e1 = 0) or ( e1 <> e2);

 close(b1);
 close(b2);

end;

begin { MAIN }

  if paramcount <> 1 then
  begin
    writeln;
    writeln(' Sound Convert - A utility to convert signed to unsigned sound files ');
    writeln('                 and unsigned to signed files. ');
    writeln;
    writeln(' Version 1.0   2/15/92   1990 - 1992 Zebra Research ');
    writeln;
    writeln(' Usage: SNDCNV [files] ');
    writeln('    files = Names of files to convert. Wildcards *,? ok.');
    writeln;
    writeln(' Example: SNDCNV *.IFF ');
    writeln('    This would generate converted copys of all .IFF file  ');
    writeln('    with the extention .CNV .');
    writeln('    The files can then be renamed to .SND manualy ');
    writeln('    using:  REN *.cnv *.snd ');

    halt(0);
  end;


findfirst(paramstr(1),archive,dirinfo);
if doserror <> 0 then
begin
  writeln(' No files found to convert ');
  halt(1);
end;

 while doserror = 0 do
  begin
    fn1 := Dirinfo.name ;
    fn2 := base(fn1) + '.cnv';
    copy( fn1 , fn2 );
    findnext(dirinfo);
  end;

end.



