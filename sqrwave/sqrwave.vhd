library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.midi.all;


entity sqrwave is
    port (
    	iClock : in std_logic; -- system clock
    	iFrequency : in integer;
    	iAmplitude : in integer;
    	oSample : out signed(31 downto 0)
    );
end entity;


architecture etc of sqrwave is
    signal Counter : integer := 0;
    signal Sample : integer := 0;
    signal Sign : integer := 1;
begin
    oSample <= to_signed(Sample, oSample'length);
    
    process (iClock)
	begin
	   if (rising_edge(iClock)) then
	       if (Counter >= iFrequency) then
			   Sample <= iAmplitude * Sign;
			   Sign <= Sign * (-1); 
	           Counter <= 0;
	       else
	           Counter <= Counter + 1;
	       end if;
	   end if;
	end process;
	
end architecture;
