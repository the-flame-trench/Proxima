----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.05.2020 23:49:00
-- Design Name: 
-- Module Name: usb3_loopback_top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity usb3_loopback_top_level is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           clk_ftdi	: in std_logic;
           txe_n	 : in	std_logic;
           rxf_n	 : in	std_logic;
           oe_n   : out std_logic := '1';
           rd_n	 : out std_logic := '1';
           wr_n	 : out std_logic := '1';
           be	    : inout std_logic_vector(3 downto 0) := (others => 'Z');
           data	 : inout	std_logic_vector(31 downto 0) := (others => 'Z');
           led : out std_logic_vector(7 downto 0) := (others => '0')
          );
    end usb3_loopback_top_level;

architecture Behavioral of usb3_loopback_top_level is

component FIFO is
         generic(
           fifo_length   : positive := 4096;
           data_length   : positive := 8;
           fifo_high_watermark_level : positive := 3276;
           fifo_low_watermark_level : positive := 819    
           ); 
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               
               write_en : in STD_LOGIC;
               data_in : in STD_LOGIC_VECTOR (data_length - 1 downto 0);
               fifo_full : out STD_LOGIC;
               
               fifo_almost_full : out STD_LOGIC;
               fifo_almost_empty : out STD_LOGIC;
               
               data_out : out STD_LOGIC_VECTOR (data_length - 1 downto 0);
               fifo_empty : out STD_LOGIC;
               read_en : in STD_LOGIC;
               
               half_full : out STD_LOGIC
               );
    end component;
    
    type state_type is (idle_state, read_state, write_state,wait_state, wait_state2);
    signal current_state, temp_state : state_type := idle_state;
    
    signal write_en_sig : std_logic := '0';
    signal fifo_full_sig : std_logic := '0';
    signal empty_sig : std_logic := '0';
    signal read_en_sig : std_logic := '0';
    signal data_in_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal data_out_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal oe_n_sig : std_logic := '1';
    signal rd_n_sig : std_logic := '1';
    signal wr_n_sig : std_logic := '1';
begin
    
    inst_fifo : fifo
    generic map
    (
        fifo_length => 4096,
        data_length => 32,
        fifo_high_watermark_level => 3276,
        fifo_low_watermark_level => 819   
    )
    
    port map
    (
        clk => clk_ftdi,
        rst  => rst, 
        write_en => write_en_sig,
        data_in => data_in_sig,
        fifo_full => fifo_full_sig,
        fifo_almost_full => open,
        fifo_almost_empty => open,
        data_out => data_out_sig,
        fifo_empty => empty_sig,
        read_en => read_en_sig,
        half_full => open
    );
    
    led(0) <= empty_sig;
    
    process(clk_ftdi)
    begin
        if(rst = '0') then
            
        elsif(rising_edge(clk_ftdi)) then
            oe_n <= '1';
            rd_n <= '1';
            wr_n <= '1';
            oe_n_sig <= '1';
            rd_n_sig <= '1';
            wr_n_sig <= '1';
            data <= (others => 'Z');
            read_en_sig <= '0';
            write_en_sig <= '0';
            led(7 downto 1) <= (others => '0');
            case(current_state) is
            
            when idle_state =>
                led(1) <= '1';
                current_state <= idle_state;
                if(rxf_n = '0') then
                    current_state <= wait_state;
                    oe_n <= '0';
                    oe_n_sig <= '0';
                elsif(txe_n = '0') then
                    current_state <= idle_state;
                    if(empty_sig = '0') then
                        current_state <= write_state;
                        read_en_sig <= '1';
                    end if;
                end if;
            when read_state =>
                led(2) <= '1';
                if(rxf_n = '1' or fifo_full_sig = '1') then
                    write_en_sig <= '0';
                    data_in_sig <= data;
                    current_state <= idle_state;
                    rd_n <= '1';
                    rd_n_sig <= '1';
                    oe_n <= '1';
                    oe_n_sig <= '1';
                else
                    write_en_sig <= '1';
                    data_in_sig <= data;
                    current_state <= read_state;
                    rd_n <= '0';
                    rd_n_sig <= '0';
                    oe_n <= '0';
                    oe_n_sig <= '0';
                end if;
            
            when write_state =>
                led(3) <= '1';
                if(txe_n = '1' or empty_sig = '1') then
                    wr_n <= '1';
                    wr_n_sig <= '1';
                    read_en_sig <= '0';
                    current_state <= idle_state;
                else
                    wr_n <= '0';
                    wr_n_sig <= '0';
                    read_en_sig <= '1';
                    data <= data_out_sig;
                    current_state <= write_state;
                end if;
            
            when wait_state =>
                led(4) <= '1';
                rd_n <= '0';
                rd_n_sig <= '0';
                oe_n <= '0';
                oe_n_sig <= '0';
                current_state <= read_state;
            
            when wait_state2 =>
                led(5) <= '1';
                rd_n <= '0';
                oe_n <= '0';
                oe_n_sig <= '0';
                rd_n_sig <= '0';
                current_state <= read_state;
            
            when others => 
                led(6) <= '1';
                current_state <= idle_state;
            end case;
            
        end if;
    
    end process;


end Behavioral;
