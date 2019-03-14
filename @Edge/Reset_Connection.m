function [] = Reset_Connection(laser)
   % close, re-connect, read & clear error
   try
      laser.Close_Connection;
   catch
       % do nothing
   end
   laser.Open_Connection;
   laser.Read_Error;
   laser.Clear_Error;
end
