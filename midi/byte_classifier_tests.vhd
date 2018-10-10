
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;

entity byte_classifier_tests is
end byte_classifier_tests;

architecture tests of byte_classifier_tests is

	signal RunSim : std_logic := '1';

	signal MidiFrame : std_logic_vector(7 downto 0);
	signal Decoded : decoded_byte;

	constant NoteOn : std_logic_vector(7 downto 0) := "10000011";
	constant NoteOff : std_logic_vector(7 downto 0) := "10010011";
	constant CtrlChange : std_logic_vector(7 downto 0) := "10111110";
	constant SongPosition : std_logic_vector(7 downto 0) := "11110010";
	constant EOX : std_logic_vector(7 downto 0) := "11110111";
	constant TimingClock : std_logic_vector(7 downto 0) := "11111000";
	constant SystemReset : std_logic_vector(7 downto 0) := "11111111";
	constant DataMaxValue : std_logic_vector(7 downto 0) := "01111111";

	procedure ExpectData
	(
		constant AssertParam : in integer;
		signal Decoded : in decoded_byte
	) is
	begin
		wait for 1 ns;
		assert Decoded.FrameType = DATA_FRAME
			report "wrong frame type" severity failure;
		assert to_integer(Decoded.AsParam) = AssertParam
			report "wrong parameter value" severity failure;
	end ExpectData;

	procedure ExpectStatus
	(
		constant AssertType : in frame_type;
		constant AssertChannel : in integer;
		signal Decoded : in decoded_byte
	) is
	begin
		wait for 1 ns;
		assert Decoded.FrameType = AssertType
			report "wrong frame type" severity failure;
		assert to_integer(Decoded.AsChannel) = AssertChannel
			report "wrong channel value" severity failure;

	end ExpectStatus;

	procedure ExpectRealtime
	(
		constant AssertType : in frame_type;
		signal Decoded : in decoded_byte
	) is
	begin
		wait for 1 ns;
		assert Decoded.FrameType = AssertType
			report "wrong frame type" severity failure;
	end ExpectRealtime;

begin

	byte_classifier: entity work.byte_classifier
	port map
	(
		iMidiByte => MidiFrame,
		oDecodedByte => Decoded
	);

	process
	begin
		-- note on
		MidiFrame <= NoteOn;
		ExpectStatus(STATUS_NOTE_ON, 3, Decoded);

		-- note off
		MidiFrame <= NoteOff;
		ExpectStatus(STATUS_NOTE_OFF, 3, Decoded);

		-- timing clock
		MidiFrame <= TimingClock;
		ExpectRealtime(REALTIME_TIMING_CLOCK, Decoded);

		-- control change
		MidiFrame <= CtrlChange;
		ExpectStatus(STATUS_CONTROL_CHANGE, 14, Decoded);

		-- song position
		MidiFrame <= SongPosition;
		ExpectStatus(STATUS_SYSTEM, 2, Decoded);

		-- eox
		MidiFrame <= EOX;
		ExpectStatus(STATUS_SYSTEM, 7, Decoded);

		-- data frame
		MidiFrame <= DataMaxValue;
		ExpectData(127, Decoded);

		-- data frame
		MidiFrame <= SystemReset;
		ExpectRealtime(REALTIME_SYSTEM_RESET, Decoded);

		wait;
	end process;
end tests;
