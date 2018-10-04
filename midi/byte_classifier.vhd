
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity byte_classifier is
	port (
		-- input uart frame
		iMidiByte : in std_logic_vector(7 downto 0);

		-- unpacked information
		oFrameType : out frame_type;
		oAsStatusMessage : out status_message;
		oAsRealtimeMessage : out realtime_message;
		oAsChannel : out unsigned(3 downto 0);
		oAsData : out unsigned(6 downto 0)
	);
end byte_classifier;




architecture etc of byte_classifier is

	signal StatusIndex : integer := 0;
	signal RealtimeIndex : integer := 0;
	
begin

	StatusIndex <= to_integer(unsigned(iMidiByte(6 downto 4)));
	RealtimeIndex <= to_integer(unsigned(iMidiByte(2 downto 0)));

	oFrameType <= FRAME_REALTIME when iMidiByte(7 downto 3) = "11111" else
				  FRAME_STATUS when iMidiByte(7) = '1' else
				  FRAME_DATA;

	-- these won't necessarily be valid, check the frame type
	oAsStatusMessage <= status_message'VAL(StatusIndex);
	oAsRealtimeMessage <= realtime_message'VAL(RealtimeIndex);
	oAsChannel <= unsigned(iMidiByte(3 downto 0));
	oAsData <= unsigned(iMidiByte(6 downto 0));
	
end etc;
