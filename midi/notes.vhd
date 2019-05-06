
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity note_to_frequency is

	port (
		iClock : in std_logic; -- system clock
		iNoteNumber : in midi_param;
		oFrequency : out integer range 8 to 15804
	);

end note_to_frequency;


architecture etc of note_to_frequency is

	signal Period : integer range 0 to 11 := 0;
	signal Octave : integer range -1 to 9 := -1;
	signal BaseFreq : integer range 8372 to 15804 := 8372;
	signal NewFreq : integer range 8 to 15804 := 8;
	type frequency_array is array (0 to 11) of integer range 8372 to 15804;
	constant BaseFrequencies : frequency_array := (
		8372, -- midi 120, C9
		8869,
		9397,
		9956,
		10548,
		11175,
		11839,
		12543, -- midi 127, G9
		13289,
		14080,
		14917,
		15804 -- B9
	);

begin
	advance: process (iClock)
	begin
		if (rising_edge(iClock)) then
			Period <= to_integer(iNoteNumber) mod 12;
			Octave <= 10 - (to_integer(iNoteNumber) / 12);
			BaseFreq <= BaseFrequencies(Period);
			NewFreq <= to_integer(shift_right(to_unsigned(BaseFreq, 14), Octave));
			oFrequency <= NewFreq;
		end if;
	end process;

end architecture;

