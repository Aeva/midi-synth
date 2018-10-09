

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
		oStatusLight : out std_logic
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
	signal StatusMessage : frame_type;
	signal StatusChannel : unsigned(3 downto 0);
	signal StatusParam1 : unsigned(6 downto 0);
	signal StatusParam2 : unsigned(6 downto 0);
	signal IgnoredByte : std_logic_vector(7 downto 0);
	signal IgnoredReady : std_logic := '0';

	signal NoteStatus : std_logic := '0';

begin

	Reset <= not iReset;

	oStatusLight <= not NoteStatus; -- set to ground to turn on the light

	process (iClock)
	begin
		if (rising_edge(iClock)) then
			if (StatusReady = '1' and StatusParam1 = 60) then
				if (StatusMessage = STATUS_NOTE_ON and StatusParam2 > 0) then

					NoteStatus <= '1';
					
				elsif (StatusMessage = STATUS_NOTE_OFF or (StatusMessage = STATUS_NOTE_ON and StatusParam2 = 0)) then

					NoteStatus <= '0';
					
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
		oStatusMessage => StatusMessage,
		oStatusChannel => StatusChannel,
		oStatusParam1 => StatusParam1,
		oStatusParam2 => StatusParam2,
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

end etc;
