classdef Edge < handle
   % Edge class which handles settings of the 532nm super stronk diode laser
   % Currently allows to connect to the laser, control laser current, trigger
   % frequencies, trigger mode, has Warm_Up and Cool_Down methods and can check
   % for errors.
   % ToDo: Implement wavelenght control for SIRAH laser as well...probalby should
   % be renamed to DominateLaser or sth then....

   properties % default properties, probaly most of your data
      WarmUpTime(1,1) {mustBeFinite,mustBeNonnegative} = 60; % [s], duration over which laser slowly warms up on start
      CoolDownFactor(1,1) {mustBeFinite,mustBeNonnegative} = 0.75; % cool down time = WarmUpTime*CoolDownFactor
      MaxWarmUpCurrent(1,1) {mustBeFinite,mustBeNonnegative} = 33; % [A], max current for warm up procedure

      %% laser info
      current(1,1) {mustBeFinite,mustBeNonnegative} = 0; % [A], diode laser current, SET/GET
      power(1,1) {mustBeFinite,mustBeNonnegative} = 0; % [%], set laser power in percent rather than amps, to unify laser control
      TriggerFrequency(1,1) {mustBeInteger,mustBeNonnegative} = 500; % trigger freq. for internal triggering, SET/GET
      TriggerMode(1,1) {mustBeInteger,mustBeNonnegative} = 0; % 0 = internal, 1 = external, 2 = CW. SET/GET
      isOn(1,1); % Edge.isOn = 1 turns on laser. SET/GET
   end

   properties (Constant) % can only be changed here in the def file
      %set max laser current using laser.Write_Command(['w67 ' num2str(laser.CURRENT_SAFETY_LIMIT)])
      CURRENT_SAFETY_LIMIT = 60; %[A], not possible to set higher laser current
      READ_ERROR_WAIT = 5; % time in seconds to re-read laser error after clearing
   end

   properties (Constant, Access = private) % can't be changed, can't be seen
      BAUD_RATE = 57600;  % BaudRate as bits per second
      TERMINATOR = 'CR/LF'; % carriage return + linefeed termination
      TIME_OUT = 2 ; %[s], serial port communication timenout
      TRIG_LIMIT = [200 15000]; % min and max limits of trigger freq.
      CONNECT_ON_STARTUP = true;
   end

   properties (Dependent) %callulated based on other values
   end

   properties (GetAccess=private) % can't be seen but can be set by user
   end

   properties (SetAccess=private) % can be seen but not set by user
      COM_PORT = 'COM5'; % com port of diode laser ("USB Serial Port" in Device manager)
      SerialObj; % serial port object, required for Matlab to laser comm.
      ConnectionStatus = 'Connection Closed';  % Connection stored as text
      isConnected = 0; % Connection stored as logical
      WarmUpStatus = ['Requires warm up'... % WarmUpStatus stored as text
       '(use Warm_Up method)'];
      isWarmedUp = 0;
      Status = 'No On/Off information availabe, use Read_Status method!'; % ON/OFF status
      TriggerStatus = ['No trigger information'... % triggerstatus stored as text here
          'availabe, use Read_Status method!'];
      ErrorStatus  = ['No error information availabe,'... % error stored as text here
         ' use Read_Error method!'];
      ErrorCodes; % errors stored as codes here
   end

   % can't be seen or set by user, only by methods in this class
   properties (Access=private)
      SerialNumber; %used to check connection to correct device, i.e. laser
      WarmUpInterval = 0.5; %[s], interval in which laser current is increased
                           % during warm and up/cool procedures
   end

   properties (Hidden=true)
      outTarget = 1;
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% "Standard" methods, i.e. functions which can be called by the user and by
   % the class itself
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods
      % constructor, called when class is created
      function Edge = Edge(doConnect)

        % constructor, called when creating instance of this class
        if nargin == 0
          doConnect = Edge.CONNECT_ON_STARTUP; % use default setting
        end

        % try to read serial port from file
        if isfile(get_path('com_file'))
          load(get_path('com_file'), 'port_edge');
          Edge.COM_PORT = port_edge;
        else % file does not exist, we need to search for com port
          Edge.Find_Com_Port();
        end

        % auto connect on creation?
        if doConnect
          % try to connect to edge
          try
            Edge.Open_Connection();
          catch ME % if not working, Fin_Com_Port and retry
            Edge.Find_Com_Port();
            Edge.Open_Connection();
          end

        else
          fprintf(Edge.outTarget,'[Edge] Initialized but not connected yet.\n');
        end
      end

      % Destructor: Mainly used to close the serial connection correctly
      function delete(EL)
        % Close Serial connection
        if EL.isConnected
          EL.Close_Connection();
        end
      end

      % when saved, hand over only properties stored in saveObj
      function SaveObj = saveobj(EL)
        % only save public properties of the class if you save it to mat file
        % without this saveobj function you will create an error when trying
        % to save this class
        % SaveObj.vel = EC.vel;
        % SaveObj.pos = EC.pos;
        SaveObj = [];
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Property Set functions are down here...
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function set.MaxWarmUpCurrent(laser,current)
         if current > laser.CURRENT_SAFETY_LIMIT
            error(['The maximum warm up current (' num2str(current) ...
               ' A) is VERY high and exceeds the current safety limit' ...
               'of ' num2str(laser.CURRENT_SAFETY_LIMIT) ' A!']);
         else
            laser.MaxWarmUpCurrent = current;
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function set.current(laser, current)
         %saftey limit check
         if ((current > laser.CURRENT_SAFETY_LIMIT) || (current < 0))
            error(['Setting a laser current of' num2str(current) ' A ' ...
               ' exceeds the safety limit of ' ...
               num2str(laser.CURRENT_SAFETY_LIMIT) 'A !']);
            return;
         end
         laser.Write_Command(['w61 ' num2str(current)]);
         laser.current = current;
      end

      function current = get.current(laser)
         % read current from laser
         tempString = laser.Read_Command('r61');
         current = cell2mat(textscan(tempString,'%f'));
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function set.power(laser, setPower)
        if isinf(setPower)
          % little trick where we don't change the power when we set it to inf
        elseif setPower > 100 || setPower < 0
          error('Need to set power in percent (0-100%)!');
        else
          % set laser power in percent, relative to max current
          current = laser.CURRENT_SAFETY_LIMIT*(setPower./100);
          laser.current = current;
          laser.power = setPower;
        end
      end

      function power = get.power(laser)
        current = laser.current;
        power = current./laser.CURRENT_SAFETY_LIMIT.*100;
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function set.TriggerFrequency(laser, frequency)
         %saftey limit check
         if ((frequency < laser.TRIG_LIMIT(1)) || (frequency > laser.TRIG_LIMIT(2)))
            error('Internal trigger rate out of limits [200 15000]!');
            return;
         end
         laser.Write_Command(['w73 ' num2str(frequency)]);
         laser.TriggerFrequency = frequency;
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function triggerFrequency = get.TriggerFrequency(laser)
         % read laser trigger frequency from laser
         tempString = laser.Read_Command('r73');
         % find numbers of form xxx.xxx
         tempCell = regexp(tempString, '\d*[.]\d*', 'match');
         % regexp returns cells, turn into number
         triggerFrequency = str2num(cell2mat(tempCell));
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function set.TriggerMode(laser, triggerMode)
         % If internal Trigger mode is activated a trigger signal
         % is generated internal and used for trigger
         % If external trigger mode is activated (command w71 1) this set point
         % should be the maximum frequency used during operation. The value is
         % used for internal settings for the first pulse suppression.
         switch triggerMode
            case 0
               laser.TriggerStatus = 'Internal Trigger';
               laser.Write_Command('w70 1');
            case 1 % external trigger,
               laser.TriggerStatus = 'External Trigger';
               laser.Write_Command('w70 0');
               laser.Write_Command('w71 1');
            case 2 % CW trigger mode
               laser.TriggerStatus = 'CW Trigger';
               laser.Write_Command('w70 0');
               laser.Write_Command('w71 2');
            otherwise
               error('Unknown Trigger Mode');
               return;
         end
      end

      function triggerMode = get.TriggerMode(laser)
         intTriggerMode = laser.Read_Command('r70');
         disp(['Internal Trigger Mode: ' intTriggerMode]);
         extTriggerMode = laser.Read_Command('r71');
         disp(['External Trigger Mode: ' extTriggerMode]);
         triggerMode = -1;
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function set.isOn(laser,laserOn)
         % turn laser on/off when setting the Edge.isOn property
         if (laserOn) % turn on the laser
            % check for laser errors
            if ~strcmp(laser.ErrorStatus ,'[Edge] No Errors!')
               error(['Laser error ' laser.ErrorStatus  ...
                  ' occured, fix it and try again!']);
            end
            laser.Write_Command('w60 1');
            laser.Status = 'Laser ON, PEW PEW';
            laser.isOn = 1;
         else
            laser.Write_Command('w60 0');
            laser.Status = 'Laser Off :-(';
            laser.isOn = 0;
         end
         laser.isOn = laserOn;
      end

      function laserIsOn = get.isOn(laser)
         % check if laser is on
         laserIsOn = laser.Read_Command('r60');
         if laserIsOn
            laser.Status = 'ON';
         else
            laser.Status = 'OFF';
         end
      end

      function status = get.Status(laser)
         % check if laser is on and set laser.status
         status = laser.isOn;
      end
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Private Methods, can only be called from methods in the class itself
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods(Access=public) % FIXME: Sure that we do not need private here?
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function [laserAnswer] = Read_Command(laser,command)
         % send a command to the laser and return the answer string
         % possible commands:
         % r01 = ask for SN of laser
         fprintf(laser.SerialObj,'%s\n',command);
         laserAnswer = fscanf(laser.SerialObj,'%s\n');
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      function [] = Write_Command(laser,command)
         % send a command to the laser
         % possible commands:
         % w60 0/1 - Laser on/off
         % w61 0-50 - Laser driving current
         % w67 0-60 - set upper laser current limit
         fprintf(laser.SerialObj,'%s\n',command);
         returnMessage = fscanf(laser.SerialObj,'%s\n');
         if ~strcmp(returnMessage,'OK')
            warning('Writing laser command failed!');
            fprintf(['Laser Message was: "' returnMessage '"\n']);
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Private Get Access methods, i.e. they can be called by the user but
   % only if the use knows they exist and knows their name
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods(Hidden)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       function [] = Set_Pulse_Energy(laser)
%          %% for later, when have an automatic power calibration
%       end

   end

   %static methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % These methods do not perform operations on individual objects of a
   % class and, therefore, do not require an instance of the class as an
   % input argument, like ordinary methods
   methods(Static)
      % function p = Get_Pi(tol)
      %    p = 0;
      % end
   end

end
