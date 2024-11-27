

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_controller_tb is
end display_controller_tb;

architecture sim of display_controller_tb is
  constant CNT1         : time                         := 15us ;
  signal   RST_i        : std_logic                    := '1';
  signal   CLK_i        : std_logic                    := '0';
  signal   DATO_RX_OK_i : std_logic                    := '0';
  signal   DATO_RX_i    : std_logic_vector(7 downto 0) := (others => '0');
  signal   DP_i         : std_logic;
  signal   SEG_AG_i     : std_logic_vector(6 downto 0);
  signal   AND_30_i     : std_logic_vector(3 downto 0);

begin  -- sim

  DUT : entity work.display_controller
    port map (
      RST        => RST_i,
      CLK        => CLK_i,
      DATO_RX_OK => DATO_RX_OK_i,
      DATO_RX    => DATO_RX_i,
      DP         => DP_i,
      SEG_AG     => SEG_AG_i,
      AND_30     => AND_30_i);

  clk_i <= not clk_i after 5 ns;
  rst_i <= '0'       after 137 ns;

  process
  begin  -- process
    wait for 212 ns;
    for j in 0 to 15 loop
      wait until CLK_i = '0';
      DATO_RX_OK_i <= '1';
      DATO_RX_i    <= std_logic_vector(to_unsigned(j, 8));
      wait until CLK_i = '0';
      DATO_RX_OK_i <= '0';
      wait for CNT1;
    end loop;  -- j
  --  report "FIN CONTROLADO DE LA SIMULACION" severity failure;

  end process;
end sim;
