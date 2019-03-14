% Open_Connection @ Edge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Open_Connection(laser)
   % open serial connection to laser on COM_PORT, creates serial obj
   % also displays laser status
  fprintf('[Edge] Openning serial connection...\n');

   % add serachpath to where waitbar fct
   addpath(genpath('C:\Joe_PAM\00_WorkCode\00_general_utility'));
   laser.SerialObj = instrfind('Type', 'serial', 'Port', laser.COM_PORT);

   % Create the serial port object if it does not exist
   % otherwise use the object that was found.
   if isempty(laser.SerialObj)
       laser.SerialObj = serial(laser.COM_PORT);
   else
       fclose(laser.SerialObj);
       laser.SerialObj = laser.SerialObj(1);
   end

   % setup serial connection correctly
   set(laser.SerialObj, 'BaudRate', laser.BAUD_RATE);
   set(laser.SerialObj, 'Terminator',laser.TERMINATOR);
   set(laser.SerialObj, 'Timeout', laser.TIME_OUT);

   fopen(laser.SerialObj); % Connect to laser

   laser.SerialNumber = Read_Command(laser,'r01');
   isCorrectLaser = strcmp(laser.SerialNumber,'S/N:1639');
   connectionIsOpen = strcmp(laser.SerialObj.Status,'open');
   if (connectionIsOpen && isCorrectLaser)
      laser.ConnectionStatus = 'Connected';
      laser.isConnected = 1;
      % disp(laser.ConnectionStatus);
      fprintf('[Edge] Laser connection established!\n');
   else
      disp('[Edge] Connection NOT established!');
      disp(['[Edge] isCorrectLaser: ' num2str(isCorrectLaser)]);
      disp(['[Edge] Serial number: ' laser.SerialNumber])
      disp(['[Edge] connectionIsOpen: ' num2str(connectionIsOpen)]);
      return;
   end
   laser.Read_Error;
   % laser.Display_Status;
end
