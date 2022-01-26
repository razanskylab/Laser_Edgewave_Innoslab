% File: Open_Connection.m @ Edge
% Author: Urs Hofmann
% Mail: hofmannu@ethz.ch
% Date: 12.03.2021


function [] = Open_Connection(edge, varargin)
   % open serial connection to laser on COM_PORT, creates serial obj
   % also displays laser status

   flagFail = 1; % should error occur if not connected

   for iargin = 1:2:(nargin - 1)
      switch varargin{iargin}
         case 'flagFail'
            flagFail = varargin{iargin + 1};
         otherwise
            error('Invalid argument passed');
      end
   end

  fprintf('[Edge] Openning serial connection... ');

  edge.SerialObj = serialport(...
   edge.COM_PORT, double(edge.BAUD_RATE), ...
   "Timeout", double(edge.TIME_OUT)); 
  configureTerminator(edge.SerialObj, edge.TERMINATOR);
   %instrfind('Type', 'serial', 'Port', laser.COM_PORT);


   status = getpinstatus(edge.SerialObj);
   if status.ClearToSend
      edge.isConnected = 1;
      flush(edge.SerialObj);
   else
      edge.isConnected = 0;
      warning("this did not work");
   end

   fprintf(' done\n');

   % Create the serial port object if it does not exist
   % otherwise use the object that was found.
   % if isempty(laser.SerialObj)
   %    laser.SerialObj = serial(laser.COM_PORT);
   % else
   %     fclose(laser.SerialObj);
   %     laser.SerialObj = laser.SerialObj(1);
   % end

   % setup serial connection correctly


   % try
   %    edge.SerialNumber = Read_Command(edge, 'r01');
   %    isCorrectLaser = strcmp(laser.SerialNumber, 'S/N:1639') || strcmp(laser.SerialNumber,'S/N:1631');
   %    % if (~isCorrectLaser)
   %    %  error('Invalid laser connected');
   %    % end
   %    connectionIsOpen = strcmp(laser.SerialObj.Status, 'open');
   %    if (connectionIsOpen && isCorrectLaser)
   %       edge.ConnectionStatus = 'Connected';
   %       edge.isConnected = 1;
   %       % disp(laser.ConnectionStatus);
   %       fprintf('[Edge] Laser connection established!\n');
   %    else
   %       disp('[Edge] Connection NOT established!');
   %       disp(['[Edge] isCorrectLaser: ' num2str(isCorrectLaser)]);
   %       disp(['[Edge] Serial number: ' edge.SerialNumber])
   %       disp(['[Edge] connectionIsOpen: ' num2str(connectionIsOpen)]);
   %       return;
   %    end
   %    edge.Read_Error();
   %    edge.isConnected = 1;
   %    % laser.Display_Status;
   % catch
   %    edge.isConnected = 0;
   %    if flagFail
   %       error('Could not open connection to laser');
   %    else
   %       warning("could not open connection to laser");
   %    end
   % end


end
