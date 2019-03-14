function [] = Read_Error(laser)
   %% read error codes from laser
   % error codes behave different than other commands,
   % which is handled here and in the Clear_Error function
   fprintf(laser.SerialObj,'%s\n','r90'); %ask for error codes

   while(~laser.SerialObj.BytesAvailable); %wait for the answer
       pause(0.01);
   end

   laserAnswer = '';
   % need to run while loop since more than one error code
   % can be send for one r90 query
   while(laser.SerialObj.BytesAvailable)
      laserAnswer = [laserAnswer fscanf(laser.SerialObj,'%s\n') ' '];
   end

   % check if laserAnswer strings contains numbers
   errorOccured = any(isstrprop(laserAnswer,'digit'));

   %if no numbers in laserAnswer string, then no errors...
   if errorOccured
      laser.ErrorCodes = textscan(laserAnswer,'%u'); %extract numbers
      laser.ErrorCodes = cell2mat(laser.ErrorCodes);
      laser.ErrorStatus = mat2str(laser.ErrorCodes);
      laser.ErrorStatus = unique(laser.ErrorStatus); % remove duplicates
      for iError = 1:length(laser.ErrorCodes)
         switch laser.ErrorCodes(iError)
            case 73
               short_warn('[Edge] Water flow to low or too high! (Error 73)');
            case 80
               short_warn('[Edge] Dioder laser temp laser 1 incorrect! (Error 80)');
            case 81
               short_warn('[Edge] Dioder laser temp laser 2 incorrect! (Error 81)');
            case 86
               short_warn('[Edge] Oven temperature unstable...wait a minute! (Error 86)');
            case 91
               short_warn('[Edge] Shutter hangs or is blocked! (Error 91)');
            case 92
               short_warn('[Edge] Door was opened! (Error 92)');
            case 93
               short_warn('[Edge] General protection interlock was open! (Error 93!');
            case 94
               short_warn('[Edge] Chiller error! (Error 94)');
            case 95
               short_warn('[Edge] Diode laser current to high! (Error 95!)');
            case 97
               short_warn('[Edge] Temperature sensor defect! (Error 97!)');
            case 98
               short_warn('[Edge] Humidity to high, replace air dryer cartridge! (Error 98!)');
            otherwise
               short_warn(['[Edge] Unknown error code number ', num2str(laser.ErrorCodes(iError)), ' ...what the heck?']);
         end
      end
   else % no errors occured
      laser.ErrorStatus  = '[Edge] No Errors!';
      laser.ErrorCodes = '';
      disp(laser.ErrorStatus);
   end

end
