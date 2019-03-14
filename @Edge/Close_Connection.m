function [] = Close_Connection(laser)
   % close serial connection to laser, delete SerialObj
   fclose(laser.SerialObj);  % always, always want to close serial connection
   delete(laser.SerialObj);
   laser.ConnectionStatus = 'Laser Connection Closed';
   laser.isConnected = 0;
   fprintf('[Edge] Connection closed.\n');
end
