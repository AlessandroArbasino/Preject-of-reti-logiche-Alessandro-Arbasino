--ALESSANDRO ARBASINO
--MATRICOLA 909714
--CODICE PERSONA 10628778
library IEEE;
use IEEE.STD_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity project_reti_logiche is
port( 
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic; 
    i_data : in std_logic_vector (7 downto 0);
    o_address : out std_logic_vector (15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;


architecture behavioral of project_reti_logiche is

type S is (sr,column_state,s1,s2,dim_state,min_state,s5,s6,s7,s9,s10,s11,s12,end_state,new_bit_address_state,address_state,max_state,wait1,increment_state,shift_state,wait4,wait9,wait8,wait14,raw_state,wait3,wait5,wait0,s15,wait7);
signal next_state,  curr_state : S ;
signal n_col : std_logic_vector (7 downto 0);--salvo colonne
signal n_righe : std_logic_vector (7 downto 0);-- salvo righe
signal next_count : std_logic_vector (15 downto 0);
signal next_dim_foto: std_logic_vector (15 downto 0);
signal dim_foto: std_logic_vector (15 downto 0);
signal max : std_logic_vector (7 downto 0):="00000000";
signal min : std_logic_vector (7 downto 0):="11111111";
signal current_address : std_logic_vector (15 downto 0);
signal next_current_address : std_logic_vector (15 downto 0):="0000000000000000";
signal delta_value : std_logic_vector (8 downto 0);
signal value_log : std_logic_vector ( 9 downto 0) ;
signal next_value_log : std_logic_vector ( 9 downto 0) ;
signal log : std_logic_vector (4 downto 0);
signal next_log : std_logic_vector (4 downto 0);
signal shift_level : std_logic_vector (3 downto 0);
signal volte_shift : std_logic_vector (3 downto 0);
signal next_volte_shift : std_logic_vector (3 downto 0);
signal temp_pixel : std_logic_vector (15 downto 0);
signal next_temp_pixel : std_logic_vector (15 downto 0);
signal new_pixel_value : std_logic_vector (7 downto 0);
signal comparison : std_logic_vector (7 downto 0):="11111111";--per fare il min di new pixel value
signal n16_righe : std_logic_vector (15 downto 0);
signal count : std_logic_vector (15 downto 0);

 begin 
process(i_clk,i_rst)
begin 
if i_rst = '1'  or i_start = '0' then 
    curr_state<=sr;
   o_address<="0000000000000000";
    dim_foto<="0000000000000000";
    current_address<="0000000000000000";
     value_log<="0000000001";
     log<="00001";
     volte_shift<="0000";
    temp_pixel<="0000000000000000";
    count<="0000000000000000";
elsif i_clk'event and i_clk = '1' then 
    curr_state<=next_state;  
     count<=next_count; 
     dim_foto<=next_dim_foto;
    current_address<=next_current_address;
    o_address<=next_current_address;
    temp_pixel<=next_temp_pixel;
      log<=next_log;
      volte_shift<=next_volte_shift;  
      value_log<=next_value_log;
      
      
end if;
end process;

process (curr_state,i_start,count)
begin 
             case curr_state is 
                 
                 when sr =>
                     
                       min<="11111111";
                       max<="00000000";
                       o_we <='0';
                       o_done<= '0';     
                       o_en<='1';
         -- start ricevuto
                      if i_start = '1' then
                          next_state<=column_state;
                       else 
                          next_state<=wait0;
                       end if;
                when wait0=>
                    next_current_address<="0000000000000000";
                    next_state<=column_state;
                when column_state =>--salvo il dato colonna  e incremento address
                    o_en<='0';
                    n_col<=i_data;
                    next_current_address <= "0000000000000001" ;
                    next_state<=wait1;
                    
                when wait1 =>--attendo risposta dalla meoria 
                    o_en<='1';
                    next_state<=s1;
                    if (to_integer(unsigned(n_col))) = 0 then-- gestisco corner case di foto rettilinea
                          next_state<=end_state;
                    else
                        next_state<=s1;
                      end if;
               when s1 =>--salvo il numero di righe 
                    next_state<=raw_state;
               when raw_state=> 
                    n_righe<= i_data;
                    next_state<=s2;
               when s2 =>
                    o_en<='0';
                    if (to_integer(unsigned(n_righe))) = 0 then-- gestisco corner case di foto rettilinea
                          next_state<=end_state;
                    else
                        next_state<=s1;
                      end if;
                    next_dim_foto<= "00000000"& n_righe;--valore iniziale della dimensione dell immagine  immagine 
                    next_count<="00000000"& n_col ;--quante volte itererò la somma 
                    n16_righe<="00000000"& n_righe;
                    next_state<=dim_state;
               when wait3 =>
                    next_state<=dim_state;
               when dim_state => 
                     if (to_integer(unsigned(count))) = 1 then
                        next_state<=wait4;
                        next_current_address<="0000000000000010";
                     else 
                        next_dim_foto<= dim_foto + n16_righe;--calcolo la dimensione della foto
                        next_count<=count-"0000000000000001";
                         next_state<=wait3;
                    end if ;
               when wait4=>
                    o_en<='1';
                    next_state<=wait5;
               when wait5=>
                    next_state<=min_state;
               when min_state=>--calcolo il minimo 
                    if (to_integer(unsigned(min))) > (to_integer(unsigned(i_data))) then
                            min<=i_data;
                    end if;
                    next_state<=max_state;
               when max_state=>--calcolo il massimo
                    if (to_integer(unsigned(max))) < (to_integer(unsigned(i_data))) then
                            max<=i_data;
                    end if;
                    next_state<=address_state;
               when address_state =>--cambio il pixel in lettura
                    next_current_address<=current_address+"0000000000000001";
                    if (to_integer(unsigned(current_address))) = ((to_integer(unsigned(dim_foto)))+2) then--ultimo valore dell'immagine 
                            next_state<=s5;
                    else 
                            next_state<=min_state;
                    end if;
               when s5 =>--inizio computo del logaritmo
                    o_en<='0';
                    next_log<="00000";
                    next_value_log<="0000000001";
                    delta_value<="0"& (max-min);--fare una cosa a parte e mettere un bit a 0 in piu e fare delta value a 9 bit
                    next_state<=s6;
              when s6=>                     
                    if ((to_integer(unsigned(delta_value)))+1) >=(to_integer(unsigned(value_log))) then--trovo il valore del logaritmo
                           next_state<=increment_state;
                    else 
                          next_state<=wait7;
                        end if;
             when increment_state=>
                   next_value_log<=value_log(8 downto 0) & "0"; --valore del logaritmo 
                   next_log<=log+"00001";-- incremento del valore effettivo del logaritmo
                   next_state<=s6;
             when wait7=>
                   next_log<=log-"00001";--eseguo il floor
                   next_state<=s7;
            when s7=>
                   o_en<='1';
                   shift_level<="1000"-log(3 downto 0);
                   next_current_address<="0000000000000010";
                   next_state<=wait8;
            when wait8=>--aspetto la memoria 
                   next_state<=wait9;
            when wait9=>
                   next_state<=s9;
            when s9 =>
                   o_en<='1';
                   next_temp_pixel<="00000000" & (i_data-min);--temp pixel al ciclo 0
                   next_volte_shift<= shift_level;--contatore delle iterazioni di shift
                   next_state <= s10 ;
           when s10=>
                   if (to_integer(unsigned(volte_shift)))=0 then
                            o_en<='1';
                            next_state<=s11;
                   else 
                            next_state<=shift_state;
                  end if ;
          when shift_state=>
                  next_temp_pixel<=temp_pixel(14 downto 0) & "0";--effettivo shift
                  next_volte_shift<=volte_shift-"001";--decremento il contatore 
                  next_state<=s10;
          when s11 =>
                  if (to_integer(unsigned(temp_pixel))) > (to_integer(unsigned(comparison))) then--ultimo confronto
                             new_pixel_value<="11111111";
                  else 
                            new_pixel_value <= temp_pixel(7 downto 0);
                  end if;
                  next_state<=s12;
          when s12 =>
                  o_data<=new_pixel_value;
                  next_current_address<= current_address+dim_foto;--indirizzo indirizzo di memoria corrspondente al new_pixel_value
                  if current_address+dim_foto /= "0000000000000010"+dim_foto+dim_foto then --massima dimensione della memoria alla fine di una computazione 
                            next_state<=wait14;
                  else 
                            next_state<= end_state;
                  end if;
          when end_state =>
                  o_done<='1';
                  next_state<=sr;
          when wait14=>
                  o_we<='1';--abilito scrittura
                  next_state<=new_bit_address_state;
         when new_bit_address_state =>
                  o_en<='1';
                  next_current_address<=current_address-dim_foto+"0000000000000001";--indirizzo del nuovo bit che iniziarà la computazione 
                  next_state<= s15;
         when s15=>
                  o_we<='0';
                  next_state<= wait8;
      end case; 
end process ;
end behavioral;

      
        
            
      
