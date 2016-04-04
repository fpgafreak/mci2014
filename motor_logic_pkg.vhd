----------------------------------------------------------------------------------
-- 
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package MOTOR_LOGIC_PKG is
  component MOTOR_LOGIC is
		generic (
			DIR_CW : STD_LOGIC;
			ACTIVE : STD_LOGIC
		);
		port (
			CLK : in  STD_LOGIC;
			RST : in  STD_LOGIC;
			IDXR_DIR : in  STD_LOGIC_VECTOR (0 to 15);
			IDXR_STEP : in  STD_LOGIC_VECTOR (0 to 15);
			CCW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
			CW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
			AUX1_LIM : in  STD_LOGIC_VECTOR (0 to 15);
			AUX2_LIM : in  STD_LOGIC_VECTOR (0 to 15);
			SDL_CCW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
			SDL_CW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
			INP : in  STD_LOGIC_VECTOR (0 to 7);
			OUTP : out  STD_LOGIC_VECTOR (0 to 7);			  
			DOUT : out  STD_LOGIC_VECTOR (0 to 15);			  
			DRVR_CW : out  STD_LOGIC_VECTOR (0 to 15);
			DRVR_CCW : out  STD_LOGIC_VECTOR (0 to 15);
			IND_CW_STEP : out  STD_LOGIC_VECTOR (0 to 15);
			IND_CCW_STEP : out  STD_LOGIC_VECTOR (0 to 15);
			IND_CW_LIM : out  STD_LOGIC_VECTOR (0 to 15);
			IND_CCW_LIM : out  STD_LOGIC_VECTOR (0 to 15);
			IND_AUXA_LIM : out  STD_LOGIC_VECTOR (0 to 15):=(others=>'0');
			IND_AUXB_LIM : out  STD_LOGIC_VECTOR (0 to 15):=(others=>'0');
			IDXR_CW_LIM: out  STD_LOGIC_VECTOR (0 to 15);
			IDXR_CCW_LIM: out  STD_LOGIC_VECTOR (0 to 15)
		);
  end component;
end MOTOR_LOGIC_PKG;

  
 library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

 use work.MTR_STANDARD_PKG.all;
 
entity MOTOR_LOGIC is
		generic (
			DIR_CW : STD_LOGIC := '1';
			ACTIVE : STD_LOGIC := '1'
		);
  port (
		CLK : in  STD_LOGIC;
		RST : in  STD_LOGIC;
		IDXR_DIR : in  STD_LOGIC_VECTOR (0 to 15);
		IDXR_STEP : in  STD_LOGIC_VECTOR (0 to 15);
		CCW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
		CW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
		AUX1_LIM : in  STD_LOGIC_VECTOR (0 to 15);
		AUX2_LIM : in  STD_LOGIC_VECTOR (0 to 15);
    SDL_CCW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
    SDL_CW_LIM : in  STD_LOGIC_VECTOR (0 to 15);
		INP : in  STD_LOGIC_VECTOR (0 to 7);
		OUTP : out  STD_LOGIC_VECTOR (0 to 7);			  
		DOUT : out  STD_LOGIC_VECTOR (0 to 15);			  
		DRVR_CW : out  STD_LOGIC_VECTOR (0 to 15);
		DRVR_CCW : out  STD_LOGIC_VECTOR (0 to 15);
		IND_CW_STEP : out  STD_LOGIC_VECTOR (0 to 15);
		IND_CCW_STEP : out  STD_LOGIC_VECTOR (0 to 15);
		IND_CW_LIM : out  STD_LOGIC_VECTOR (0 to 15);
		IND_CCW_LIM : out  STD_LOGIC_VECTOR (0 to 15);
		IND_AUXA_LIM : out  STD_LOGIC_VECTOR (0 to 15);
		IND_AUXB_LIM : out  STD_LOGIC_VECTOR (0 to 15);
		IDXR_CW_LIM: out  STD_LOGIC_VECTOR (0 to 15);
		IDXR_CCW_LIM: out  STD_LOGIC_VECTOR (0 to 15)		  
	);
end MOTOR_LOGIC;


architecture structural of MOTOR_LOGIC is
 
--	signal CH0_OUTP, CH1_OUTP, CH2_OUTP, CH3_OUTP : STD_LOGIC_VECTOR (0 to 7);
--	signal CH4_OUTP, CH5_OUTP, CH6_OUTP, CH7_OUTP : STD_LOGIC_VECTOR (0 to 7);
--	signal CH8_OUTP, CH9_OUTP, CH10_OUTP, CH11_OUTP : STD_LOGIC_VECTOR (0 to 7);
--	signal CH12_OUTP, CH13_OUTP, CH14_OUTP, CH15_OUTP : STD_LOGIC_VECTOR (0 to 7);
--
--	signal CH0_DOUT, CH1_DOUT, CH2_DOUT, CH3_DOUT : STD_LOGIC_VECTOR (0 to 15);
--	signal CH4_DOUT, CH5_DOUT, CH6_DOUT, CH7_DOUT : STD_LOGIC_VECTOR (0 to 15);
--	signal CH8_DOUT, CH9_DOUT, CH10_DOUT, CH11_DOUT : STD_LOGIC_VECTOR (0 to 15);
--	signal CH12_DOUT, CH13_DOUT, CH14_DOUT, CH15_DOUT : STD_LOGIC_VECTOR (0 to 15);
--
--	signal CH0_IND_AUXA, CH1_IND_AUXA, CH2_IND_AUXA, CH3_IND_AUXA : STD_LOGIC_VECTOR (0 to 15);
--	signal CH4_IND_AUXA, CH5_IND_AUXA, CH6_IND_AUXA, CH7_IND_AUXA : STD_LOGIC_VECTOR (0 to 15);
--	signal CH8_IND_AUXA, CH9_IND_AUXA, CH10_IND_AUXA, CH11_IND_AUXA : STD_LOGIC_VECTOR (0 to 15);
--	signal CH12_IND_AUXA, CH13_IND_AUXA, CH14_IND_AUXA, CH15_IND_AUXA : STD_LOGIC_VECTOR (0 to 15);
--
--	signal CH0_IND_AUXB, CH1_IND_AUXB, CH2_IND_AUXB, CH3_IND_AUXB : STD_LOGIC_VECTOR (0 to 15);
--	signal CH4_IND_AUXB, CH5_IND_AUXB, CH6_IND_AUXB, CH7_IND_AUXB : STD_LOGIC_VECTOR (0 to 15);
--	signal CH8_IND_AUXB, CH9_IND_AUXB, CH10_IND_AUXB, CH11_IND_AUXB : STD_LOGIC_VECTOR (0 to 15);
--	signal CH12_IND_AUXB, CH13_IND_AUXB, CH14_IND_AUXB, CH15_IND_AUXB : STD_LOGIC_VECTOR (0 to 15);	
	
  ----------------------------------	

  type OUTP_ARRAY_TYPE is array (0 to 15) of STD_LOGIC_VECTOR (0 to 7);
  signal OUTP_ARRAY : OUTP_ARRAY_TYPE;

  type DOUT_ARRAY_TYPE is array (0 to 15) of STD_LOGIC_VECTOR (0 to 15);
  signal DOUT_ARRAY : DOUT_ARRAY_TYPE;

  type IND_ARRAY_TYPE is array (0 to 15) of STD_LOGIC_VECTOR (0 to 15);
  signal IND_AUXA_ARRAY : IND_ARRAY_TYPE;
  signal IND_AUXB_ARRAY : IND_ARRAY_TYPE;
  
  constant DEF_PULSE_LEN : integer := 288;

begin

	MOTOR_GEN: for i in 0 to 15 generate

		-- channel 0 begin
		CH0_GEN: if i = 0 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
    -- channel 0 end
		
		-- channel 1 begin
		CH1_GEN: if i = 1 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 1 end

		-- channel 2 begin
		CH2_GEN: if i = 2 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 2 end

		-- channel 3 begin
		CH3_GEN: if i = 3 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 3 end

		-- channel 4 begin
		CH4_GEN: if i = 4 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 4 end

		-- channel 5 begin
		CH5_GEN: if i = 5 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 5 end

		-- channel 6 begin
		CH6_GEN: if i = 6 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 6 end

		-- channel 7 begin
		CH7_GEN: if i = 7 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 7 end

		-- channel 8 begin
		CH8_GEN: if i = 8 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 8 end

		-- channel 9 begin
		CH9_GEN: if i = 9 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 9 end

		-- channel 10 begin
		CH10_GEN: if i = 10 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 10 end

		-- channel 11 begin
		CH11_GEN: if i = 11 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 11 end

		-- channel 12 begin
		CH12_GEN: if i = 12 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 12 end

		-- channel 13 begin
		CH13_GEN: if i = 13 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 13 end

		-- channel 14 begin
		CH14_GEN: if i = 14 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 14 end

		-- channel 15 begin
		CH15_GEN: if i = 15 generate
			MOTOR_INST: MTR_STANDARD
				generic map (
					CHANNEL => i, 
					PULSE_LEN => DEF_PULSE_LEN,
          DIR_CW => DIR_CW,
					ACTIVE => ACTIVE 
				)
				port map (
					-- inputs
					CLK => CLK, RST => RST,
					DIR => IDXR_DIR(i), STEP => IDXR_STEP(i),
					CW_LIM => CW_LIM, CCW_LIM => CCW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
          SDL_CW_LIM => SDL_CW_LIM, SDL_CCW_LIM => SDL_CCW_LIM, INP => INP,
					-- outputs
					OUTP => OUTP_ARRAY(i), DOUT => DOUT_ARRAY(i),
					DRVR_CW => DRVR_CW(i), DRVR_CCW => DRVR_CCW(i),
          IND_AUXA_LIM => IND_AUXA_ARRAY(i), IND_AUXB_LIM => IND_AUXB_ARRAY(i),
					IND_CW_STEP => IND_CW_STEP(i), IND_CCW_STEP => IND_CCW_STEP(i),
          IND_CW_LIM => IND_CW_LIM(i), IND_CCW_LIM => IND_CCW_LIM(i),  
					IDXR_CCW_LIM => IDXR_CCW_LIM(i), IDXR_CW_LIM => IDXR_CW_LIM(i),
					POSITION => open
				);
		end generate;
		-- channel 15 end
	end generate;	 	
	

--	DOUT <=	CH0_DOUT or CH1_DOUT or CH2_DOUT or CH3_DOUT or
--					CH4_DOUT or CH5_DOUT or CH6_DOUT or CH7_DOUT or
--					CH8_DOUT or CH9_DOUT or CH10_DOUT or CH11_DOUT or
--					CH12_DOUT or CH13_DOUT or CH14_DOUT or CH15_DOUT;
--		
--	OUTP <=	CH0_OUTP or CH1_OUTP or CH2_OUTP or CH3_OUTP or
--					CH4_OUTP or CH5_OUTP or CH6_OUTP or CH7_OUTP or
--					CH8_OUTP or CH9_OUTP or CH10_OUTP or CH11_OUTP or
--					CH12_OUTP or CH13_OUTP or CH14_OUTP or CH15_OUTP;
--					
--	IND_AUXA_LIM <= CH0_IND_AUXA or CH1_IND_AUXA or CH2_IND_AUXA or CH3_IND_AUXA 
--                  or CH4_IND_AUXA or CH5_IND_AUXA or CH6_IND_AUXA or CH7_IND_AUXA 
--                  or CH8_IND_AUXA or CH9_IND_AUXA or CH10_IND_AUXA or CH11_IND_AUXA 
--	                or CH12_IND_AUXA or CH13_IND_AUXA or CH14_IND_AUXA or CH15_IND_AUXA;
--						 
--	IND_AUXB_LIM <= CH0_IND_AUXB or CH1_IND_AUXB or CH2_IND_AUXB or CH3_IND_AUXB 
--	                or CH4_IND_AUXB or CH5_IND_AUXB or CH6_IND_AUXB or CH7_IND_AUXB 
--                  or CH8_IND_AUXB or CH9_IND_AUXB or CH10_IND_AUXB or CH11_IND_AUXB 
--	                or CH12_IND_AUXB or CH13_IND_AUXB or CH14_IND_AUXB or CH15_IND_AUXB;
	
	----------------------------------
	DOUT <=	DOUT_ARRAY(0) or DOUT_ARRAY(1) or DOUT_ARRAY(2) or DOUT_ARRAY(3) or
					DOUT_ARRAY(4) or DOUT_ARRAY(5) or DOUT_ARRAY(6) or DOUT_ARRAY(7) or 
					DOUT_ARRAY(8) or DOUT_ARRAY(9) or DOUT_ARRAY(10) or DOUT_ARRAY(11) or 
					DOUT_ARRAY(12) or DOUT_ARRAY(13) or DOUT_ARRAY(14) or DOUT_ARRAY(15); 
		
	OUTP <=	OUTP_ARRAY(0) or OUTP_ARRAY(1) or OUTP_ARRAY(2) or OUTP_ARRAY(3) or
					OUTP_ARRAY(4) or OUTP_ARRAY(5) or OUTP_ARRAY(6) or OUTP_ARRAY(7) or 
					OUTP_ARRAY(8) or OUTP_ARRAY(9) or OUTP_ARRAY(10) or OUTP_ARRAY(11) or 
					OUTP_ARRAY(12) or OUTP_ARRAY(13) or OUTP_ARRAY(14) or OUTP_ARRAY(15); 
					
	IND_AUXA_LIM <=	IND_AUXA_ARRAY(0) or IND_AUXA_ARRAY(1) or IND_AUXA_ARRAY(2) or IND_AUXA_ARRAY(3) or
                  IND_AUXA_ARRAY(4) or IND_AUXA_ARRAY(5) or IND_AUXA_ARRAY(6) or IND_AUXA_ARRAY(7) or 
                  IND_AUXA_ARRAY(8) or IND_AUXA_ARRAY(9) or IND_AUXA_ARRAY(10) or IND_AUXA_ARRAY(11) or 
                  IND_AUXA_ARRAY(12) or IND_AUXA_ARRAY(13) or IND_AUXA_ARRAY(14) or IND_AUXA_ARRAY(15); 

	IND_AUXB_LIM <=	IND_AUXB_ARRAY(0) or IND_AUXB_ARRAY(1) or IND_AUXB_ARRAY(2) or IND_AUXB_ARRAY(3) or
                  IND_AUXB_ARRAY(4) or IND_AUXB_ARRAY(5) or IND_AUXB_ARRAY(6) or IND_AUXB_ARRAY(7) or 
                  IND_AUXB_ARRAY(8) or IND_AUXB_ARRAY(9) or IND_AUXB_ARRAY(10) or IND_AUXB_ARRAY(11) or 
                  IND_AUXB_ARRAY(12) or IND_AUXB_ARRAY(13) or IND_AUXB_ARRAY(14) or IND_AUXB_ARRAY(15); 
  
end structural; 
  
 

