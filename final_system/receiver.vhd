library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--velocidad= 9600 bps
-- Nº bits=8
--paridad impar
-- Nº bits parada=1
entity receiver is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    rx         : in  std_logic;
    dato_rx    : out std_logic_vector(7 downto 0);
    error_recep : out std_logic;
    DATO_RX_OK : out std_logic);
end receiver;

architecture rtl of receiver is

--Señales correspondientes a Muestreo
    signal Q1            :          std_logic;
    signal Q2            :          std_logic;
    signal Q3            :          std_logic;
    signal Q4            :          std_logic;
    signal Q5            :          std_logic; 
    signal S            :          std_logic;
    signal R            :          std_logic;

    signal send            :          std_logic := '0';
    --Señal que el dato está listo para enviarse
    
    signal tmp: std_logic_vector(7 downto 0);
    --Señal temporal para la asignación de la salida del registro
    --serie-paralelo
    signal RX_OK            :          std_logic; 
    --Señal RX recibida correcta pasada por el filtro de muestreo
    signal shift_reg_ok            :          std_logic;
    --Señal medio periodo de bit retrasada de bit_pulse
    --Principalmente se usa para medir un bit en el medio 
    --de su periodo de transmisión para mayor fiabilidad y precisión
    signal shift_reg_CE            :          std_logic;
    --Habilita al registro serie-paralelo para que sólo capte los bits de datos
    --y no los de parada,paridad o start
    signal cuenta            :          unsigned(3 downto 0);
    --indica el bit por el que vamos en cada momento
    signal bit_pulse            :          std_logic;
    --Es el periodod e transmisión de cada bit
    signal sample_pulse            :          std_logic;
    --La señal cuyo periodo marca el número de muestras
    signal BUSY_r            :          std_logic;
    --Está a nivel alto mientras se transmite un dato
    signal Reg_ok            :          std_logic;
    --Señal de carga del registro paralelo-paralelo
    signal Reg_ok_aux            :          std_logic;
    --señal creada para la detección de flanco positivo de la señal
    --Reg_ok
    signal DATO_RX_AUX            :          std_logic_vector(7 downto 0);
    --Bits de datos agrupados leidos esperando verificación para poder ser 
    --transmitidos  
    signal parity            :          std_logic;
    --producto de la XOR de DATA_RX_AUX, su resultado nos indicará
    --si el dato es par o impar
    signal parity_logic            :          std_logic;
    --XOR de la señal parity con RX_OK que en el momento de la lectura
    --deberá corresponder al bit de paridad.Su resultado indicará si se ha
    --producido algún error
    
    --Las siguientes señales corresponden a:
    --Check: indica que se verifique el estado del bit en cuestión
    --Error: se pondrá a nivel alto si hay algún error de ese tipo
    signal error_parity            :          std_logic := '0';
    signal check_parity            :          std_logic := '0';

    signal error_start            :          std_logic := '0'; 
    signal check_start            :          std_logic := '0'; 
    
    signal error_stop            :          std_logic := '0'; 
    signal check_stop            :          std_logic := '0'; 
    
    
    signal error_recep_aux            :          std_logic;   
    --Es la or de todas las señales anteriores.Si se produce algún error
    --esta señal se pondrá a nivel alto

    constant T_BIT      :         integer := 10416;
    --Es el periodo de cada BIT
    --1/9600 = 104,17us = 10.417*Tclk
    signal   counter_bit :         integer range 0 to T_BIT; 
    
    constant T_sample      :         integer := 2 ;
    --Dividimos entre 2 ya que 

    signal   counter_sampl :         integer range 0 to T_BIT; 
     
    type estadoFSM is (S0,S1,S2,S3,S4);
    signal estado_r: EstadoFSM := S1;
    
    constant T_shift_reg      :         integer := 10416/2 ;
    --Corresponde a medio periodo de bit ya que se usará principalmente para 
    --que se lean ciertos bit en la mitad de su periodo para mayor fiabilidad

begin  -- rtl 





-----------------------------------------------------------------------------------------
--Registro de desplazamiento
process (CLK,RST)
begin
    if RST='1' then
    Q1 <= '1';
    Q2 <= '1';
    Q3 <= '1';
    Q4 <= '1';
    Q5 <= '1';
        elsif CLK'event and CLK='1' then
        if sample_pulse ='1' then
            Q5 <= Q4;
            Q4 <= Q3;
            Q3 <= Q2;
            Q2 <= Q1;
            Q1 <= RX;
        end if; 
   end if;
end process;

--------------------------------------------------------------
    --ASIGNACIONES CONCURRENTES PARA RS
    S <= Q1 and Q2 and Q3 and Q4 and Q5;
    R <= (not Q1) and (not Q2) and (not Q3) and (not Q4) and(not Q5);

--RS
process (CLK,RST)
begin
    if RST='1' then
    RX_OK <= '1';
        elsif CLK'event and CLK='1' then
            if S ='1' and R='0' then
                RX_OK <= '1';
            end if;
            if S ='0' and R='1' then
                RX_OK <= '0';
            end if;
   end if;
end process;

-------------------------------------------------------------------------------------------------------------------

--Prescaler_1	
--secuencial		
process (CLK,RST)                 
    begin  -- process
    if(RST = '1') then
        counter_bit <= 0;
    elsif clk'event and clk = '1' then
        if BUSY_r = '1' then
            if counter_bit = T_bit-1 then     
                counter_bit <= 0;
            else
                counter_bit <= counter_bit+1;
            end if;
        else 
        counter_bit <= 0;
        end if;
    end if;
end process;

process (clk, rst)
    begin  -- process
    if(RST = '1') then
      bit_pulse <= '0';
    elsif clk'event and clk = '1' then
        if (counter_bit = T_bit-1)then      
            bit_pulse <= '1';
        else
            bit_pulse <= '0';
        end if;       
    end if;
end process;

-----------------------------FIN de Prescaler_1-----------------------

--Prescaler_2	
--secuencial		
process (CLK,RST)                 
    begin  -- process
    if(RST = '1') then
        counter_sampl <= 0;
    elsif clk'event and clk = '1' then
        if counter_sampl = T_sample-1 then     
            counter_sampl <= 0;
        else
            counter_sampl <= counter_sampl+1;
        end if;
    end if;
end process;

process (clk, rst)
    begin  -- process
    if(RST = '1') then
      sample_pulse <= '0';
    elsif clk'event and clk = '1' then
        if (counter_sampl = T_sample-1)then      
            sample_pulse <= '1';
        else
            sample_pulse <= '0';
        end if;       
    end if;
end process;


------------------------------------Fin Prescaler_2----------------------------


   process (CLK,RST)            --CONTADOR
   --secuencial
   variable cuenta_aux : integer ;
   --variable necesaria para un preciso funcionamiento del proceso
   --se podría hacer con una señal pero no sería preciso 
   begin
   if RST = '1' then
    cuenta <= (others => '0');
    cuenta_aux := 0;  
    elsif CLK='1' and CLK'event then     
           if bit_pulse = '1' then
           cuenta_aux := cuenta_aux +1;
           end if;
           if cuenta_aux = 11 then
           cuenta_aux := 0;
           end if; 
           cuenta <= (to_unsigned(cuenta_aux,4));     
     end if;
    end process;


---------------------------------------------------------------------------------------
----------XOR
    process(DATO_RX_AUX)
    begin
        parity <= not(DATO_RX_AUX(0) xor DATO_RX_AUX(1) xor DATO_RX_AUX(2) xor DATO_RX_AUX(3) xor DATO_RX_AUX(4) xor DATO_RX_AUX(5) xor DATO_RX_AUX(6) xor DATO_RX_AUX(7));
    end process;
 ---------FSM
     --Secuencial
     process(rst,clk)
     begin
         if (rst='1') then
             estado_r <= S0;
             elsif (clk'event and clk='1') then
                 case estado_r is
                     when S0 =>--STANDBY
                     if RX_OK = '0' then
                        estado_r <= S1;
                     end if;
                     when S1 =>--START
                        estado_r <= S2;
                        
                     when S2 =>--RECEIVING
                     if cuenta = 9 then
                        estado_r <= S3;
                        
                     end if;
                     when S3 =>--CHECK_parity
                     if cuenta = 10  then
                        estado_r <= S4;
                     end if;
                     when S4 =>--CHECK_STOP
                     if cuenta = 0 then
                        estado_r <= S0;
                     end if;
                  end case;
        end if;
     end process;
     
     parity_logic <= parity  xor RX_OK;--Asignacion concurrente
     
     --Combinacional
     process(estado_r) 
        begin -- Cálculo de las salidas
        shift_reg_CE <= '0';
        send <= '0';
        BUSY_r <= '0';
            case estado_r is
            when S0 =>
             --STANDBY
            check_start <= '0';
            check_parity <= '0';
            check_stop <= '0';
            
            send <= '1';
            when S1 =>
            --START    
            check_start <= '1';
            check_parity <= '0';
            check_stop <= '0';

            when S2 =>
            --RECEIVING
            check_start <= '0';
            check_parity <= '0';
            check_stop <= '0';
            
            BUSY_r <= '1';
            shift_reg_CE <= '1';
            
            when S3 =>
            --CHECK_parity
            check_start <= '0';
            check_parity <= '1';
            check_stop <= '0';
            
            BUSY_r <= '1';
            
            when S4 =>
            --CHECK_STOP
            BUSY_r <= '1';
            
            check_start <= '0';
            check_parity <= '0';
            check_stop <= '1';
            
            end case;
     end process;
   -----------------------------------------------------------------------FIN FSM-----------------------------------------------------------------
---------------------------------OR----------------------------
error_recep_aux <= error_stop or error_parity or error_start;
error_recep <= error_recep_aux ;
----------------------------------------CHECKING---------------------------

    process (CLK,RST) 
    --shift register
    --Serie paralelo
    begin
    if RST = '1' then
    error_start <= '0';
    error_stop <= '0';
    error_parity <= '0';
    
        elsif (CLK'event and CLK='1') then
            if shift_reg_ok = '1' then
            if check_start = '1' then
                if RX_OK = '0' then
                error_start <= '0';
                else
                error_start <= '1';
                end if;
            end if;
            if check_stop = '1' then
                if RX_OK = '1' then
                    error_stop <= '0';
                else
                    error_stop <= '1';
                end if;
            end if;
            if check_parity = '1' then
                if parity_logic = '1' then
                    error_parity <= '1';
                else
                    error_parity <= '0';
                end if;
            end if;
            end if;
            
        end if;
    end process;

----------------------------------------------------------------------------------------------------------------------

    process (CLK,RST) 
    --shift register
    --Serie paralelo
    begin
    if RST = '1' then
    tmp <= (others => '0');
        elsif (CLK'event and CLK='1') then
            if shift_reg_CE = '1' then
                if shift_reg_ok = '1' then
                    for i in 6 downto 0 loop
                        tmp(i) <= tmp(i+1);
                    end loop;
                    tmp(7) <= RX_OK;
                end if;
            end if;
        end if;
    end process;
    DATO_RX_AUX <= tmp;

-----------------------------------------------------------

   process (CLK,RST)            --CONTADOR
   --secuencial
   variable cuenta_reg : integer ;
   --variable necesaria para un preciso funcionamiento del proceso
   --se podría hacer con una señal pero no sería preciso 
   --Se carga el valor T_shift_reg que es la mitad del periodo de transmisión
   --para que se tome un valor en el punto medio del periodo que es el más fiable.
   begin
   if RST = '1' then
    cuenta_reg := 0;  
    shift_reg_ok <= '0';
    elsif CLK='1' and CLK'event then     
           if bit_pulse = '1' then
           
           cuenta_reg := T_shift_reg ;
           --cargamos el valor
           end if;
           
           if cuenta_reg > 0 then
           cuenta_reg := cuenta_reg -1;
           end if; 
           
           if cuenta_reg = 1 then
           --cuando llegamos cerca del final, disparamos un periodo de TCLK
           shift_reg_ok <= '1';
           else
           shift_reg_ok <= '0';
           end if;
               
     end if;
    end process;

----------------------------------------------------------------------------------

   process (CLK,RST)   
   --POS_EDGE_DETECT
   --detector de flanco positivo con CE siendo este la entrada
   --error_recep_aux                               
   --secuencial
   begin
   if ( RST = '1') then
    reg_ok <= '0';
    reg_ok_aux <= '0';
   elsif CLK'event and CLK='1' then
        if error_recep_aux = '0' then          
          reg_ok_aux <= send;
          reg_ok <= (send and (not reg_ok_aux));
        end if;
   end if;
   end process;

-----------------------------------------------------------

   process (CLK,RST)                                    --BIESTABLE D
   --secuencial
   begin
   if ( RST = '1') then
    DATO_RX_OK <= '0';
   elsif CLK'event and CLK='1' then          
          DATO_RX_OK <= reg_ok;
   end if;
   end process;

---------------------------------------------------------

-- REGISTRO paralelo-paralelo

process (CLK,RST)
begin
    if RST ='1' then
    DATO_RX <= (others => '0');
      elsif CLK'event and CLK='1' then
        if REG_OK = '1' then
        DATO_RX <= DATO_RX_AUX;
        end if;
   end if;
end process;








end rtl;
