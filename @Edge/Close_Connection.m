% File: Close_Connection.m @ Edge
% Author: Urs Hofmann
% Mail: hofmannu@ethz.ch
% Date: 05.11.2020

% Description: closes the serial connection to laser

function Close_Connection(laser)
   fprintf("[Edge] Closing connection... ");
   % close serial connection to laser, delete SerialObj
   laser.SerialObj = [];  % always, always want to close serial connection
   laser.isConnected = 0;

   fprintf('done!\n');
end
