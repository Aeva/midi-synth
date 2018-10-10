

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


package midi_test_helper is

	procedure Tick ( signal Clock : out std_logic );
	procedure Tock ( signal Clock : out std_logic );
	procedure AssertHigh ( signal ReadyBit : in std_logic );
	procedure AssertLow ( signal ReadyBit : in std_logic );

	procedure AssertStatus
	(
		signal Status : status_message;
		constant ExpectedMessage : frame_type;
		constant ExpectedChannel : integer;
		constant ExpectedParam1 : std_logic_vector(7 downto 0);
		constant ExpectedParam2 : std_logic_vector(7 downto 0)
	);

	procedure NewFrame
	(
		constant NewFrame : in std_logic_vector(7 downto 0);
		signal MidiByte : out std_logic_vector(7 downto 0);
		signal MidiReady : out std_logic;
		signal Clock : out std_logic
	);

end package midi_test_helper;




package body midi_test_helper is

	procedure Tick ( signal Clock : out std_logic ) is
	begin
		wait for 5 ns;
		Clock <= '1';
		wait for 5 ns;
	end Tick;


	procedure Tock ( signal Clock : out std_logic ) is
	begin
		wait for 5 ns;
		Clock <= '0';
		wait for 5 ns;
	end Tock;

	
	procedure AssertHigh ( signal ReadyBit : in std_logic ) is
	begin
		assert ReadyBit = '1'
			report "Expected ready state bit to be high." severity failure;
	end AssertHigh;


	procedure AssertLow ( signal ReadyBit : in std_logic ) is
	begin
		assert ReadyBit = '0'
			report "Expected ready state bit to be low." severity failure;
	end AssertLow;


	procedure AssertStatus
	(
		signal Status : status_message;
		constant ExpectedMessage : frame_type;
		constant ExpectedChannel : integer;
		constant ExpectedParam1 : std_logic_vector(7 downto 0);
		constant ExpectedParam2 : std_logic_vector(7 downto 0)
	) is
	begin
		assert Status.Message = ExpectedMessage
			report "Unexpected value for StatusMessage" severity failure;
		assert Status.Channel = ExpectedChannel
			report "Unexpected value for StatusChannel" severity failure;
		assert Status.Param1 = unsigned(ExpectedParam1(6 downto 0))
			report "Unexpected value for StatusParam1" severity failure;
		assert Status.Param2 = unsigned(ExpectedParam2(6 downto 0))
			report "Unexpected value for StatusParam2" severity failure;
	end AssertStatus;

	
	procedure NewFrame
	(
		constant NewFrame : in std_logic_vector(7 downto 0);
		signal MidiByte : out std_logic_vector(7 downto 0);
		signal MidiReady : out std_logic;
		signal Clock : out std_logic
	) is
	begin
		MidiByte <= NewFrame; -- this needs time to propogate before
							  -- MidiReady would be set
		Tick(Clock);
		Tock(Clock);
		MidiReady <= '1';
		Tick(Clock);
		Tock(Clock);
		MidiReady <= '0';
	end NewFrame;

	
end package body midi_test_helper;
