
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;




entity midi_synth is
	generic (
		gClockHz : integer := 1e8 -- 100 mhz
	);
	port (
		-- misc system signals
		iClock : in std_logic;
		iReset : in std_logic; -- assumed to be held high
		
		-- uart interface for midi
		iMidiRxD : in std_logic;
		iMidiFrameError : out std_logic;
		
		-- uart interface for usb logging
		iDebugTxD : out std_logic
	);
end midi_synth;




architecture etc of midi_synth is

	-- constant UART parameters required by midi
	constant BAUD_RATE : 31250;
	constant PARITY_BIT : string := "none";

	-- uart signals
	signal MidiData : std_logic_vector(7 downto 0);
	signal MidiReady : std_logic;
	signal DebugData : std_logic_vector(7 downto 0);
	signal DebugSend : std_logic;
	signal DebugBusy : std_logic;

	-- system reset signal
	signal Reset : std_logic;

begin

	Reset <= not iReset;

	-- midi byte classifier
	entity work.byte_classifier
		port map (
			MidiByte => MidiData
		);

	-- same uart interface for midi and debug for now
	entity work.UART
		generic map (
			CLK_FREQ => gClockHz,
			BAUD_RATE => BAUD_RATE,
			PARITY_BIT => PARITY_BIT
		)
		port map (
			CLK => iClock,
			RST => Reset,
			UART_TXD => iDebugTxD,
			UART_RXD => iMidiRxD,
			DATA_OUT => MidiData,
			DATA_VLD => MidiReady,
			FRAME_ERROR => iMidiFrameError,
			DATA_IN => DebugData,
			DATA_SEND => DebugSend,
			BUSY => DebugBusy
		);

end etc;
