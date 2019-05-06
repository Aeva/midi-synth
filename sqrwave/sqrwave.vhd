library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity sqrwave is
	generic (
        gClockHz : integer := 1e8 -- system clock frequency in Hz
    );
    port (
    	iClock : in std_logic; -- system clock
    	iFrequency : in integer range 8 to 15804;
    	iAmplitude : in integer;
    	oSample : out signed(31 downto 0)
    );
end entity;


architecture etc of sqrwave is
    signal Counter : integer := 0;
    signal Sign : integer range -1 to 1:= 1;
begin
    
    process (iClock)
	begin
	   if (rising_edge(iClock)) then
	       if (Counter >= gClockHz) then
			   oSample <= to_signed(iAmplitude * Sign, oSample'length);
			   Sign <= Sign * (-1); 
	           Counter <= 0;
	       else
	           Counter <= Counter + iFrequency;
	       end if;
	   end if;
	end process;
	
end architecture;
