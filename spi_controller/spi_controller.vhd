library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity spi_controller is
  port ( 
         CLK         : in  std_logic;
         RST         : in  std_logic;
         DATA_SPI_OK : in  std_logic;
         --Señal activa durante un periodo de CLK que indica
         --la llegada de un nuevo dato
         DATA_SPI    : in  std_logic_vector (8 downto 0);
         --Dato de 9 bits proveniente de oled_controller para ser enviado
         --al display OLED,su bit de mayor peso es D_C
         D_C         : out std_logic;
         CS          : out std_logic;
         --Salida activa a nivel bajo que habilita al display
         --durante todo el proceso de la transmisión para
         --que reciba el nuevo dato por el protocolo SPI
         SDIN        : out std_logic;
         --Salida utilizada para enviar los datos al display
         SCLK        : out std_logic;
         --Señal de sincronismo generada para indicar el momento en el que
         --obtener cada bit
         END_SPI     : out std_logic);
         --indica el fin de la transmisión del nuevo dato
end spi_controller;

architecture rtl of spi_controller is
     signal BUSY         :          std_logic;
     --señal que indica que se está transmitiendo un dato
     signal FC           :          std_logic;
     --Indica el fin de cada semiperiodo de SCLK
     signal SCLK_in      :          std_logic := '1';
     --Señal complementaria a SCLK 
     signal CE           :          std_logic;
     --Señal que indica con un pulso el fin de cada periodo de SCLK o el fin
     --de trnasmisión de un bit.
     signal REG_OUT      :          std_logic_vector (8 downto 0);
     --salida del registro
     signal REG_OUT_aux  :          std_logic_vector (8 downto 0);
     --salida del registro temporal que luego se asignará a REG_OUT mediante
     --una asignación concurrente
     signal SCLK_CE       :          std_logic;
     --INHIBE la generación de SCLK a nivel alto
     signal MUX_CE       :          std_logic;
     --Señal de habilitación del Multiplexor
     signal MUX_OUT      :          std_logic;
     --Salida del multiplexor
     signal MUX_aux      :          unsigned (2 downto 0) := "000";
     --Conversión de cuenta aux a unsigned que se usará para saber qué dato
     --se está transmitiendo para la entrada de selección del multiplexor o saber
     --cuando quitar la entrada BUSY  
     signal cuenta_aux   :          integer := 8;
     --cuenta que se convertirá a unsigned siendo esta nueva señal MUX_aux 
     --LAS VARIABLES NSIGUIENTES SON PARA VARIAR LA FRECUENCIA DE CE Y FC SON DIVISORES DE FEECUENCIA
     constant cte_N1      :         integer := 6;  
     --El valor de esta constante marcará el factor de división del
     --prescaler que impondrá la frecuencia de la señal FC cuyo periodo
     --es la mitad de el de la señal CE que tiene el mismo periodo que la señal
     --SCLK. Su valor por tanto siguiendo la tabla que impone los tiempos,
     --será 2*TCLK * cte_N1 > 100ns = 20ns *cte_N1>100ns en mi caso elijo 
     --6 ya que 5 sería demasiado justo 
     signal   counter_reg :         integer range 0 to cte_N1;    
     type estadoFSM is (S0,S1,S2);
     signal estado: EstadoFSM;
     
begin

-------------------------------------------------------------------------
-------------------------START-------------------------------
-------------------------------------------------------------------------
   

   process (CLK,RST,MUX_aux)    -- Quest_2 CREACION BUSY
   --secuencial
    variable couter : integer;
    --variable requerida para que la cuenta se actualice dentro del proceso
    begin  
    if RST='1' then
        BUSY <= '0';
        SCLK_CE <= '1';
        couter := 0;
     elsif(CLK'event and CLK = '1') then
                if DATA_SPI_OK = '1' then
                --iniciamos la cuenta a partir del recibimiento de 
                --DATA_SPI_OK
                 BUSY <= '1' ;
                 SCLK_CE <= '0';
                 couter := 0;               
                end if;
                if FC = '1' then
                   couter := couter +1;
                   if couter = 16 then 
                   --inhabilitamos SCLK porque si no, cambiaría de nivel
                   --debido a la naturaleza del bloque que la genera
                    SCLK_CE <= '1';
                   end if;              
                   if couter = 17  then        
                   --Una vez esperado TSCLK/2 después de transmitir el
                   --último dato finalizamos la transmisión
                      BUSY <= '0';
                   end if;
                end if;
    end if;
end process;
		
-------------------------------------------------------------------------
--Counter N1    generamos  FC	
--secuencial		
	  process (CLK,RST)                 --Es un divisor de frecuencia (prescaler)
begin  -- process
 if(RST = '1') then
  counter_reg <= 0;
 elsif clk'event and clk = '1' then
            if counter_reg = cte_N1-1 then      --Es un contador simple que se resetea sólo
            counter_reg <= 0;
            else
            counter_reg <= counter_reg+1;
            end if;
  end if;
end process;

process (clk, rst)
    begin  -- process
    if(RST = '1') then
      FC <= '0';
      elsif clk'event and clk = '1' then
            if (counter_reg = cte_N1-1 and BUSY = '1')then      --El contador anterior al llegar al valor maximo cambia de estado FC
              FC <= '1';
            else
              FC <= '0';
            end if;       
    end if;
end process;


   -----------------------------------------------------------------------
   

   process (CLK,RST)    --Quest_1 
   --como SCLK no se puede leer usamos SCLK_in 
   --y posteriormente la asignamos a SCLK por medio
   --de una asignación concurrente.Por lo demás,
   --este proceso tiene el comportamiento de un biestable tipo T
   begin
      if RST='1' then
      SCLK_in <= '1';
        elsif CLK'event and CLK='1' then
            if  BUSY = '1' and SCLK_CE = '0' and FC = '1' then
                SCLK_in <= not(SCLK_in);
            end if;
      end if;
   end process;
   SCLK <= SCLK_in;
   --asignación concurrente ya que SCLK no puede leerse
   
   
   ------------------------------------------------------------------------------
   
   --CC1 GENERADOR DE CE
    --combinacional/""secuencial""
    process (SCLK_in,FC)
        begin  -- process
        CE <= SCLK_in and FC;
        --Una simple puerta and,se podría poner como asignación concurrente
    end process;

   
   ------------------------------------------------------------------------------
   
   
   process (CLK,RST)            --CONTADOR MUX GENERADOR DE CUENTA
   --secuencial
   variable cuenta : integer ;
   --variable necesaria para un preciso funcionamiento del proceso
   --se podría hacer con una señal pero no sería preciso 
   begin
   if RST = '1' then
    cuenta_aux <= 8;
    MUX_CE <= '0';
    cuenta := 8;  
    elsif CLK='1' and CLK'event then     
           if CE = '1' then
           MUX_CE <= '1';
           cuenta := cuenta -1;
--           cuenta_aux <= cuenta;
           end if;
           if cuenta < 0 or BUSY = '0' then
--           cuenta_aux <= 8;
           cuenta := 8;
           MUX_CE <= '0';
           end if; 
           cuenta_aux <= cuenta;     
     end if;


   end process;
   
       MUX_aux <= to_unsigned(cuenta_aux,3);
       --asignación concurrente.
   
   -----------------------------------------------------------------------------
   
    --REGISTRO
    --secuencial
    process( CLK,RST)       
    begin
     if RST = '1' then
     REG_OUT_aux <= (others => '0');
     D_C <= '0';
     elsif (CLK'event and CLK = '1') then
        REG_OUT_aux <= DATA_SPI;
        D_C <= REG_OUT_aux(8);
    end if;
    end process;
    REG_OUT <= REG_OUT_aux;           --asignacion concurrente
   
   
   
   ----------------------------------------------------------------
   
--MULTIPLEXOR
--combinacional
   process (REG_OUT,MUX_aux,MUX_CE)
   begin   
    if MUX_CE = '1' then 
          case MUX_aux is
             when "000" => MUX_OUT <= REG_OUT(0);
             when "001" => MUX_OUT <= REG_OUT(1);
             when "010" => MUX_OUT <= REG_OUT(2);
             when "011" => MUX_OUT <= REG_OUT(3);
             when "100" => MUX_OUT <= REG_OUT(4);
             when "101" => MUX_OUT <= REG_OUT(5);
             when "110" => MUX_OUT <= REG_OUT(6);
             when "111" => MUX_OUT <= REG_OUT(7);
             when others => MUX_OUT <= '0';
          end case;
      else 
      MUX_OUT <= '0';
      end if;
   end process;

   --------------------------------------------------------------------------------
   
   
   
   
   
   process (CLK,RST)                                    --BIESTABLE D
   --secuencial
   begin
   if ( RST = '1') then
    SDIN <= '0';
   elsif CLK'event and CLK='1' then          
          SDIN <= MUX_OUT;
   end if;
   end process;

   
   
   -------------------------------------------------------------------------------
   
   
   process (BUSY)    -- GENERADOR DE CS
   --combinacional
   begin  
         if BUSY = '1' then
            CS <= '0';
         else
            CS <= '1';
         end if;
   end process;
   

   ---------FSM
     --Secuencial
     process(rst,clk)
     begin
         if (rst='1') then
             estado <= S0;
             elsif (clk'event and clk='1') then
                 case estado is
                     when S0 =>
                     if (BUSY = '1') then
                         estado <= S1;
                     end if;
                     when S1 =>
                     if (BUSY = '0') then
                         estado <= S2;
                     end if;
                     when S2 =>
                         estado <= S0;
                  end case;
        end if;
     end process;
     
     --Combinacional
     process(estado)
         begin -- Cálculo de las salidas
          END_SPI <= '0';            --añadido para quitar el latch
             case estado is
             when S0 =>
                 END_SPI <= '0';
             when S1 =>
             --ninguna funcionalidad en este estado implementada
             when S2 =>
             END_SPI <= '1';
             end case;
     end process;
   
   ---------------------------------------------------------------------------------------------
   ---------------------------------------------------------------------------------------------
      
	
				

end rtl;

