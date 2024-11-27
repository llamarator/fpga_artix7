-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity receiver_tb is

end receiver_tb;

-------------------------------------------------------------------------------

architecture sim of receiver_tb is


  signal clk_i        : std_logic := '0';
  signal rst_i        : std_logic := '1';
  signal rx_i         : std_logic;
  signal dato_rx_i    : std_logic_vector(7 downto 0);
  signal error_recep_i : std_logic;
  signal DATO_RX_OK_i : std_logic;

begin  -- sim

  DUT : entity work.receiver
    port map (
      clk        => clk_i,
      rst        => rst_i,
      rx         => rx_i,
      dato_rx    => dato_rx_i,
      error_recep => error_recep_i,
      DATO_RX_OK => DATO_RX_OK_i);

  u_tx : entity work.pc_tx
    port map (
      tx => rx_i);


  -- estímulos para CLK y RST
  clk_i <= not clk_i after 5 ns;
  rst_i <= '0'       after 137 ns;
  -- 

  
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






end sim;

-------------------------------------------------------------------------------
