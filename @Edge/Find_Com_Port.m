% File: Find_Com_Port.m @ Edge
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 30.04.2019

% Description: checks serial connections to determine on which we have an edge

function Find_Com_Port(edge)

	portArray = seriallist(); % get all serial devices as a list
	nDevices = length(portArray); % determine number of serial devices
	flagFound = 0; % flag indicating if we found the device already

	for iDevice = 1:nDevices % for each serial port
		disp("test")
		if (flagFound == 0) % only do this if we did not find edge yet
			try
				obj = serialport(portArray(iDevice), edge.BAUD_RATE, ...
					"Timeout", 2); % create serial port
				configureTerminator(obj, edge.TERMINATOR); % set terminator
				writeline(obj, 'r01');
				pause(0.1);
				response = readline(obj) % scan for serial number
				if strcmp(response(1:4), 'S/N:') % if it starts with S/N: we have an edgewave
					port_edge = portArray(iDevice);
					flagFound = 1;
				end
			catch ME
				% nothing 
			end
		end
	
	end

	% if we found the correct com port
	if flagFound
		edge.COM_PORT = port_edge;
		if isfile(get_path('com_file')) % if file exists
			save(get_path('com_file'), 'port_edge', '-append');
		else
			save(get_path('com_file'), 'port_edge');
		end
	else % otherwise throw error
		error('None of the connected devices seems to be an Edgewave.');
	end

end