function [] = Clear_Error(laser)
   % laser errors need to be cleared before laser can be turned on
   fprintf(laser.SerialObj, '%s\n',' w97 101'); %clear laser error
   tic;
   noError = true;
   disp('Checking for new errors...')
   while ((toc < laser.READ_ERROR_WAIT) && noError)
     pause(1); %give laser time to check if error is still there
     laser.Read_Error;
    %  fprintf(1,repmat('\b',1,11));
     noError = isempty(laser.ErrorCodes);
   end
   if noError
     disp('Looks like laser error was cleared!')
   else
     short_warn('Laser Error was not cleared!')
   end
end
