function [] = Display_Status(laser)
   % display laser status information
   fprintf(['Connection Status: '  laser.ConnectionStatus '\n']);
   fprintf(['Laser Status: '  laser.Status '\n']);
   fprintf(['Laser Errors: '  laser.ErrorStatus  '\n']);
   fprintf('Laser Current: %2.1fA\n', laser.current);
   fprintf('Trigger Frequency: %4.0f\n', laser.TriggerFrequency);
   fprintf(['Trigger Mode: '  laser.TriggerStatus '\n']);
   fprintf(['Warm Up Status: '  laser.WarmUpStatus '\n']);
end
