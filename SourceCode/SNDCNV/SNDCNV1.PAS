program convert_sign;
uses dos,crt;
var  dirinfo:searchrec;



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

 assign(b2,fn1);
 assign(b1,fn2);
 reset(b1,1);
 rewrite(b2,1);

  repeat

  blockread(b1,buff,$7FFF,e1);
  blockwrite(b2,buff,e1,e2);

  until ( e1 = 0) or ( e1 <> e2);

 close(b1);
 close(b2);

end;

begin

findfirst(paramstr(1),archive,dirinfo);
 while doserror = 0 do
  begin
    fn1 := Dirinfo.name ;
    fn2 := base(fn1) + '.cnv';
    copy( fn1 , fn2 );
    findnext(dirinfo);
  end;

end;

