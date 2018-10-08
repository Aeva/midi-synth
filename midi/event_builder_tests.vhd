
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;
use work.midi_test_helper.all;

entity event_builder_tests is
end event_builder_tests;

architecture tests of event_builder_tests is

	signal MidiByte : std_logic_vector(7 downto 0);
	signal MidiReady : std_logic := '0';
	signal Clock : std_logic := '0';

	signal StatusReady : std_logic := '0';
	signal StatusMessage : frame_type;
	signal StatusChannel : unsigned(3 downto 0);
	signal StatusParam1 : unsigned(6 downto 0);
	signal StatusParam2 : unsigned(6 downto 0);

	signal IgnoredByte : std_logic_vector(7 downto 0);
	signal IgnoredReady : std_logic := '0';

	constant NoteOn : std_logic_vector(7 downto 0) := "10000000";
	constant NoteOff : std_logic_vector(7 downto 0) := "10010000";
	
	constant MiddleC : std_logic_vector(7 downto 0) := "00111100";
	constant AnotherNote : std_logic_vector(7 downto 0) := "00111000";
	
	constant ZeroVelocity : std_logic_vector(7 downto 0) := "00000000";
	constant LowishVelocity : std_logic_vector(7 downto 0) := "00001101";
	constant HighishVelocity : std_logic_vector(7 downto 0) := "01100110";

	-- I currently have no intention to implement system common
	-- messages, so receiving one should put the builder into an
	-- ignore state.  "Song Position" should receive two data bytes.  The ones
	-- given below are contrived.
	constant SongPosition : std_logic_vector(7 downto 0) := "11110010";
	constant SongPositionData1 : std_logic_vector(7 downto 0) := "00001010";
	constant SongPositionData2 : std_logic_vector(7 downto 0) := "00100110";

	-- System realtime messages would be processed or ignored by
	-- another mechanism, probably, so if one is received between two
	-- data bytes, it shouldn't mess anything up.
	constant ActiveSense : std_logic_vector(7 downto 0) := "11111110";
	
begin

	event_builder: entity work.event_builder
	port map
	(
		iMidiByte => MidiByte,
		iDataReady => MidiReady,
		iClock => Clock,

		oStatusReady => StatusReady,
		oStatusMessage => StatusMessage,
		oStatusChannel => StatusChannel,
		oStatusParam1 => StatusParam1,
		oStatusParam2 => StatusParam2,

		oIgnoredByte => IgnoredByte,
		oIgnoredReady => IgnoredReady
	);

	process
	begin

		--
		-- no new data
		--
		Tick(Clock);
		Tock(Clock);
		AssertLow(StatusReady);
		AssertLow(IgnoredReady);

		--
		-- play a note
		--
		NewFrame(NoteOn, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertLow(IgnoredReady);
		-- data byte 1
		NewFrame(MiddleC, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertLow(IgnoredReady);
		-- data byte 2
		NewFrame(LowishVelocity, MidiByte, MidiReady, Clock);
		AssertHigh(StatusReady);
		AssertLow(IgnoredReady);
		-- new status event!
		AssertStatus(StatusMessage, STATUS_NOTE_ON,
					 StatusChannel, 0,
					 StatusParam1, MiddleC,
					 StatusParam2, LowishVelocity);

		--
		-- running status for a second note
		--
		-- data byte 1
		NewFrame(AnotherNote, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertLow(IgnoredReady);
		-- data byte 2
		NewFrame(HighishVelocity, MidiByte, MidiReady, Clock);
		AssertHigh(StatusReady);
		AssertLow(IgnoredReady);
		-- new status event!
		AssertStatus(StatusMessage, STATUS_NOTE_ON,
					 StatusChannel, 0,
					 StatusParam1, AnotherNote,
					 StatusParam2, HighishVelocity);

		--
		-- unhandled system common message data should be ignored
		--
		NewFrame(SongPosition, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertHigh(IgnoredReady);
		NewFrame(SongPositionData1, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertHigh(IgnoredReady);
		NewFrame(SongPositionData2, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertHigh(IgnoredReady);

		--
		-- status message interrupted by system realtime messages should still
		-- be received correctly
		--
		NewFrame(NoteOff, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertLow(IgnoredReady);
		-- system realtime message
		NewFrame(ActiveSense, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertHigh(IgnoredReady);
		-- data byte 1
		NewFrame(MiddleC, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertLow(IgnoredReady);
		-- system realtime message
		NewFrame(ActiveSense, MidiByte, MidiReady, Clock);
		AssertLow(StatusReady);
		AssertHigh(IgnoredReady);
		-- data byte 2
		NewFrame(ZeroVelocity, MidiByte, MidiReady, Clock);
		AssertHigh(StatusReady);
		AssertLow(IgnoredReady);
		-- new status event!
		AssertStatus(StatusMessage, STATUS_NOTE_OFF,
					 StatusChannel, 0,
					 StatusParam1, MiddleC,
					 StatusParam2, ZeroVelocity);
		
		wait;
	end process;
	
end tests;
