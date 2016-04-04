----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package MTR_STANDARD_PKG is 
  component MTR_STANDARD is
		generic (
			CHANNEL : integer;
			PULSE_LEN : integer;
			DIR_CW : STD_LOGIC;
      ACTIVE : STD_LOGIC
		); 	
		port (
			CLK:  	 	   in STD_LOGIC;
			RST: 			   in STD_LOGIC;
			DIR:  			in STD_LOGIC;
			STEP: 			in STD_LOGIC;
			CW_LIM:   	 	in STD_LOGIC_VECTOR(0 to 15);
			CCW_LIM:  	 	in STD_LOGIC_VECTOR(0 to 15);         
			AUX1_LIM: 	 	in STD_LOGIC_VECTOR(0 to 15);        
			AUX2_LIM:  	  	in STD_LOGIC_VECTOR(0 to 15);
      SDL_CW_LIM: 	in STD_LOGIC_VECTOR(0 to 15);        
      SDL_CCW_LIM:  in STD_LOGIC_VECTOR(0 to 15);
			INP :				in STD_LOGIC_VECTOR(0 to 7);
			OUTP :			out STD_LOGIC_VECTOR(0 to 7);
			DOUT :			out STD_LOGIC_VECTOR(0 to 15);
      DRVR_CW, DRVR_CCW	: out STD_LOGIC;
	    IND_AUXA_LIM : out STD_LOGIC_VECTOR(0 to 15);		
		  IND_AUXB_LIM : out STD_LOGIC_VECTOR(0 to 15);								
      IND_CW_STEP, IND_CCW_STEP, IND_CW_LIM, IND_CCW_LIM: out STD_LOGIC;
      IDXR_CW_LIM, IDXR_CCW_LIM: out STD_LOGIC;
      POSITION : out STD_LOGIC_VECTOR(31 downto 0)
		);	    
	end component;
end package MTR_STANDARD_PKG; 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity MTR_STANDARD is
                                               
	generic (
		CHANNEL : integer := -1;
		PULSE_LEN : integer := -1;
		DIR_CW : STD_LOGIC := '1';
		ACTIVE : STD_LOGIC := '1'
	); 
	
	port (
		CLK	: 		in STD_LOGIC;
		RST	: 		in STD_LOGIC;
		DIR:  		in STD_LOGIC;
		STEP: 		in STD_LOGIC;
		CW_LIM:   	in STD_LOGIC_VECTOR(0 to 15);
		CCW_LIM:  	in STD_LOGIC_VECTOR(0 to 15);         
		AUX1_LIM: 	in STD_LOGIC_VECTOR(0 to 15);        
		AUX2_LIM:  	in STD_LOGIC_VECTOR(0 to 15);
    SDL_CW_LIM: 	in STD_LOGIC_VECTOR(0 to 15);        
    SDL_CCW_LIM:  in STD_LOGIC_VECTOR(0 to 15);
		INP :			in STD_LOGIC_VECTOR(0 to 7);
		OUTP :		out STD_LOGIC_VECTOR(0 to 7);
		DOUT :		out STD_LOGIC_VECTOR(0 to 15);
		DRVR_CW, DRVR_CCW	: out STD_LOGIC;
    IND_AUXA_LIM : out STD_LOGIC_VECTOR(0 to 15);		
    IND_AUXB_LIM : out STD_LOGIC_VECTOR(0 to 15);						
		IND_CW_STEP, IND_CCW_STEP, IND_CW_LIM, IND_CCW_LIM	: out STD_LOGIC;
		IDXR_CW_LIM, IDXR_CCW_LIM: out STD_LOGIC;
		POSITION : out STD_LOGIC_VECTOR(31 downto 0)
	);	    
end	MTR_STANDARD;

architecture behavioral of MTR_STANDARD is
	constant PULSE_CNT_LEN : integer := integer(ceil(log2(real(PULSE_LEN))));
	signal   PULSE_CNT : STD_LOGIC_VECTOR(PULSE_CNT_LEN-1 downto 0);
	constant PULSE_CNT_IC : STD_LOGIC_VECTOR(PULSE_CNT_LEN-1 downto 0) := conv_std_logic_vector(PULSE_LEN-1, PULSE_CNT_LEN);
	constant PULSE_CNT_TC : STD_LOGIC_VECTOR(PULSE_CNT_LEN-1 downto 0) := (others => '0');

	signal CCW_AUX_DISABLE, CW_AUX_DISABLE: STD_LOGIC;
	signal CCW_STEP_DISABLE, CW_STEP_DISABLE: STD_LOGIC;
	
  signal OUT_PULSE_CW:  STD_LOGIC;
  signal OUT_PULSE_CCW: STD_LOGIC;

--	signal DINT: STD_LOGIC;
                                      
  begin
  
	-- limit logic -------------------------------------------------------
   -- step disable signal combines Lim and Aux limits state influence on 
	-- on motor step pulses and signals indication
	----------------------------------------------------------------------
	CCW_AUX_DISABLE <=  ACTIVE when AUX1_LIM(CHANNEL) = ACTIVE else
                      ACTIVE when AUX2_LIM(CHANNEL) = ACTIVE else
                      not ACTIVE ; 
	CW_AUX_DISABLE <=   ACTIVE when AUX1_LIM(CHANNEL) = ACTIVE else
                      ACTIVE when AUX2_LIM(CHANNEL) = ACTIVE else
                      not ACTIVE ; 

	CCW_STEP_DISABLE <= ACTIVE when CCW_LIM(CHANNEL) = ACTIVE or CCW_AUX_DISABLE = ACTIVE else not ACTIVE;
	CW_STEP_DISABLE  <= ACTIVE when  CW_LIM(CHANNEL) = ACTIVE or  CW_AUX_DISABLE = ACTIVE else not ACTIVE;
  -- limit logic ends ---------------------------------------------------
  -----------------------------------------------------------------------
  
   -- Motor pulses generation
   -- 1. Pulse length from step pulse and delay---
	
	PULSE_CNT_PROC : process (CLK) 
	begin
		if CLK'event and CLK = '1' then
			if RST = '1' then
				PULSE_CNT <= PULSE_CNT_TC;
			elsif STEP = ACTIVE then
				PULSE_CNT <= PULSE_CNT_IC;
			elsif PULSE_CNT /= PULSE_CNT_TC then
				PULSE_CNT <= PULSE_CNT - 1; 
			end if;
		end if;
	end process;
	
   -- 2. DRVR_CW from pulse length, STEP, DIR and combined CW_DISABLE: 
	
	DRVR_CW_PROC : process (CLK)  
	begin
		if CLK'event and CLK = '1' then
			if RST = '1' then
				   OUT_PULSE_CW <= not ACTIVE;
			elsif STEP = ACTIVE and DIR = DIR_CW and CW_STEP_DISABLE = not ACTIVE then
				   OUT_PULSE_CW <= ACTIVE;				
			elsif PULSE_CNT = PULSE_CNT_TC then
				   OUT_PULSE_CW <= not ACTIVE;				
			end if;
		end if;
	end process;

   -- 3. DRVR_CCW from pulse length, STEP, DIR and combined CCW_DISABLE:
 	
	DRVR_CCW_PROC : process (CLK)   

	begin
		if CLK'event and CLK = '1' then
			if RST = '1' then
				   OUT_PULSE_CCW <= not ACTIVE;
			elsif STEP = ACTIVE and DIR = not DIR_CW and CCW_STEP_DISABLE = not ACTIVE then
				   OUT_PULSE_CCW <= ACTIVE;				
			elsif PULSE_CNT = PULSE_CNT_TC then
				   OUT_PULSE_CCW <= not ACTIVE;				
			end if;
		end if;
	end process;
 -------------------------------------------------
 -- outputs generation
 
	OUTP <= INP;
--  DINT <= INP(0) xor INP(1) xor INP(2) xor INP(3);
--	DOUT <= (others => DINT);
  DOUT <= AUX1_LIM;
	
	IND_CCW_STEP <= OUT_PULSE_CCW; 	
	IND_CW_STEP <= OUT_PULSE_CW;   

   DRVR_CCW <=	OUT_PULSE_CCW;
   DRVR_CW <=	OUT_PULSE_CW;
	
	IND_CCW_LIM <= CCW_STEP_DISABLE;
	IND_CW_LIM  <= CW_STEP_DISABLE;
  
--  IND_AUX_GEN: for i in 0 to 15 generate 
--    CH_EQ_AUX_GEN: if i = CHANNEL generate
--      IND_AUXA_LIM(CHANNEL) <= CCW_AUX_DISABLE;
--      IND_AUXB_LIM(CHANNEL) <= CW_AUX_DISABLE;
--    end generate;
--    CH_NE_AUX_GEN: if i /= CHANNEL generate
--      IND_AUXA_LIM(CHANNEL) <= '0';
--      IND_AUXB_LIM(CHANNEL) <= '0';
--    end generate;
--  end generate;

  IND_AUX_PROC: process (AUX1_LIM, AUX2_LIM)
  begin
    IND_AUXA_LIM(CHANNEL) <= AUX1_LIM(CHANNEL);
    IND_AUXB_LIM(CHANNEL) <= AUX2_LIM(CHANNEL);
    if CHANNEL /= 0 then
      IND_AUXA_LIM(0 to CHANNEL-1) <= (others => '0');
      IND_AUXB_LIM(0 to CHANNEL-1) <= (others => '0');
    end if;
    if CHANNEL /= 15 then
      IND_AUXA_LIM(CHANNEL+1 to 15) <= (others => '0');
      IND_AUXB_LIM(CHANNEL+1 to 15) <= (others => '0');
    end if;
  end process;

	IDXR_CCW_LIM <= CCW_STEP_DISABLE;	
	IDXR_CW_LIM <= CW_STEP_DISABLE;
  
  POSITION <= (others => '0');
 
end behavioral;

 
  
  
  
  