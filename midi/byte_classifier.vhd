
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;




entity byte_classifier is
	-- TODO: maybe use an enums to communicate byte type, system real time
	-- message, and message type outputs?
	
	port (
		-- input uart frame
		MidiByte : in std_logic_vector(7 downto 0);
		
		-- system real time messages
		IsEvent : out std_logic; -- "MidiByte" is a system realtime messages
		SystemRealTimeMessage : out unsigned(2 downto 0);
		
		-- status message
		IsStatus : out std_logic; -- "MidiByte" is the start of a new status message
		MessageType : out unsigned(2 downto 0);
		Channel : out unsigned(3 downto 0);

		-- data message
		IsData : out std_logic; -- "MidiByte" is a status message data byte
		DataParam : out unsigned(6 downto 0);
	);
end byte_classifier;




architecture etc of byte_classifier is
	
	signal StatusBit : std_logic;
	
begin

	StatusBit <= MidiByte(7);

	-- byte type flag
	IsEvent <= MidiByte(7 downto 3) = "11111";
	IsStatus <= StatusBit = '1' and not IsEvent;
	IsData <= StatusBit = '0';

	-- these won't necessarily be valid, check the above flags
	SystemRealTimeMessage <= unsigned(MidiByte(2 downto 0));
	MessageType <= unsigned(MidiByte(6 downto 4));
	Channel <= unsigned(MidiByte(3 downto 0));
	DataParam <= unsigned(MidiByte(6 downto 0));
	
end etc;
