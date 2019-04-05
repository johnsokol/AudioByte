program convert_sign;
uses dos,crt;
var  dirinfo:searchrec;
     fn1,fn2:string;




procedure copy(fn1,fn2:string);
var
    b1,b2:file;
    e1,e2:integer;
    buff:array[0..$7FFF] of byte;
begin

 { Copy File BACK }
 assign(b2,fn2);
 rewrite(b2,1);


 assign(b1,fn1);
 reset(b1,1);

  repeat

  blockread(b1,buff,$7FFF,e1);

  blockwrite(b2,buff,e1,e2);

  until ( e1 = 0) or ( e1 <> e2);

 close(b1);

 { do second pass }

 assign(b1,fn1);
 reset(b1,1);

  repeat

  blockread(b1,buff,$7FFF,e1);

  blockwrite(b2,buff,e1,e2);

  until ( e1 = 0) or ( e1 <> e2);

 close(b1);


 close(b2);

end;

begin

    copy( paramstr(1) , paramstr(2) );

end.

