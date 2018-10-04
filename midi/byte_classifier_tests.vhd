
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;

entity byte_classifier_tests is
end byte_classifier_tests;

architecture tests of byte_classifier_tests is

	signal RunSim : std_logic := '1';

	signal MidiFrame : std_logic_vector(7 downto 0);
	signal FrameType : frame_type;
	signal AsStatusMessage : status_message;
	signal AsRealtimeMessage : realtime_message;
	signal AsChannel : unsigned(3 downto 0);
	signal AsData : unsigned(6 downto 0);

	constant NoteOn : std_logic_vector(7 downto 0) := "10000011";
	constant NoteOff : std_logic_vector(7 downto 0) := "10010011";
	constant CtrlChange : std_logic_vector(7 downto 0) := "10111110";
	constant SongPosition : std_logic_vector(7 downto 0) := "11110010";
	constant EOX : std_logic_vector(7 downto 0) := "11110111";
	constant TimingClock : std_logic_vector(7 downto 0) := "11111000";
	constant SystemReset : std_logic_vector(7 downto 0) := "11111111";
	constant DataMaxValue : std_logic_vector(7 downto 0) := "01111111";
begin

	byte_classifier: entity work.byte_classifier
	port map
	(
		iMidiByte => MidiFrame,
		oFrameType => FrameType,
		oAsStatusMessage => AsStatusMessage,
		oAsRealtimeMessage => AsRealtimeMessage,
		oAsChannel => AsChannel,
		oAsData => AsData
	);

	process
	begin
		-- note on
		MidiFrame <= NoteOn;
		wait for 1 ns;
		assert FrameType = FRAME_STATUS
			report "wrong frame type" severity failure;
		assert AsStatusMessage = STATUS_NOTE_ON
			report "wrong status message type" severity failure;
		assert AsChannel = 3
			report "wrong channel value" severity failure;

		-- note off
		MidiFrame <= NoteOff;
		wait for 1 ns;
		assert FrameType = FRAME_STATUS
			report "wrong frame type" severity failure;
		assert AsStatusMessage = STATUS_NOTE_OFF
			report "wrong status message type" severity failure;
		assert AsChannel = 3
			report "wrong channel value" severity failure;

		-- timing clock
		MidiFrame <= TimingClock;
		wait for 1 ns;
		assert FrameType = FRAME_REALTIME
			report "wrong frame type" severity failure;
		assert AsRealtimeMessage = REALTIME_TIMING_CLOCK
			report "wrong system realtime message type" severity failure;

		-- control change
		MidiFrame <= CtrlChange;
		wait for 1 ns;
		assert FrameType = FRAME_STATUS
			report "wrong frame type" severity failure;
		assert AsStatusMessage = STATUS_CONTROL_CHANGE
			report "wrong status message type" severity failure;
		assert AsChannel = 14
			report "wrong channel value" severity failure;

		-- song position
		MidiFrame <= SongPosition;
		wait for 1 ns;
		assert FrameType = FRAME_STATUS
			report "wrong frame type" severity failure;
		assert AsStatusMessage = STATUS_SYSTEM
			report "wrong status message type" severity failure;

		-- eox
		MidiFrame <= EOX;
		wait for 1 ns;
		assert FrameType = FRAME_STATUS
			report "wrong frame type" severity failure;
		assert AsStatusMessage = STATUS_SYSTEM
			report "wrong status message type" severity failure;

		-- data frame
		MidiFrame <= DataMaxValue;
		wait for 1 ns;
		assert FrameType = FRAME_DATA
			report "wrong frame type" severity failure;
		assert AsData = 127
			report "wrong data value" severity failure;

		-- data frame
		MidiFrame <= SystemReset;
		wait for 1 ns;
		assert FrameType = FRAME_REALTIME
			report "wrong frame type" severity failure;
		assert AsRealtimeMessage = REALTIME_SYSTEM_RESET
			report "wrong system realtime message type" severity failure;

		wait for 10 sec;
	end process;
end tests;
