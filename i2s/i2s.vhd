
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity i2s is
	generic (
		gClockHz : integer := 1e8; -- system clock frequency in Hz
		gSamplingHz : integer := 44100 -- sampling rate in HZ
	);
	port (
		iClock : in std_logic; -- system clock
		-- I2S interface
		oBitClock : out std_logic;
		oWordClock : out std_logic;
		oDataLine : out std_logic;
		iLeftChannel : in signed(31 downto 0);
		iRightChannel : in signed(31 downto 0)
	);
end entity;
	

architecture etc of i2s is
	constant CLOCK_TARGET : integer := gClockHz / (gSamplingHz * 32 * 2 * 2);
	signal ClockCounter : integer := 0;
	signal Index : integer := 0;
	signal Phase : std_logic := '0';
	signal Channel : std_logic := '0';
	signal Message : signed(31 downto 0) := to_signed(0, iLeftChannel'length);

begin
	oBitClock <= Phase;
	oWordClock <= Channel;
	oDataLine <= Message(Index);

	process(iClock)
	begin
		if (rising_edge(iClock)) then
			if (ClockCounter = CLOCK_TARGET) then
				ClockCounter <= 0;
				Phase <= not Phase;
			else
				ClockCounter <= ClockCounter + 1;
			end if;
		end if;
	end process;

	process(Phase)
	begin
		if (falling_edge(Phase)) then
			if (Index = 31) then
				Index <= 0;
				Channel <= not Channel;
				if (Channel = '1') then
				    Message <= iLeftChannel;
				else
				    Message <= iRightChannel;
				end if;
			else
				Index <= Index + 1;
			end if;
		end if;
	end process;
	
end architecture;
