
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity byte_classifier is
	port (
		-- input uart frame
		iMidiByte : in std_logic_vector(7 downto 0);

		-- unpacked information
		oDecodedByte : out decoded_byte
	);
end byte_classifier;




architecture etc of byte_classifier is

	signal StatusIndex : integer := 0;
	signal RealtimeIndex : integer := 0;
	signal TypeIndex : integer := 0;
	signal IsRealtimeEvent : std_logic;
	
begin

	StatusIndex <= STATUS_OFFSET + to_integer(unsigned(iMidiByte(6 downto 4)));
	RealtimeIndex <= REALTIME_OFFSET + to_integer(unsigned(iMidiByte(2 downto 0)));
	TypeIndex <= RealtimeIndex when iMidiByte(7 downto 3) = "11111" else
				 StatusIndex when iMidiByte(7) = '1' else
				 0;
	IsRealtimeEvent <= '1' when TypeIndex >= REALTIME_OFFSET else '0';

	oDecodedByte <= (
		frame_type'VAL(TypeIndex),
		IsRealtimeEvent,
		midi_channel(iMidiByte(3 downto 0)),
		midi_param(iMidiByte(6 downto 0))
	);
	
end etc;
