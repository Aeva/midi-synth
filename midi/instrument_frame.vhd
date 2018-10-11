
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity instrument_frame is
	port (
		iClock : in std_logic;
		iStatusReady: in std_logic;
		iStatus : in status_message;
		oVoiceArray : out voice_array;
		oVoiceCount : out natural;
	);
end instrument_frame;


architecture etc of instrument_frame is

	signal VoiceArray : voice_array;
	signal VoiceCount : natural := 0;

	signal DeleteIndex : natural;
	signal DoDelete : std_logic := 0;

begin

	oVoiceArray <= VoiceArray;
	oVoiceCount <= VoiceCount;

	process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (iStatusReady = '1') then
				if (Status.Message = STATUS_NOTE_ON and voice_count < POLYPHONY) then
					-- new note, and we have space for it!
					VoiceArray(VoiceCount) <=
					(
						active => '1',
						expired => '0',
						since_press => 0,
						since_release => 0,
						program => 0,
						key => to_integer(Status.Param1),
						strike => to_integer(Status.Param2)
					);
					VoiceCount = VoiceCount + 1;


				elsif (Status.Message = STATUS_NOTE_OFF) then
					-- key was released, see if we're tracking it and
					-- mark it accordingly
					for v in 0 to POLYPHONY -1 loop
						if (VoiceArray(v).key = to_integer(Status.Param1)) then
							VoiceArray(v).active <= '0';

							-- ideally something else would determine
							-- when the voice has finished playing and
							-- can be deleted, but I'm not sure where
							-- that fits right now
							VoiceArray(v).expired <= '1';
						end if;
					end if;


				end if;
			elsif (VoiceCount > 0) then
				if (DoDelete = '1') then
					-- Compact the list.  Ignore the last element; if
					-- it is the deleted element, then it is fine to
					-- leave it where it is.
					for v in 0 to POLYPHONY - 2 loop
						if (v < DeleteIndex) then
							VoiceArray(v) <= VoiceArray(v);
						else
							VoiceArray(v) <= VoiceArray(v+1);
						end if;
					end for;
					DoDelete = '0';


				else
					-- mark new voices for deletion
					for v in POLYPHONY - 1 downto 0 loop
						if (VoiceArray(v).expired = '1') then
							DoDelete <= '1';
							DeleteIndex <= v;
						end if;
					end for;
				end if;
			end if;
		end if;
	end process;

end etc;
