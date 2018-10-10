
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity event_builder is
	port (
		-- inputs
		iMidiByte : in std_logic_vector(7 downto 0); -- uart frame
		iDataReady : in std_logic;
		iClock : in std_logic;

		-- output events
		oStatusReady : out std_logic;
		oStatus : out status_message;

		-- for debugging
		oIgnoredByte : out std_logic_vector(7 downto 0);
		oIgnoredReady : out std_logic
	);
end event_builder;




architecture etc of event_builder is

	signal IgnoreData : std_logic := '1';
	signal Datums : integer;

	signal WorkingType : frame_type;
	signal NewDecoded : decoded_byte;
	
	procedure NewStatus
	(
		signal iNewType : in frame_type;
		signal iNewChannel : in midi_channel;
		signal oWorkingType : out frame_type;
		signal oIgnoreData : out std_logic;
		signal oDatums : out integer;
		signal oNewStatus : out status_message
	) is
	begin
		oWorkingType <= iNewType;
		oIgnoreData <= '0';
		oDatums <= 0;
		oNewStatus <= (iNewType, iNewChannel, to_midi_param(0), to_midi_param(0));
	end NewStatus;

begin

	process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (iDataReady = '1') then
				case NewDecoded.FrameType is
					when DATA_FRAME =>
						if (IgnoreData = '1') then
							oIgnoredByte <= iMidiByte;
							oIgnoredReady <= '1';
						elsif (Datums = 0) then
							oStatus.Param1 <= NewDecoded.AsParam;
							Datums <= Datums + 1;
							oStatus.Message <= WorkingType;
						else
							oStatus.Param2 <= NewDecoded.AsParam;
							Datums <= 0;
							if (WorkingType = STATUS_NOTE_ON and NewDecoded.AsParam = 0) then
								oStatus.Message <= STATUS_NOTE_OFF;
							end if;
							oStatusReady <= '1';
						end if;

					when STATUS_NOTE_ON =>
						NewStatus(NewDecoded.FrameType, NewDecoded.AsChannel, WorkingType, IgnoreData, Datums, oStatus);

					when STATUS_NOTE_OFF =>
						NewStatus(NewDecoded.FrameType, NewDecoded.AsChannel, WorkingType, IgnoreData, Datums, oStatus);

					when others =>
						oIgnoredByte <= iMidiByte;
						oIgnoredReady <= '1';
						if (NewDecoded.IsRealtimeEvent = '0') then
							IgnoreData <= '1';
						end if;
						
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
		oDecodedByte => NewDecoded
	);

end etc;
