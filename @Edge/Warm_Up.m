

function [] = Warm_Up(laser, doCoolDown, warmUpTime, maxWarmUpCurrent)

   if nargin > 2 % replace default warum up values
      laser.WarmUpTime = warmUpTime;  % warmUpTime [min]
      laser.MaxWarmUpCurrent = maxWarmUpCurrent; % [A]
   elseif nargin <= 1
      doCoolDown = 0; % don't cool down per default
   end

   laser.Read_Error(); %make sure all is good before warming up
   % laser.Display_Status; %get latest current and trigger values

   % calc steps and current values based on time and nSteps
   if ~doCoolDown % do warm up, i.e. don't do cool down duh
      if (laser.current >= laser.MaxWarmUpCurrent)
         fprintf(['[Edge] Laser current (' sprintf('%2.1f A',laser.current) ...
            ') already at or above warmUpCurrent ('...
            sprintf('%2.1f A',laser.MaxWarmUpCurrent) ')!\n']);
         short_warn('[Edge] WarmUp cancled');
         return;
      end
      nWarmUpSteps = laser.WarmUpTime / laser.WarmUpInterval;
      currentStepSize = laser.MaxWarmUpCurrent / nWarmUpSteps;
      % warm up from present current setting in laser
      currentSteps = laser.current:currentStepSize:laser.MaxWarmUpCurrent;
      currentSteps = round(currentSteps * 10) / 10; %round to one digit
      fprintf('[Edge] Warming Up Laser to %2.1fA\n',laser.MaxWarmUpCurrent);
      laser.isOn = 1; % turn laser on if not already on!
      laser.TriggerMode = 1; % make sure we are at externalTrigger
      fprintf('[Edge] Laser will go pew pew, and so should you!');
    else
      % cool down can be faster, given by laser.CoolDownFactor
      nWarmUpSteps = laser.WarmUpTime*laser.CoolDownFactor/laser.WarmUpInterval;
      currentStepSize = laser.current/nWarmUpSteps;
      currentSteps = laser.current:-currentStepSize:0;
      currentSteps = round(currentSteps * 10) / 10; %round to one digit
      fprintf('[Edge] Cooling down laser.');
   end

   if length(currentSteps) > 1
            
      % prepare workspace waitbar
      cpb = ConsoleProgressBar();
      cpb.setLeftMargin(0);
      cpb.setTopMargin(0);
      cpb.setLength(30);
      cpb.setMinimum(1);
      cpb.setMaximum(length(currentSteps));
      cpb.setElapsedTimeVisible(1);
      cpb.setRemainedTimeVisible(1);
      cpb.setElapsedTimePosition('left');
      cpb.setRemainedTimePosition('right');
      cpb.start();
      % start while loop that steps up/down the laser current
      iStep = 1;
      tic;

      % temporarily disable warnings as communication during warm up sometimes
      % failes but never really...
      s = warning; % save old warning state
      warning('off');

      while (iStep <= length(currentSteps))
        % set new laser current if WarmUpInterval passed
        if (toc > laser.WarmUpInterval)
           laserCurrent = currentSteps(iStep); % only read once
           laser.current = laserCurrent;
           dispText = sprintf('%2.1fA/%2.1fA',laserCurrent, laser.MaxWarmUpCurrent);
           cpb.setValue(iStep);
           cpb.setText(dispText);
           tic;
           iStep = iStep + 1;
        end
      end
      cpb.stop();

      warning(s); % restore old warning state
   end


   if ~doCoolDown % we warmed up the laser
      laser.isWarmedUp = 1;
      fprintf('[Edge] Laser warm up successful.\n');
   else
      laser.isOn = 0;
      laser.isWarmedUp = 0;
      fprintf('[Edge] Laser cool down successful.\n');
   end

   laser.TriggerMode = 1; %set to internal trigger mode
   % play a fun sound
   load gong.mat;
   sound(y, Fs);
   clear Fs y;
   % laser.Display_Status;
end
