
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package midi is

	constant POLYPHONY : positive := 20; -- maximum number of concurrent voices

	type frame_type is
	(
		DATA_FRAME,
		STATUS_NOTE_ON,
		STATUS_NOTE_OFF,
		STATUS_POLYPHONIC_PRESSURE,
		STATUS_CONTROL_CHANGE,
		STATUS_PROGRAM_CHANGE,
		STATUS_CHANNEL_PRESSURE,
		STATUS_PITCH_BLEND,
		STATUS_SYSTEM,
		REALTIME_TIMING_CLOCK,
		REALTIME_UNDEFINED1,
		REALTIME_START,
		REALTIME_CONTINUE,
		REALTIME_STOP,
		REALTIME_UNDEFINED2,
		REALTIME_ACTIVE_SENSE,
		REALTIME_SYSTEM_RESET
	);

	subtype midi_channel is unsigned(3 downto 0);
	subtype midi_param is unsigned(6 downto 0);

	constant STATUS_OFFSET : integer := frame_type'POS(STATUS_NOTE_ON);
	constant REALTIME_OFFSET : integer := frame_type'POS(REALTIME_TIMING_CLOCK);

	type decoded_byte is record
		FrameType : frame_type;
		IsRealtimeEvent : std_logic;
		-- these won't necessarily be valid, check the frame type
		AsChannel : midi_channel;
		AsParam : midi_param;
	end record;

	type status_message is record
		Message : frame_type;
		Channel : midi_channel;
		Param1 : midi_param;
		Param2 : midi_param;
	end record;

	type voice is record
		active : std_logic; -- note is currently pressed
		expired : std_logic; -- note no longer contributes any sound
		since_press : natural; -- time since note was pressed
		since_release : natural; -- time since note was released
		program : natural; -- program number
		key : natural; -- key number
		strike : natural; -- velocity
	end record;

	type voice_array is array (POLYPHONY - 1 downto 0) of voice;

	function to_midi_param ( IntForm : in integer ) return midi_param;
	
end midi;


package body midi is

	function to_midi_param ( IntForm : in integer ) return midi_param is
	begin
		return to_unsigned(0, midi_param'length);
	end;

end package body midi;
