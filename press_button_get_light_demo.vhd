

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

	signal NoteStatus : std_logic_vector(3 downto 0) := "0000";
	
	-- I2S DAC test signal
    signal Message : signed(31 downto 0) := to_signed(0, 32);
    signal Sample : integer := 2147483647;
    signal ToneCounter : integer := 0;
    constant SAMPLING_HZ : integer := 44100;

begin

	Reset <= not iReset;

	oStatusLights <= not NoteStatus; -- set to ground to turn on the light
	
	oI2sShutdown <= '1'; -- always on
	
	Message <= to_signed(Sample, Message'length);
	
	tone_generator: process (iClock)
	begin
	   if (rising_edge(iClock)) then
	       if (ToneCounter = 227272) then -- 440 hz
			   --Message(31) <= not Message(31);
			   Sample <= Sample * (-1);
	           ToneCounter <= 0;
	       else
	           ToneCounter <= ToneCounter + 1;
	       end if;
	   end if;
	end process;

	midi_listener: process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (Reset = '1') then
				NoteStatus <= "0000";
			elsif (StatusReady = '1') then
				case Status.Message is
					when STATUS_NOTE_ON =>
						case to_integer(Status.Param1) is
							when 60 =>
								NoteStatus(0) <= '1';
							when 62 =>
								NoteStatus(1) <= '1';
							when 64 =>
								NoteStatus(2) <= '1';
							when 65 =>
								NoteStatus(3) <= '1';
							when others =>
						end case;
					when STATUS_NOTE_OFF =>
						case to_integer(Status.Param1) is
							when 60 =>
								NoteStatus(0) <= '0';
							when 62 =>
								NoteStatus(1) <= '0';
							when 64 =>
								NoteStatus(2) <= '0';
							when 65 =>
								NoteStatus(3) <= '0';
							when others =>
						end case;
					when others =>
				end case;
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
	
	i2s_interface: entity work.i2s
	generic map (
	   gClockHz => gClockHz,
	   gSamplingHz => SAMPLING_HZ
	)
	port map (
	   iClock => iClock,
	   oBitClock => oI2sBitClock,
	   oWordClock => oI2sWorldClock,
       oDataLine => oI2sData,
       iLeftChannel => Message,
       iRightChannel => Message
	);

end etc;
