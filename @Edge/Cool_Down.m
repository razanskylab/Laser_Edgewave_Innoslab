function [] = Cool_Down(laser,warmUpTime)
   % cool down laser, behaves like warumUp but different
   % calls the Warm_Up method but with a super secret argument that will
   % cause the laser to cool down instead of warming up...
   % Uses default values for warmUpTime (coolDownTime really...) if not
   % specified by the user
   if nargin > 1 % replace default warum up values
      laser.WarmUpTime = warmUpTime;  % warmUpTime [min]
   end
   laser.Warm_Up(1); % calling warmUp with coolDown functionality
end
