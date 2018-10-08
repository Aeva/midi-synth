
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;

entity event_builder_tests is
end event_builder_tests;

architecture tests of event_builder_tests is

	signal MidiByte : std_logic_vector(7 downto 0);
	signal MidiReady : std_logic := '0';
	signal Clock : std_logic := '0';

	signal StatusReady : std_logic;
	signal StatusMessage : frame_type;
	signal StatusChannel : unsigned(3 downto 0);
	signal StatusParam1 : unsigned(6 downto 0);
	signal StatusParam2 : unsigned(6 downto 0);

	signal IgnoredByte : std_logic_vector(7 downto 0);
	signal IgnoredReady : std_logic;

	constant NoteOn : std_logic_vector(7 downto 0) := "10000000";
	constant NoteOff : std_logic_vector(7 downto 0) := "10010000";
	
	constant MiddleC : std_logic_vector(7 downto 0) := "00111100";
	constant AnotherNote : std_logic_vector(7 downto 0) := "00111000";
	
	constant ZeroVelocity : std_logic_vector(7 downto 0) := "00000000";
	constant LowishVelocity : std_logic_vector(7 downto 0) := "00001101";
	constant HighishVelocity : std_logic_vector(7 downto 0) := "01100110";

	constant ProgramChange : std_logic_vector(7 downto 0) := "11000000";
	constant ProgramOne : std_logic_vector(7 downto 0) := "00000001";
	constant ProgramTwo : std_logic_vector(7 downto 0) := "00000000";

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

		-- idle
		Clock <= '1';
		wait for 10 ns;
		Clock <= '0';
		wait for 10 ns;

		assert StatusReady = '0'
			report "should not start with status ready on" severity failure;
		assert StatusReady = '0'
			report "should not start with ignore ready on" severity failure;
		
		MidiByte <= NoteOn;
		wait for 1 ns; -- presumably this is set some clock ticks
					   -- before MidiReady would be
		MidiReady <= '1';
		Clock <= '1';
		wait for 10 ns;

		assert StatusReady = '0'
			report "no status change should have occured" severity failure;
		assert IgnoredReady = '0'
			report "no ignore change should have occured" severity failure;

		-- idle
		MidiReady <= '0';
		Clock <= '0';
		wait for 10 ns;
		Clock <= '1';
		wait for 10 ns;

		assert StatusReady = '0'
			report "no status change should have occured" severity failure;
		assert IgnoredReady = '0'
			report "no ignore change should have occured" severity failure;

		MidiByte <= MiddleC;
		Clock <= '0';
		wait for 10 ns;
		MidiReady <= '1';
		Clock <= '1';
		wait for 10 ns;

		assert StatusReady = '0'
			report "no status change should have occured" severity failure;
		assert IgnoredReady = '0'
			report "no ignore change should have occured" severity failure;

		MidiByte <= LowishVelocity;
		Clock <= '0';
		wait for 10 ns;
		MidiReady <= '1';
		Clock <= '1';
		wait for 10 ns;

		assert StatusReady = '1'
			report "a status change should have occured" severity failure;
		assert IgnoredReady = '0'
			report "no ignore change should have occured" severity failure;

		assert StatusMessage = STATUS_NOTE_ON
			report "StatusMessage should be STATUS_NOTE_ON" severity failure;
		assert StatusChannel = 0
			report "StatusChannel should be 0" severity failure;
		assert StatusParam1 = unsigned(MiddleC)
			report "StatusParam1 should be MiddleC" severity failure;
		assert StatusParam2 = unsigned(LowishVelocity)
			report "StatusParam2 should be LowishVelocity" severity failure;


		
		wait;
	end process;
	
end tests;
