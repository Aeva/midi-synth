
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity event_builder is
	port (
		-- inputs
		iMidiByte : in std_logic_vector(7 downto 0); -- uart frame
		iDataReady : std_logic;
		iClock : std_logic;

		-- output events
		oStatusReady : out std_logic;
		oStatusMessage : out frame_type;
		oStatusChannel : out unsigned(3 downto 0);
		oStatusParam1 : out unsigned(6 downto 0);
		oStatusParam2 : out unsigned(6 downto 0);

		-- for debugging
		oIgnoredByte : out std_logic_vector(7 downto 0);
		oIgnoredReady : out std_logic
	);
end event_builder;




architecture etc of event_builder is

	signal IgnoreData : std_logic := '1';
	signal Datums : integer;

	signal NewType : frame_type;
	signal NewAsChannel : unsigned(3 downto 0);
	signal NewAsData : unsigned(6 downto 0);
	signal NewIsStatus : std_logic;

begin

	NewIsStatus <= '1' when frame_type'POS(NewType) < REALTIME_OFFSET else '0';

	process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (iDataReady = '1') then
				case NewType is
					when DATA_FRAME =>
						if (IgnoreData = '1') then
							oIgnoredByte <= iMidiByte;
							oIgnoredReady <= '1';
						elsif (Datums = 0) then
							oStatusParam1 <= NewAsData;
							Datums <= Datums + 1;
						else
							oStatusParam2 <= NewAsData;
							Datums <= 0;
							oStatusReady <= '1';
						end if;

					when STATUS_NOTE_ON =>
						IgnoreData <= '0';
						Datums <= 0;
						oStatusMessage <= NewType;
						oStatusChannel <= NewAsChannel;

					when STATUS_NOTE_OFF =>
						IgnoreData <= '0';
						Datums <= 0;
						oStatusMessage <= NewType;
						oStatusChannel <= NewAsChannel;

					when others =>
						oIgnoredByte <= iMidiByte;
						oIgnoredReady <= '1';
						IgnoreData <= NewIsStatus;
						
				end case;
			else
				oIgnoredReady <= '0';
				oStatusReady <= '0';
			end if;
		end if;
	end process;


	midi_byte_classifier : entity work.byte_classifier
	port map (
		iMidiByte => iMidiByte,
		oFrameType => NewType,
		oAsChannel => NewAsChannel,
		oAsData => NewAsData
	);

end etc;
