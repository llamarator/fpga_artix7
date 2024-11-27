-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity top_system_tb is

end top_system_tb;

-------------------------------------------------------------------------------

architecture SIM of top_system_tb is


  signal RST_i    : std_logic := '1';
  signal CLK_i    : std_logic := '0';
  signal RX_i     : std_logic;
  signal LED_i    : std_logic;
  signal DP_i     : std_logic;
  signal SEG_AG_i : std_logic_vector(6 downto 0);
  signal AND_30_i : std_logic_vector(3 downto 0);
  signal BUSY_i   : std_logic;
  signal RES_i    : std_logic;
  signal VBAT_i   : std_logic;
  signal VDD_i    : std_logic;
  signal D_C_i    : std_logic;
  signal CS_i     : std_logic;
  signal SDIN_i   : std_logic;
  signal SCLK_i   : std_logic;
  
  constant cte_baudios : integer := 9600;
  signal   trama_tx    : std_logic_vector(10 downto 0);
  signal   dato_tx     : std_logic_vector(7 downto 0);
  
  signal trama_tx_paridad_mal : std_logic;      --añadido
  signal trama_tx_stop_mal : std_logic;      --añadido

begin  -- SIM

  DUT : entity work.top_system
    port map (
      RST    => RST_i,
      CLK    => CLK_i,
      RX     => RX_i,
      LED    => LED_i,
      DP     => DP_i,
      SEG_AG => SEG_AG_i,
      AND_30 => AND_30_i,
      BUSY   => BUSY_i,
      RES    => RES_i,
      VBAT   => VBAT_i,
      VDD    => VDD_i,
      D_C    => D_C_i,
      CS     => CS_i,
      SDIN   => SDIN_i,
      SCLK   => SCLK_i);



  SPI_DEV : entity work.spi_device
    port map (
      D_C  => D_C_i,
      CS   => CS_i,
      SDIN => SDIN_i,
      SCLK => SCLK_i);

  u_tx : entity work.pc_tx
    port map (
      tx => rx_i);


  -- estímulos para CLK y RST
 process				 
        begin
        CLK_i <= '0';            -- clock cycle is 10 ns
        wait for 5 ns;
        CLK_i <= '1';
        wait for 5 ns;
        end process;
  --
  process
    begin
    rst_i <= '1';
    wait for 20 ns;
    rst_i <= '0';
    wait for 50 ms;
    end process;
    
---------------------------------Codigo para pc_tx-------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--entity pc_tx is
--  port (
--    tx : out std_logic);
--    --corresponde a la señal RX
--end pc_tx;
---- paridad impar
---- 1 bit de parada
--architecture rtl of pc_tx is

--  constant cte_baudios : integer := 9600;
--  signal   trama_tx    : std_logic_vector(10 downto 0);
--  --Es la trama de 11 bits conteniendo ya los 8 bits de datos
--  signal   dato_tx     : std_logic_vector(7 downto 0);
--  --Son los datos que vamos a transmitir a través del protocolo
--  --RS_232
  
--  signal trama_tx_paridad_mal : std_logic;      --añadido
--  signal trama_tx_stop_mal : std_logic;      --añadido

--begin  -- rtl



--  process (dato_tx,trama_tx_paridad_mal)
--    variable aux_par : std_logic;
--  begin
--    --crea la trama para el dato a transmitir
--    trama_tx             <= (0 => '0', others => '1');
--    trama_tx(8 downto 1) <= dato_tx;
--    aux_par     := '0';
--    for i in dato_tx'range loop
--      if dato_tx(i) = '1' then
--        aux_par := not aux_par;
--        --configuracion del bit de paridad
--      end if;
--    end loop;  -- i 
           
--    if trama_tx_paridad_mal = '1' then      --añadido
--    trama_tx(9) <= aux_par;         --añadido
--    else                            --añadido
--    trama_tx(9)          <= not aux_par;    --esta es la parte buena
--    end if;                         --añadido
--    --asignación final del bit de paridad
    
--    if trama_tx_stop_mal = '1' then      --añadido
--    trama_tx(10) <= '0';         --añadido
--    else                            --añadido
--    trama_tx(10)<= '1';    --añadido
--    end if;                   --añadido
--  end process;
  



--  process
--  --transmite la trama
--    procedure tx_data is
--      variable T_tx_aux : time := 10 ns;
--    begin
--      wait for 1 us;
--      T_tx_aux                 := 1 sec/ cte_baudios;
--      wait for 1 us;
--      for j in 0 to 10 loop
--        tx <= trama_tx(j);
--        wait for T_tx_aux;
--      end loop;  -- j     
--      wait for 5 us;
--    end tx_data;

--    procedure ruido is
--        variable tx_aux : std_logic := '0';
--        begin
--        for j in 0 to 15 loop
--        tx_aux := not tx_aux;
--        wait for 13ns;
--        tx <= tx_aux;
        
--        end loop;
--        tx <= '1';
--    end ruido;


--  begin
  
  
  
--    dato_tx <= x"48";
--    tx      <= '1';
--    wait for 1.5 ms;-- solo para simular  top_system
--    --wait for 1 us; --solo para simular  receiver
--    tx_data;

-----------paridad mal-------------
--    trama_tx_paridad_mal <= '1';
--    dato_tx <= x"4F";
    
--    wait for 1 us;
--    tx_data;
--    trama_tx_paridad_mal <= '0';
-----------paridad mal----------

--    ruido;
--    wait for 500 us;    --añadido tiempo de espera 
--    wait for 1 us;
--    tx_data;


--    dato_tx <= x"4C";
--    wait for 1 us;
--    tx_data;

-----------paridad mal----------
--    trama_tx_paridad_mal <= '1';    --añadido

--    dato_tx <= x"41";
--    wait for 1 us;
--    tx_data;
    
--    trama_tx_paridad_mal <= '0';    --añadido
-- ---------paridad mal----------
    
--    wait for 500 us;    --añadido tiempo de espera

--    dato_tx <= x"09";
--    wait for 1 us;
--    tx_data;

--    dato_tx <= x"4D";
--    wait for 1 us;
--    tx_data;
------------------------------stop mal-----------
--    trama_tx_stop_mal <= '1';   --añadido
--    dato_tx <= x"55";
--    wait for 1 us;
--    tx_data;
--    trama_tx_stop_mal <= '0';   --añadido
------------------------------stop mal-----------
    
--    dato_tx <= x"4E";
--    wait for 1 us;
--    tx_data;
--    dato_tx <= x"44";
--    wait for 1 us;
--    tx_data;
--    dato_tx <= x"4F";
--    wait for 1 us;
--    tx_data;
--    dato_tx <= x"09";
--    wait for 1 us;
--    tx_data;
   
--    report "FIN CONTROLADO DE LA SIMULACION" severity failure;
--  end process;


--end rtl;

--------------------------------Fin de código para pc_tx--------------------------


  

end SIM;

-------------------------------------------------------------------------------
