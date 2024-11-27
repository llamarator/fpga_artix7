library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_controller is
  port(RST        : in  std_logic;
       CLK        : in  std_logic;
       DATO_RX_OK : in  std_logic;
       DATO_RX    : in  std_logic_vector(7 downto 0);
       DP         : out std_logic;
       SEG_AG     : out std_logic_vector(6 downto 0);  -- gfedcba
       AND_30     : out std_logic_vector(3 downto 0));
end display_controller;

architecture rtl of display_controller is

    signal DATA_aux             :          std_logic_vector (7 downto 0);
    --señal que almacena el dato previo al que acaba de llegar
    signal reg_out        :                std_logic_vector (7 downto 0);
    --señal correspondiente a la salida re Registro_1
    --tendrá el valor del dato actual al valor de DATO_RX
    signal reg_out_tmp    :                std_logic_vector (7 downto 0);   
    --Se usa para modificar la señal del registro_1 para luego asignarla
    --a reg_out
    signal DATO_RX_OK_aux       :          std_logic := '0';
    --señal de carga para el registro_1 generada por registro_2
    signal MUX_OUT              :          std_logic_vector (3 downto 0);
    --Señal de salida de MUX_1
    signal MUX_aux              :          unsigned (1 downto 0) := "00";
    --señal de salida del contador MUX que lleva el periodo de encendido
    --de cada transistor y es la que selecciona el nº hexadecimal que se 
    --va a visualizar
    signal Tc                   :          std_logic;
    --pulso de ciclo de trabajo de 1 TCLK y periodo 2,5ms
    signal T_DISPL              :          std_logic;
    --pulso de ciclo de trabajo de 1 TCLK y periodo 720ms
    signal SEL                  :          std_logic;
    --Entrada que controla el bloque de displays que está activo en cada mommento
    --varía cada vez que T_DISPL se pone a nivel alto
    signal AND_30_aux           :          std_logic_vector(3 downto 0);
    --Selecciona el transistor de encendido pero hay que aplicarle el filtro de los bloques
    --posteriormente
    
    signal cuenta_aux           :          integer := 0;
    --señal utilizada para contar hasta 4 que es el número de posibilidades
    --de selección de MUX_1.Posteriormente se convertirá a unsigned en MUX_aux
    --ya que al ser integer  no puede ser aceptada como valor de entrada por el multiplexor. 
    
    constant CTE_ANDS           :          integer :=  100;
    --constant CTE_ANDS           :          integer :=  250000;
    --CTE_ANDS indica el tiempo de refresco del encendido
    --de los transistores,basado en el nºpuesto de lab,en mi caso 10ms
    --como 10ms es el tiempo de refresco habiendo pasado por los 4 transistores
    --el tiempo para cada transistor es 10ms/4 y lo dividimos a razón:
    -- ((10/4)*10^(-3))/(10*10^(-9)) = 250000

    constant CTE_DISP           :         integer :=  720;
    --constant CTE_DISP           :         integer :=  72000000;
    --El valor viene dado por mi letra del DNI:Z 0x90 cuyo valor decimal es 144 que por 5
    --es 720ms aprovechando, creamos un nuevo prescaler y mediante la ecuación
    -- ((720)*10^(-3))/(10*10^(-9)) = 72000000 
    signal   counter_tran       :         integer range 0 to CTE_ANDS;
    signal   counter_disp       :         integer range 0 to CTE_DISP;

begin  -- 
DP <= '1';

--------------------------------------------------------------------------------------------------------
-- REGISTRO_1

process (CLK,RST)
begin
    if RST ='0' then
      if CLK'event and CLK='1' then
        if DATO_RX_OK_aux = '1' then
        reg_out_tmp(7) <= DATO_RX(7);
        reg_out_tmp(6) <= DATO_RX(6);
        reg_out_tmp(5) <= DATO_RX(5);
        reg_out_tmp(4) <= DATO_RX(4);
            --
        reg_out_tmp(3) <= DATO_RX(3);
        reg_out_tmp(2) <= DATO_RX(2);
        reg_out_tmp(1) <= DATO_RX(1);
        reg_out_tmp(0) <= DATO_RX(0);
        end if;
      end if;
      else
      reg_out_tmp <= (others => '0');
   end if;
end process;
reg_out <= reg_out_tmp;


--------------------------------------------------------------------------------------------------------

   --REGISTRO_2
    --secuencial
    process(CLK,RST)       --REGISTRO 
    --La función de DATO_RX_OK_aux es dejar un retardo de un periodo de reloj para que el registro_2
    --pueda guardar el valor de reg_out ofrecido por el registro_1 antes que este ponga a su salida el nuevo dato.
    begin
    
     if RST = '1' then
     DATA_aux <= (others => '0');
        elsif (CLK'event and CLK = '1') then
        DATO_RX_OK_aux <= '0';
            if(DATO_RX_OK = '1') then
            DATA_aux <= reg_out;      
            DATO_RX_OK_aux <= '1';
            end if;
    end if;

    end process;



---------------------------------PRESCALER  Tc-------------------------------------------
	  process (CLK,RST)                 --Es un divisor de frecuencia para Tc
begin  -- process
 
  if clk'event and clk = '1' then
    if counter_tran = CTE_ANDS-1 then      --Es un contador simple que se resetea sólo
      counter_tran <= 0;

    else
      counter_tran <= counter_tran+1;
    end if;
    end if;
    
end process;

--CONTADOR Tc
process (clk, rst)
begin  

  if clk'event and clk = '1' then
    if counter_tran = CTE_ANDS-1 then      
      Tc <= '1';
    else
      Tc <= '0';
    end if;
    end if;
end process;

---------------------------------FIN PRESCALER  Tc-------------------------------------------

--CONTADOR MUX GENERADOR DE CUENTA
   process (CLK,RST)            
begin
if RST = '1' then
 cuenta_aux <= 0;
 else
    if CLK='1' and CLK'event then   
       if Tc = '1' then
            if(cuenta_aux >= 0)  then
            cuenta_aux <= cuenta_aux + 1;
            end if;
            if(cuenta_aux >= 3)  then
            cuenta_aux <= 0;
            end if;
        end if;
      end if;
     end if;
end process;
     MUX_aux <= to_unsigned(cuenta_aux,2); 
    --asignación concurrente


---------------------------------PRESCALER  T_DISPL-------------------------------------------

process (clk, rst)
begin  -- process

  if clk'event and clk = '1' then
    if counter_disp = CTE_DISP-1 then      
      counter_disp <= 0;
    else
      counter_disp <= counter_disp+1;
    end if;
    end if;
end process;

--CONTADOR T_DISPL
process (clk, rst)
begin  -- process

  if clk'event and clk = '1' then
    if counter_disp = CTE_DISP-1 then      
      T_DISPL <= '1';
    else
      T_DISPL <= '0';
    end if;
    end if;
end process;

---------------------------------FIN PRESCALER  T_DISPL-------------------------------------------

--BIESTABLE TIPO T
process (CLK,RST)
begin
   if CLK'event and CLK='1' then
      if RST='1' then
         SEL <= '0';
      elsif T_DISPL ='1' then
         SEL <= not(SEL);
      end if;
   end if;
end process;



--MUX_2
process (SEL,AND_30_aux)
--En este bloque damos el valor final de AND_30 usando las entradas SEL y AND_30_aux
--teniendo en cuenta que hay que encender los displays en bloques de dos
--Tiene el comportamiento de un multiplexor de 1 bit de selección.
begin
   case SEL is
      when '0' => 
      AND_30(0) <= AND_30_aux(0);
      AND_30(1) <= AND_30_aux(1);
      AND_30(2) <= '1';
      AND_30(3) <= '1';
      when '1' =>
      AND_30(0) <= '1';
      AND_30(1) <= '1';
      AND_30(2) <= AND_30_aux(2);
      AND_30(3) <= AND_30_aux(3);
      when others => AND_30 <= "1111";
   end case;
end process;









--MULTIPLEXOR MUX_OUT
   process (DATA_aux,reg_out,MUX_aux)
   begin
     --MUX_aux corresponde a la salida del contador 
     --Lo hemos pasado previamente a unsigned ya que 
     --El multiplexor no admite valores de entrada integers.
     --Seleccionamos 4 de los 8 bits de salida de cada registro
     --en cada momento y lo conmutamos a la salida dependiendo de
     --el estado de MUX_aux
      case MUX_aux is
         when "00" =>
         MUX_OUT(0) <= reg_out(0);
         MUX_OUT(1) <= Reg_out(1);
         MUX_OUT(2) <= reg_out(2);
         MUX_OUT(3) <= reg_out(3);
         when "01" =>
         MUX_OUT(0) <= reg_out(4);
         MUX_OUT(1) <= reg_out(5);
         MUX_OUT(2) <= reg_out(6);
         MUX_OUT(3) <= reg_out(7);
         
         
         when "10" => 
         MUX_OUT(0) <= DATA_aux(0);
         MUX_OUT(1) <= DATA_aux(1);
         MUX_OUT(2) <= DATA_aux(2);
         MUX_OUT(3) <= DATA_aux(3);
         when "11" =>
         MUX_OUT(0) <= DATA_aux(4);
         MUX_OUT(1) <= DATA_aux(5);
         MUX_OUT(2) <= DATA_aux(6);
         MUX_OUT(3) <= DATA_aux(7);
         

         when others => MUX_OUT <= "0000";
      end case;
   end process;


--DECODER DISPLAY
process(MUX_OUT)
begin

         case MUX_OUT is
         when "0000" =>
                  --gfedcba
         SEG_AG <= "1000000"; --0
         when "0001" =>
         SEG_AG <= "0000110"; --1
         when "0010" =>
         SEG_AG <= "0100100"; --2
         when "0011" =>
         SEG_AG <= "0110000"; --3
         when "0100" =>
         SEG_AG <= "0011001"; --4
         when "0101" =>
         SEG_AG <= "0010010"; --5
         when "0110" =>
         SEG_AG <= "0000010"; --6
         when "0111" =>
         SEG_AG <= "1111000"; --7
         when "1000" =>
         SEG_AG <= "0000000"; --8
         when "1001" =>
         SEG_AG <= "0010000"; --9
         when "1010" =>
         SEG_AG <= "0001000"; --A
         when "1011" =>
         SEG_AG <= "0000011"; --B
         when "1100" =>
         SEG_AG <= "1000110"; --C
         when "1101" =>
         SEG_AG <= "0100001"; --D
         when "1110" =>
         SEG_AG <= "0000110"; --E
         when "1111" =>
         SEG_AG <= "0001110"; --F
         when others =>
         SEG_AG <= "1111111"; --null

         end case;

end process;


--DECODER ACTIVADOR DE DISPLAYS
process(MUX_aux)
begin
      --como son pnp se activan a nivel bajo
      
         case MUX_aux is
            when "00" =>
             AND_30_aux <= "1110";
            when "01" =>
             AND_30_aux <= "1101";
            when "10" => 
             AND_30_aux <= "1011";
            when "11" =>
             AND_30_aux <= "0111";
            when others => AND_30_aux <= "1111";
         end case;

end process;





end;
