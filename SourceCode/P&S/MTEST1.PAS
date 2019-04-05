program mtest;
uses crt,dos,mmouse;

var x,y,b:integer;
    regs : Registers;


  begin

  clrscr;

  m_int;
  m_on;


  repeat
   m_stat(x,y,b);

   gotoxy(1,1);
   write(x div 8:3,',',y div 8:3,',',b:2,'   ');

  until b = 3;

  m_off;

end.
