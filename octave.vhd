
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


-- midi note numbers range from C-1 to G-9
-- this doesn't divide cleanly into full octaves, so if we say an octave starts
-- at C, then the C for the highest full octave is 108.  Which might be out of
-- range for my keyboard anyway.

-- So with that in mind, we'll just hard code the frequencies for the top-most
-- octave, and right shift by the number of octaves to get the remaining ones.

-- So:
-- |------+------+------|
-- | midi | note | ferq |
-- |------+------+------|
-- |  108 |  C8  | 4186 |
-- |  109 |  C#8 | 4434 |
-- |  110 |  D8  | 4698 |
-- |  111 |  D#8 | 4978 |
-- |  112 |  E8  | 5274 |
-- |  113 |  F8  | 5587 |
-- |  114 |  F#8 | 5919 |
-- |  115 |  G8  | 6271 |
-- |  116 |  G#8 | 6644 |
-- |  117 |  A8  | 7040 |
-- |  118 |  A#8 | 7458 |
-- |  119 |  B8  | 7902 |
-- |------+------+------|


entity Key is
	generic (
		gClockHz : integer := 1e8; -- 100 mhz
		gMidiNumber : integer := 69;
		gFrequency : integer := 440; -- hz
		gMaxVolume : integer := 0
	);
	port (
		iClock : in std_logic; -- system clock
		iReset : in std_logic; -- assumed to be held high
		iStatusReady : in std_logic;
		iStatus : in status_message;
		oMessage : out signed(31 downto 0);
		oActive : out std_logic
	);
end entity;


architecture etc of Key is

	constant FREQUENCY_DIV : integer := gClockHz / gFrequency;
	signal NoteVolume : signed(31 downto 0) := to_signed(0, 32);
		
begin

	midi_listener: process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (iReset = '0') then
				NoteVolume <= to_signed(0, NoteVolume'length);
				oActive <= '0';
			elsif (iStatusReady = '1' and to_integer(iStatus.Param1) = gMidiNumber) then
				if iStatus.Message = STATUS_NOTE_ON then
					NoteVolume <= to_signed(gMaxVolume, NoteVolume'length);
				elsif iStatus.Message = STATUS_NOTE_OFF then
					NoteVolume <= to_signed(0, NoteVolume'length);
				end if;
				if NoteVolume = 0 then
				    oActive <= '0';
				else
				    oActive <= '1';
				end if;
			end if;
		end if;
	end process;

	tone_generator: entity work.sqrwave
	port map (
	   iClock => iClock,
	   iFrequency => FREQUENCY_DIV,
	   iAmplitude => to_integer(NoteVolume),
	   oSample => oMessage
	);
	
end architecture;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity Octave is
	generic (
		gClockHz : integer := 1e8; -- 100 mhz
		gMidiOctave : integer range 0 to 9 := 0; -- zero through 9
		gMaxVolume : integer := 0
	);
	port (
		iClock : in std_logic; -- system clock
		iReset : in std_logic; -- assumed to be held high
		iStatusReady : in std_logic;
		iStatus : in status_message;
		oMessage : out signed(31 downto 0)
	);
end entity;


architecture etc of Octave is
	
	constant OCTAVE_FREQ_SHIFT : integer := 9 - gMidiOctave;
	constant OCTAVE_START_NOTE : integer := 12 * gMidiOctave;

	type frequencies_array is array (0 to 11) of integer;
	constant BASE_FREQUENCIES : frequencies_array := (
		4186, -- C8
		4434, -- C#8
		4698, -- D8
		4978, -- D#8
		5274, -- E8
		5587, -- F8
		5919, -- F#8
		6271, -- G8
		6644, -- G#8
		7040, -- A8
		7458, -- A#8
		7902  -- B8
	);

	type volumes_array is array (0 to 11) of signed(31 downto 0);
	signal KeySamples : volumes_array;
	signal KeyStates : std_logic_vector(11 downto 0);
	
begin

	process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (KeyStates(0) = '1') then
				oMessage <= KeySamples(0);
			elsif (KeyStates(1) = '1') then
				oMessage <= KeySamples(1);
			elsif (KeyStates(2) = '1') then
				oMessage <= KeySamples(2);
			elsif (KeyStates(3) = '1') then
				oMessage <= KeySamples(3);
			elsif (KeyStates(4) = '1') then
				oMessage <= KeySamples(4);
			elsif (KeyStates(5) = '1') then
				oMessage <= KeySamples(5);
			elsif (KeyStates(6) = '1') then
				oMessage <= KeySamples(6);
			elsif (KeyStates(7) = '1') then
				oMessage <= KeySamples(7);
			elsif (KeyStates(8) = '1') then
				oMessage <= KeySamples(8);
			elsif (KeyStates(9) = '1') then
				oMessage <= KeySamples(9);
			elsif (KeyStates(10) = '1') then
				oMessage <= KeySamples(10);
			elsif (KeyStates(11) = '1') then
				oMessage <= KeySamples(11);
			else
			    oMessage <= to_signed(0, oMessage'length);
			end if;
		end if;
	end process;
		
	key_generator: for K in 0 to 11 generate
		constant NOTE_NUMBER : integer := OCTAVE_START_NOTE + K;
		constant BASE_FREQUENCY : unsigned(11 downto 0) := to_unsigned(BASE_FREQUENCIES(K), 12);
		constant FREQUENCY : integer := to_integer(shift_right(BASE_FREQUENCY, OCTAVE_FREQ_SHIFT));
	begin
		generated_key: entity work.Key
		generic map (
			gClockHz => gClockHz,
			gMidiNumber => NOTE_NUMBER,
			gFrequency => to_integer(BASE_FREQUENCY),
			gMaxVolume => gMaxVolume
		)
		port map (
			iClock => iClock,
			iReset => iReset,
			iStatusReady => iStatusReady,
			iStatus => iStatus,
			oMessage => KeySamples(K),
			oActive => KeyStates(K)
		);
	end generate;
	
end architecture;

