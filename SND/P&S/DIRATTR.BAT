
procedure loaddir;
begin
{ load sound file list }


findfirst('*.*',anyfile,dirinfo);


 while doserror = 0 do
  begin


      writeln(dirinfo.name);

  if dirinfo.attr and ReadOnly  <> 0  then write(' ReadOnly ,');
  if dirinfo.attr and Hidden    <> 0  then write(' Hidden   ,');
  if dirinfo.attr and SysFile   <> 0  then write(' SysFile  ,');
  if dirinfo.attr and VolumeID  <> 0  then write(' VolumeID ,');
  if dirinfo.attr and Directory <> 0  then write(' Directory,');
  if dirinfo.attr and Archive   <> 0  then write(' Archive  ,');
  writeln;


    findnext(dirinfo);
  end;
end;

