

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity REASONABLE_SYNTH is
  generic (
    clock_hz : integer := 1e8; -- == 100mhz
  );
  port (
    i_clock : in std_logic;
    i_reset : in std_logic;
    -- midi uart inferate --
    --i_midi_rxd : in std_logic;
    -- debug uart interface --
    o_debug_txd : out std_logic;
    i_debug_rxd : in std_logic;
  );
end REASONABLE_SYNTH;




architecture FNORD of REASONABLE_SYNTH is
  constant uart_midi_baud : integer := 31250;
  constant uart_midi_parity : string := "none";
  
  --signal uart_midi_inbox : std_logic_vector(7 downto 0);
  --signal uart_midi_valid : std_logic;
  
  signal uart_debug_inbox : std_logic_vector(7 downto 0);
  signal uart_debug_outbox : std_logic_vector(7 downto 0);
  signal uart_debug_valid : std_logic;

  signal uart_common_reset : std_logic;

begin

  uart_common_reset <= not i_reset;
  
  -- midi_uart: entity work.UART
  -- generic map (
  --   CLK_FREQ => clock_hz,
  --   BAUD_RATE => uart_midi_baud,
  --   PARTIY_BIT => uart_midi_parity
  -- )     
  -- port map (
  -- );
  
  debug_uart: entity work.UART
  generic map (
    CLK_FREQ => clock_hz;
    BAUD_RATE => uart_midi_baud;
    PARTIY_BIT => uart_midi_parity;
  )  
  port map (
    CLK => i_clock,
    RST => uart_common_reset,
    -- UART INTERFACE
    UART_TXD => o_debug_txd;
    UART_RXD => i_debug_rxd;
    -- USER DATA OUTPUT INTERFACE
    DATA_OUT => uart_debug_outbox;
    DATA_VALID => uart_debug_valid;
    -- USER DATA INPUT INTERFACE
    DATA_IN => uart_debug_inbox;
    DATA_SEND => uart_debug_inbox;
  );
  
end FNORD;
