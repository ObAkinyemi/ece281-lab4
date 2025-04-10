
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations

  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    signal w_clk : std_logic;
    signal fsm_reset : std_logic;
    signal clk_reset : std_logic;
    signal w_floor : STD_LOGIC_VECTOR (3 downto 0);  
    signal w_data : std_logic_vector(3 downto 0);
	
begin
	-- PORT MAPS ----------------------------------------
--	port map for seven seg decoder
	sevenseg_decoder_mappings : sevenseg_decoder port map (
	   i_Hex => w_floor,
	   o_seg_n => seg
	);
	
--	port map for the elevator controller
	elevator_controller_mappings : elevator_controller_fsm port map (

	   i_clk => w_clk,
	   i_reset => fsm_reset,
	   go_up_down => sw(1),
	   is_stopped => sw(0),
	   o_floor => w_floor
	);
	
    

--  PORT MAP FOR the clock divider
    clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 25000000 ) -- 1 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => clk_reset,
            o_clk => w_clk
    );  
    
	-- CONCURRENT STATEMENTS ----------------------------
	fsm_reset <= btnR or btnU;
	clk_reset <= btnL or btnU;
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	   led(14) <= '0';
	   led(15) <= w_clk;
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	an(0) <= '0';
	an(1) <= '1';
	an(2) <= '1';
	an(3) <= '1';
	
end top_basys3_arch;
