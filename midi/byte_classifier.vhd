
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
		oAsChannel : out unsigned(3 downto 0);
		oAsData : out unsigned(6 downto 0)
	);
end byte_classifier;




architecture etc of byte_classifier is

	signal StatusIndex : integer := 0;
	signal RealtimeIndex : integer := 0;
	signal AsStatus : frame_type;
	signal AsRealtime : frame_type;
	
begin

	StatusIndex <= STATUS_OFFSET + to_integer(unsigned(iMidiByte(6 downto 4)));
	AsStatus <= frame_type'VAL(StatusIndex);
	
	RealtimeIndex <= REALTIME_OFFSET + to_integer(unsigned(iMidiByte(2 downto 0)));
	AsRealtime <= frame_type'VAL(RealtimeIndex);

	oFrameType <= AsRealtime when iMidiByte(7 downto 3) = "11111" else
				  AsStatus when iMidiByte(7) = '1' else
				  DATA_FRAME;

	-- these won't necessarily be valid, check the frame type
	oAsChannel <= unsigned(iMidiByte(3 downto 0));
	oAsData <= unsigned(iMidiByte(6 downto 0));
	
end etc;
