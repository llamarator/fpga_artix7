-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity spi_controller_tb is

end spi_controller_tb;

-------------------------------------------------------------------------------

architecture sim of spi_controller_tb is


  signal CLK_i         : std_logic                     := '0';
  signal RST_i         : std_logic                     := '1';
  signal DATA_SPI_OK_i : std_logic                     := '0';
  signal DATA_SPI_i    : std_logic_vector (8 downto 0) := (others => '0');
  signal D_C_i         : std_logic;
  signal CS_i          : std_logic;
  signal SDIN_i        : std_logic;
  signal SCLK_i        : std_logic                      := '1';
  signal END_SPI_i     : std_logic;
  
  


begin  -- sim

  DUT : entity work.spi_controller
    port map (
      CLK         => CLK_i,
      RST         => RST_i,
      DATA_SPI_OK => DATA_SPI_OK_i,
      DATA_SPI    => DATA_SPI_i,
      D_C         => D_C_i,
      CS          => CS_i,
      SDIN        => SDIN_i,
      SCLK        => SCLK_i,
      END_SPI     => END_SPI_i);


  SPI_DEV : entity work.spi_device
    port map (
      D_C  => D_C_i,
      CS   => CS_i,
      SDIN => SDIN_i,
      SCLK => SCLK_i);

  -- estímulos para CLK y RST
 process				 
     begin
     CLK_I <= '0';            -- TCLK=10ns
     wait for 5 ns;
     CLK_i <= '1';
     wait for 5 ns;
     end process;  
 process
 
 
  begin  -- process
    RST_i <= '1';
    wait for 100 ns;
    RST_i <= '0';
    
    wait until CLK_i='0';
    DATA_SPI_i <= "110110011" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;                   
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    

    wait until CLK_i='0';
    DATA_SPI_i <= "110000010" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    

    wait until CLK_i='0';
    DATA_SPI_i <= "111100011" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    

    wait until CLK_i='0';
    DATA_SPI_i <= "000000000" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    
    wait until CLK_i='0';
    DATA_SPI_i <= "000010000" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    

    wait until CLK_i='0';
    DATA_SPI_i <= "111111111" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    

    wait until CLK_i='0';
    DATA_SPI_i <= "101010101" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1400 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    

    DATA_SPI_i <= "111010111" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1205 ns;
    DATA_SPI_i <= "000000000" ;
    wait until CLK_i='0';
    wait for 100 ns;
    
    DATA_SPI_i <= "101010111" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1205 ns;
    DATA_SPI_i <= "000000000" ;
    wait for 100 ns;
    
    DATA_SPI_i <= "110010111" ;
    DATA_SPI_OK_i <= '1';
    wait for 10 ns;
    DATA_SPI_OK_i <= '0';
    wait for 1205 ns;
    DATA_SPI_i <= "000000000" ;
    wait for 100 ns;
    
  end process;


end sim;

-------------------------------------------------------------------------------
