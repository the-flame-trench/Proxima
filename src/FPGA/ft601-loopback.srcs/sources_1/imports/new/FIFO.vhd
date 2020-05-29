----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.10.2019 13:52:02
-- Design Name: 
-- Module Name: FIFO - Behavioral
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

entity FIFO is
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
end FIFO;

architecture Behavioral of FIFO is
subtype  element is std_logic_vector(data_length - 1 downto 0);
type fifo_type is array (0 to (fifo_length - 1)) of element;
signal fifo : fifo_type := (others => (others => '0'));
signal write_index : unsigned(15 downto 0 ) := (others => '0');
signal read_index : unsigned(15 downto 0 ) := (others => '0');
signal fifo_count : unsigned(15 downto 0 ) := (others => '0');
signal full_sig : std_logic := '0';
signal empty_sig : std_logic := '1';
signal half_sig : std_logic := '0';
signal fifo_almost_full_sig : std_logic := '0';
signal fifo_almost_empty_sig : std_logic := '0';

begin
    data_out <= fifo(to_integer(read_index));
    full_sig  <= '1' when fifo_count = fifo_length-1 else '0';
    empty_sig <= '1' when fifo_count = 0 else '0';
    half_sig <= '1' when (fifo_count = (fifo_length/2)-1) and (fifo_count < fifo_high_watermark_level) else '0';
    fifo_almost_full_sig <= '1' when (fifo_count >= fifo_high_watermark_level - 1) and (full_sig = '0') else '0';
    fifo_almost_empty_sig <= '1' when (fifo_count <= fifo_low_watermark_level - 1) and (empty_sig = '0') else '0';
   
    fifo_full  <= full_sig;
    fifo_empty <= empty_sig;
    half_full <= half_sig;
    fifo_almost_empty <= fifo_almost_empty_sig;
    fifo_almost_full <= fifo_almost_full_sig;
    
    process(clk) is
    begin
        if rising_edge(clk) then
            if(rst = '0') then
                write_index <= (others => '0');
                read_index <= (others => '0');
                fifo_count <= (others => '0');
            else
                if (write_en = '1' and read_en = '0' and full_sig = '0') then
                    fifo_count <= fifo_count + 1;
                elsif (write_en = '0' and read_en = '1' and empty_sig = '0') then
                    fifo_count <= fifo_count - 1;
                end if;
                
                if(write_en = '1' and full_sig = '0') then
                    if(write_index = fifo_length-1) then
                        write_index <= (others => '0');
                    else
                        write_index <= write_index + 1;
                    end if;
                end if;
                
                if(read_en = '1' and empty_sig = '0') then
                    if(read_index = fifo_length-1) then
                        read_index <= (others => '0');
                    else
                        read_index <= read_index + 1;
                    end if;
                end if;
                
                
                
                if(write_en = '1') then
                    fifo(to_integer(write_index)) <= data_in;
                end if;
                
            end if;
        end if;
    end process;
end Behavioral;
