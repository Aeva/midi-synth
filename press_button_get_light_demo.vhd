
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity press_button_get_light is
	generic (
		gClockHz : integer := 1e8 -- 100 mhz
	);

	port (
		-- misc system signals
		iClock : in std_logic;
		iReset : in std_logic; -- assumed to be held high
		
		-- uart interface for midi
		iMidiRxD : in std_logic;

		-- indicator light
		oStatusLights : out std_logic_vector(3 downto 0);
		
		-- switch bank
		iSwitches : in std_logic_vector(3 downto 0);

		-- I2S DAC test
		oI2sData : out std_logic;
        oI2sBitClock : out std_logic;
        oI2sWorldClock : out std_logic;
		oI2sShutdown : out std_logic
	);
end press_button_get_light;


architecture etc of press_button_get_light is
	
	-- constant UART parameters required by midi
	constant BAUD_RATE : integer := 31250;
	constant PARITY_BIT : string := "none";

	-- uart rx signals (used for midi)
	signal MidiData : std_logic_vector(7 downto 0);
	signal MidiReady : std_logic;
	signal MidiFrameError : std_logic;

	-- uart tx signals (unused)
	signal DebugTxD : std_logic;
	signal DebugData : std_logic_vector(7 downto 0);
	signal DebugSend : std_logic := '0';
	signal DebugBusy : std_logic := '0';

	-- system reset signal
	signal Reset : std_logic;

	-- midi event signals
	signal StatusReady : std_logic := '0';
	signal Status : status_message;
	signal IgnoredByte : std_logic_vector(7 downto 0);
	signal IgnoredReady : std_logic := '0';
	
	-- I2S DAC test signal
    signal Message : signed(31 downto 0) := to_signed(0, 32);
    constant SAMPLING_HZ : integer := 44100;

	-- basic midi instrument
    constant BASE_MULTIPLIER : integer := 262144; -- (2**18)
    signal VolumeMultiplier : integer := 0;
    signal LastNote : midi_param := to_midi_param(0);
    signal NoteHz : integer range 8 to 15804 := 0;
    signal NoteVolume : integer := 0;

	-- voice pool
	constant POLYPHONY : integer := 6;
	constant POLYPHONY_END : integer := POLYPHONY - 1;

	type voice_state is record
		MidiNote : midi_param;
		Frequency : integer range 8 to 15804;
		Volume : integer;
		Sample : signed(31 downto 0);
	end record;

	type voice_state_array is array (0 to POLYPHONY_END) of voice_state;
	signal VoicePool : voice_state_array;
	signal NextVoice : integer range 0 to POLYPHONY_END := 0;
	signal LastVoice : integer range 0 to POLYPHONY_END := 0;

	signal MessageSum : signed(31 downto 0) := to_signed(0, 32);
	signal SumIndex : integer range 0 to POLYPHONY := 0;

begin

	Reset <= not iReset;
	oStatusLights <= iSwitches;
	
	oI2sShutdown <= iReset;

	VolumeMultiplier <= to_integer(unsigned(iSwitches));

	voice_combiner: process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (Reset = '1') then
				SumIndex <= 0;
				Message <= to_signed(0, 32);
				MessageSum <= to_signed(0, 32);
			elsif (SumIndex = POLYPHONY) then
				-- loop one index past the end before resetting
				Message <= MessageSum;
				MessageSum <= to_signed(0, 32);
				SumIndex <= 0;
			else
				if (VoicePool(SumIndex).Volume > 0) then
					MessageSum <= MessageSum + VoicePool(SumIndex).Sample;
				end if;
				SumIndex <= SumIndex + 1;
			end if;
		end if;
	end process;

	midi_listener: process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (Reset = '1') then
				for p in 0 to POLYPHONY_END loop
					VoicePool(p).MidiNote <= to_midi_param(0);
					VoicePool(p).Volume <= 0;
				end loop;
				NextVoice <= 0;
				LastVoice <= 0;
			elsif (StatusReady = '1') then
				if (Status.Message = STATUS_NOTE_OFF) then
					for p in 0 to POLYPHONY_END loop
						if (VoicePool(p).MidiNote = Status.Param1) then
							VoicePool(p).MidiNote <= to_midi_param(0);
							VoicePool(p).Volume <= 0;
						end if;
					end loop;
				elsif (Status.Message = STATUS_NOTE_ON) then
					VoicePool(NextVoice).Volume <= to_integer(Status.Param2) * BASE_MULTIPLIER * (VolumeMultiplier + 1);
					VoicePool(NextVoice).MidiNote <= Status.Param1;
					LastNote <= Status.Param1;
					LastVoice <= NextVoice;
					if (NextVoice = POLYPHONY_END)
					then
						NextVoice <= 0;
					else
						NextVoice <= NextVoice + 1;
					end if;
				end if;
			elsif (VoicePool(NextVoice).Volume > 0) then
				if (NextVoice = POLYPHONY_END)
				then
					NextVoice <= 0;
				else
					NextVoice <= NextVoice + 1;
				end if;
			else
				if (VoicePool(LastVoice).Volume > 0) then
					VoicePool(LastVoice).Frequency <= NoteHz;
				end if;
			end if;
		end if;
	end process;
	

	midi_event_builder: entity work.event_builder
	port map
	(
		iMidiByte => MidiData,
		iDataReady => MidiReady,
		iClock => iClock,
		oStatusReady => StatusReady,
		oStatus => Status,
		oIgnoredByte => IgnoredByte,
		oIgnoredReady => IgnoredReady
	);
	
	uart_interface: entity work.UART
	generic map (
		CLK_FREQ => gClockHz,
		BAUD_RATE => BAUD_RATE,
		PARITY_BIT => PARITY_BIT
	)
	port map (
		CLK => iClock,
		RST => Reset,
		UART_TXD => DebugTxD,
		UART_RXD => iMidiRxD,
		DATA_OUT => MidiData,
		DATA_VLD => MidiReady,
		FRAME_ERROR => MidiFrameError,
		DATA_IN => DebugData,
		DATA_SEND => DebugSend,
		BUSY => DebugBusy
	);

	frequency_finder: entity work.note_to_frequency
	port map (
		iClock => iClock,
		iNoteNumber => LastNote,
		oFrequency => NoteHz
	);
	
	voice_generators: for p in 0 to POLYPHONY_END generate
		voice: entity work.sqrwave
		generic map (
			gClockHz => gClockHz
		)
		port map (
			iClock => iClock,
			iFrequency => VoicePool(p).Frequency,
			iAmplitude => VoicePool(p).Volume,
			oSample => VoicePool(p).Sample
		);
	end generate;
	
	i2s_interface: entity work.i2s
	generic map (
	   gClockHz => gClockHz,
	   gSamplingHz => SAMPLING_HZ
	)
	port map (
	   iClock => iClock,
	   iReset => iReset,
	   oBitClock => oI2sBitClock,
	   oWordClock => oI2sWorldClock,
       oDataLine => oI2sData,
       iLeftChannel => Message,
       iRightChannel => Message
	);

end etc;
