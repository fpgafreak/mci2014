----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.DEBOUNCE_PKG.all;
use work.PULSE_DETECT_PKG.all;
use work.IO_EXT_PKG.all;
use work.motor_logic_pkg.all;
use work.INDICATION_PKG.all;
-- use work.DEFS_PKG.all;

entity MCI2012_WRAPPER is
  port (
    -- 50 MHz oscillator clock input 
    CLK_50MHZ_PIN       : in  STD_LOGIC;

    -- indexer motor control signals
    IDXR_DIR_PIN        : in  STD_LOGIC_VECTOR(0 to 15);  -- direction: '0' = CW, '1' = CCW  
    IDXR_CLK_PIN        : in  STD_LOGIC_VECTOR(0 to 15);  -- step pulse: active high (0 to 1 transition)

    -- indexer limit switch signals
    IDXR_CCW_LIM_PIN, IDXR_CW_LIM_PIN   : out STD_LOGIC_VECTOR(0 to 15); -- '0' = motion possible, '1' = limit active

    -- serializer register interface (limit and auxiliary inputs)
    SREG_CLK_PIN, SREG_MODE_PIN        : out STD_LOGIC; -- * 04-01-13
    SREG_DATA_PIN       : in  STD_LOGIC_VECTOR(0 to 7);

    -- step pulse output 
    DRVR_CW_PIN         : out STD_LOGIC_VECTOR(0 to 15);
    DRVR_CCW_PIN        : out STD_LOGIC_VECTOR(0 to 15);

    -- back panel digital I/O
    INP_PIN              : in  STD_LOGIC_VECTOR(0 to 7);
    OUTP_PIN             : out STD_LOGIC_VECTOR(0 to 7);

		-- front panel digital outputs
		DOUT_PIN       :out STD_LOGIC_VECTOR(0 to 15);

    -- SPI slave interface for front panel indication 
    SPI_NCS_PIN, SPI_SCK_PIN, SPI_MOSI_PIN    : in STD_LOGIC;
    SPI_MISO_PIN        : out STD_LOGIC;

    -- indication LEDs
    LED_PIN             : out STD_LOGIC_VECTOR(0 to 5)
  );
end MCI2012_WRAPPER;

architecture behavioral of MCI2012_WRAPPER is
    -- constants

		-- multiplexed i/o configuration
    constant SREG_LENGTH    : integer := 8;
    constant SREG_WIDTH     : integer := 8;

		-- indication configuration
    constant XFER_BYTES     : integer := 13;

		-- input configuration
    constant DIR_CW         : STD_LOGIC := '1';
		constant IDXR_STEP_EDGE : string := "RISING";
		constant INP_ACTIVE		: STD_LOGIC_VECTOR(0 to 7) := "11111111";         -- (*)not used?

    -- MMI serial data link configuration
    constant SDL_CCW_LIM_MASK : STD_LOGIC_VECTOR(0 to 15) := "0000000000000000";
    constant SDL_CW_LIM_MASK : STD_LOGIC_VECTOR(0 to 15) := "0000000000000000";
    
		-- output configuration
		constant OUTP_ACTIVE		: STD_LOGIC_VECTOR(0 to 7) := "11111111";		      --(*) TODO: check polarity
		constant DOUT_ACTIVE		: STD_LOGIC_VECTOR(0 to 15) := "1111111111111111"; --(*)TODO: check polarity
		constant IDXR_LIM_ACTIVE	: STD_LOGIC := '1';			-- TODO: check polarity
		constant DRVR_STEP_ACTIVE : STD_LOGIC := '0';			-- TODO: check polarity
    constant LED_ON         : STD_LOGIC := '0';

    constant ACTIVE         : STD_LOGIC := '1';

    -- clock management signals
    signal 		CLK_32MHZ      : STD_LOGIC;
    signal 		DCM1_LOCKED    : STD_LOGIC;
    signal 		DCM2_RST       : STD_LOGIC;
    signal 		CLK_128MHZ     : STD_LOGIC;
    signal 		DCM2_LOCKED    : STD_LOGIC;
    signal 		LOCKED       	 : STD_LOGIC;

    -- reset signals
    signal 		RST_CNT    		: STD_LOGIC_VECTOR(9 downto 0);    
    constant 	RST_TC    		: STD_LOGIC_VECTOR(9 downto 0) := (others => '1');    
    signal 		RST		    	: STD_LOGIC;    

    -- synchronized indexer direction signals
    signal 		IDXR_DIR        : STD_LOGIC_VECTOR(0 to 15);    

    -- detected indexer step flags (one clock long)
    signal 		IDXR_STEP       : STD_LOGIC_VECTOR(0 to 15);

    -- indexer limit switch signals
    signal 		IDXR_CCW_LIM    : STD_LOGIC_VECTOR(0 to 15);
    signal 		IDXR_CW_LIM     : STD_LOGIC_VECTOR(0 to 15);

    -- deserializer data (4 input limit vectors and 4 auxiliary ones combined  into 
	 -- one 8*8 debounced vector) 
    signal 		SREG_DATA       : STD_LOGIC_VECTOR(0 to SREG_LENGTH*SREG_WIDTH-1);

    -- limit input signals (from shift register map)
    signal 		CCW_LIM         : STD_LOGIC_VECTOR(0 to 15);
    signal 		CW_LIM          : STD_LOGIC_VECTOR(0 to 15);
    signal 		AUX1_LIM        : STD_LOGIC_VECTOR(0 to 15);
    signal 		AUX2_LIM        : STD_LOGIC_VECTOR(0 to 15);
    signal 		SDL_CCW_LIM     : STD_LOGIC_VECTOR(0 to 15);
    signal 		SDL_CW_LIM      : STD_LOGIC_VECTOR(0 to 15);

    -- step pulse output 
    signal 		DRVR_CW         : STD_LOGIC_VECTOR(0 to 15);
    signal 		DRVR_CCW        : STD_LOGIC_VECTOR(0 to 15);

    -- back panel digital I/O
    signal 		INP             : STD_LOGIC_VECTOR(0 to 7); -- 4 coax and 4 pads
    signal 		OUTP            : STD_LOGIC_VECTOR(0 to 7); -- same
    
    -- front panel digital output
    signal 		DOUT            : STD_LOGIC_VECTOR(0 to 15);
    
    -- indication signals
    signal 		IND_CCW_LIM     : STD_LOGIC_VECTOR(0 to 15);
    signal 		IND_CW_LIM      : STD_LOGIC_VECTOR(0 to 15);
    signal 		IND_CCW_STEP    : STD_LOGIC_VECTOR(0 to 15);
    signal 		IND_CW_STEP     : STD_LOGIC_VECTOR(0 to 15);
    signal 		IND_AUXA_LIM    : STD_LOGIC_VECTOR(0 to 15);
    signal 		IND_AUXB_LIM    : STD_LOGIC_VECTOR(0 to 15);

    -- SPI slave interface for front panel indication 
    signal 		IND_DATA        : STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);
--    SPI_NCS, SPI_SCK, SPI_MOSI    : STD_LOGIC;
    signal 		SPI_MISO    		: STD_LOGIC;

    -- indication LEDs
    signal 		LED             : STD_LOGIC_VECTOR(0 to 5);

begin

  -- clock management
    --  inputs
      --  CLK_50MHZ_PIN
    --  outputs
      ----  CLK_50MHZ_FB
      ----  CLK_50MHZ
      --  CLK_32MHZ
--  CLK_DCM_INST : DCM_SP
--  generic map (
--    CLKDV_DIVIDE => 2.0, CLKFX_DIVIDE => 25, CLKFX_MULTIPLY => 16, CLKIN_DIVIDE_BY_2 => FALSE,
--    CLKIN_PERIOD => 20.0, CLKOUT_PHASE_SHIFT => "NONE", CLK_FEEDBACK => "1X", DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
--    DLL_FREQUENCY_MODE => "HIGH", DUTY_CYCLE_CORRECTION => TRUE, PHASE_SHIFT => 0, STARTUP_WAIT => TRUE
--  )
--  port map (
--    CLK0 => open,  --  CLK0 => CLK_50MHZ,
--    CLK180 => open, CLK270 => open, CLK2X => open, CLK2X180 => open, CLK90 => open, CLKDV => open,
--    CLKFX => CLK_32MHZ, CLKFX180 => open, LOCKED => LOCKED, PSDONE => open, STATUS => open,
--    CLKFB => open,  --  CLKFB => CLK_50MHZ_FB,
--    CLKIN => CLK_50MHZ_PIN, PSCLK => '0', PSEN => '0', PSINCDEC => '0', RST => '0'
--  );
--	

  CLK_DCM1_INST : DCM_SP
  generic map (
    CLKDV_DIVIDE => 2.0, CLKFX_DIVIDE => 25, CLKFX_MULTIPLY => 16, CLKIN_DIVIDE_BY_2 => FALSE,
    CLKIN_PERIOD => 20.0, CLKOUT_PHASE_SHIFT => "NONE", CLK_FEEDBACK => "NONE", DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
    DLL_FREQUENCY_MODE => "HIGH", DUTY_CYCLE_CORRECTION => TRUE, PHASE_SHIFT => 0, STARTUP_WAIT => TRUE
  )
  port map (
    CLK0 => open,
    CLK180 => open, CLK270 => open, CLK2X => open, CLK2X180 => open, CLK90 => open, CLKDV => open,
    CLKFX => CLK_32MHZ, CLKFX180 => open, LOCKED => DCM1_LOCKED, PSDONE => open, STATUS => open,
    CLKFB => open,
    CLKIN => CLK_50MHZ_PIN, PSCLK => '0', PSEN => '0', PSINCDEC => '0', RST => '0'
  );

--  DCM2_RST <= not DCM1_LOCKED;
--	
--  CLK_DCM2_INST : DCM_SP
--  generic map (
--    CLKDV_DIVIDE => 2.0, CLKFX_DIVIDE => 1, CLKFX_MULTIPLY => 4, CLKIN_DIVIDE_BY_2 => FALSE,
--    CLKIN_PERIOD => 31.25, CLKOUT_PHASE_SHIFT => "NONE", CLK_FEEDBACK => "NONE", DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
--    DLL_FREQUENCY_MODE => "HIGH", DUTY_CYCLE_CORRECTION => TRUE, PHASE_SHIFT => 0, STARTUP_WAIT => TRUE
--  )
--  port map (
--    CLK0 => open,
--    CLK180 => open, CLK270 => open, CLK2X => open, CLK2X180 => open, CLK90 => open, CLKDV => open,
--    CLKFX => CLK_128MHZ, CLKFX180 => open, LOCKED => DCM2_LOCKED, PSDONE => open, STATUS => open,
--    CLKFB => open,
--    CLKIN => CLK_32MHZ, PSCLK => '0', PSEN => '0', PSINCDEC => '0', RST => DCM2_RST
--  );
--	
--  LOCKED <= '1' when DCM1_LOCKED ='1' and DCM2_LOCKED = '1' else '0';

  LOCKED <= '1' when DCM1_LOCKED ='1' else '0';  
  
	-- reset control
	RST_CNT_PROC: process (LOCKED, CLK_32MHZ)
	begin
		if LOCKED = '0' then
			RST_CNT <= (others => '0');
		elsif CLK_32MHZ'event and CLK_32MHZ = '1' then
			if RST_CNT /= RST_TC then
				RST_CNT <= RST_CNT + 1;
			end if;
		end if;
	end process;

	RST_PROC: process (CLK_32MHZ)
	begin
		if CLK_32MHZ'event and CLK_32MHZ = '1' then
			if RST_CNT /= RST_TC then
				RST <= '1';
			else
				RST <= '0';
			end if;
		end if;
	end process;

  -- indexer direction inputs (clk sync + short debounce)
    --  inputs
      --  CLK_32MHZ
      --  IDXR_DIR_PIN
    --  outputs
      --  IDXR_DIR
  IDXR_DIR_GEN: for i in 0 to 15 generate
    IDXR_DIR_INST: DEBOUNCE
      generic map (DELAY => 32, INVERT => false)
      port map (CLK => CLK_32MHZ, RST => RST, I => IDXR_DIR_PIN(i), O => IDXR_DIR(i));
  end generate;

  -- digital inputs (clk sync + short debounce)
    --  inputs
      --  CLK_32MHZ
      --  DI_PIN
    --  outputs
      --  DI
--  DI_SDI_INST: DEBOUNCE
--    generic map (DELAY => 128, INVERT => false)
--    port map (CLK => CLK_128MHZ, RST => RST, I => INP_PIN(0), O => INP(0));
--
  DI_GEN: for i in 0 to 7 generate
    DI_INST: DEBOUNCE
      generic map (DELAY => 32, INVERT => false)
      port map (CLK => CLK_32MHZ, RST => RST, I => INP_PIN(i), O => INP(i));
  end generate;

  -- indexer step inputs (clk sync + short debounce + edge detectors)
    --  inputs
      --  CLK_32MHZ
      --  IDXR_CLK_PIN
    --  outputs
      --  IDXR_STEP
  IDXR_STEP_GEN: for i in 0 to 15 generate
    IDXR_STEP_INST: PULSE_DETECT
      generic map (DELAY => 32, EDGE => IDXR_STEP_EDGE, OUTPUT_ACTIVE => ACTIVE)
      port map (CLK => CLK_32MHZ, RST => RST, I => IDXR_CLK_PIN(i), O => IDXR_STEP(i));
  end generate;

  -- input deserializer
    --  inputs
      --  CLK_32MHZ
      --  SREG_DATA_PIN
    --  outputs
      --  SREG_CLK_PIN
      --  SREG_MODE_PIN
      --  SREG_DATA
  DESERIALIZER_INST: DESERIALIZER
    generic map (
      SREG_LENGTH => SREG_LENGTH, SREG_WIDTH => SREG_WIDTH,
      DELAY => 256,
      -- INPUT_ACTIVE => '0', ch 04-08-13
      INPUT_ACTIVE => '1',		
		OUTPUT_ACTIVE => ACTIVE
    )
    port map (
      CLK => CLK_32MHZ, RST => RST, SR_DATA => SREG_DATA_PIN,
      SR_CLK => SREG_CLK_PIN, SR_MODE => SREG_MODE_PIN, SR_OUT => SREG_DATA
    );

  -- serialized input map
    --  inputs
      --  SREG_DATA
    --  outputs
      --  CCW_LIM
      --  CW_LIM
      --  AUX1_LIM
      --  AUX2_LIM
  
  CW_LIM <=  SREG_DATA(0)  & SREG_DATA(2)  & SREG_DATA(4)  & SREG_DATA(6)  & SREG_DATA(8)  & SREG_DATA(10)
					 & SREG_DATA(12) & SREG_DATA(14) & SREG_DATA(16) & SREG_DATA(18) & SREG_DATA(20) & SREG_DATA(22)
					 & SREG_DATA(24) & SREG_DATA(26) & SREG_DATA(28) & SREG_DATA(30);
	 
  CCW_LIM <= SREG_DATA(1)  & SREG_DATA(3)  & SREG_DATA(5)  & SREG_DATA(7)  & SREG_DATA(9)  & SREG_DATA(11)
           & SREG_DATA(13) & SREG_DATA(15) & SREG_DATA(17) & SREG_DATA(19) & SREG_DATA(21) & SREG_DATA(23)
						&SREG_DATA(25) & SREG_DATA(27) & SREG_DATA(29) & SREG_DATA(31);
   
  AUX1_LIM <= SREG_DATA(32 to 47);
  AUX2_LIM <= SREG_DATA(48 to 63);
  
  -- TODO: add MMI_SDL here
  SDL_CCW_LIM <= (others => not ACTIVE);
  SDL_CW_LIM <= (others => not ACTIVE);
  
  -- motor logic
    --  inputs
      --  CLK_32MHZ
      --  CCW_LIM
      --  CW_LIM
      --  AUX1_LIM
      --  AUX2_LIM
      --  INP
      --  IDXR_STEP
      --  IDXR_DIR
    --  outputs
      --  IDXR_CCW_LIM
      --  IDXR_CW_LIM
      --  DRVR_CCW
      --  DRVR_CW
      --  OUTP
			--	DOUT
      --  IND_CCW_LIM
      --  IND_CW_LIM
      --  IND_CCW_STEP
      --  IND_CW_STEP
      --  IND_AUX1_LIM
      --  IND_AUX2_LIM
  MOTOR_LOGIC_INST: MOTOR_LOGIC
--    generic map (DIR_CW => DIR_CW, LIMIT_ACTIVE => ACTIVE, STEP_ACTIVE => ACTIVE)
    generic map (DIR_CW => DIR_CW, ACTIVE => ACTIVE)
    port map (
      CLK => CLK_32MHZ, RST => RST,
      CCW_LIM => CCW_LIM, CW_LIM => CW_LIM, AUX1_LIM => AUX1_LIM, AUX2_LIM => AUX2_LIM,
      SDL_CCW_LIM => SDL_CCW_LIM, SDL_CW_LIM => SDL_CW_LIM, INP => INP,
      IDXR_STEP => IDXR_STEP, IDXR_DIR => IDXR_DIR,
      IDXR_CCW_LIM => IDXR_CCW_LIM, IDXR_CW_LIM => IDXR_CW_LIM, DRVR_CCW => DRVR_CCW, DRVR_CW => DRVR_CW, OUTP => OUTP,
			DOUT => DOUT,
      IND_CCW_LIM => IND_CCW_LIM, IND_CW_LIM => IND_CW_LIM, IND_CCW_STEP => IND_CCW_STEP, IND_CW_STEP => IND_CW_STEP,
      IND_AUXA_LIM => IND_AUXA_LIM, IND_AUXB_LIM => IND_AUXB_LIM
    );


  
  -- indication map
    --  inputs: defined in Motor_logic component
      --  IND_CCW_LIM
      --  IND_CW_LIM
      --  IND_CCW_STEP
      --  IND_CW_STEP
      --  IND_AUX1_LIM
      --  IND_AUX2_LIM
    --  outputs
      --  IND_DATA
 -- ind_data defined as  "signal IND_DATA : STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);"		
 -- and combined from MOTOR LOGIC output vectors' components.
   
  IND_DATA(0 to 3)   <= IND_AUXA_LIM(7) & IND_AUXA_LIM(6) & IND_AUXA_LIM(5) & IND_AUXA_LIM(3);
  IND_DATA(4 to 7)   <= IND_AUXA_LIM(2) & IND_AUXA_LIM(1) & IND_AUXA_LIM(0) & IND_AUXA_LIM(4); 
  IND_DATA(8 to 11)  <= IND_CW_LIM(7) & IND_CW_LIM(6) & IND_CW_LIM(5) & IND_CW_LIM(3); 
  IND_DATA(12 to 15) <= IND_CW_LIM(2) & IND_CW_LIM(1) & IND_CW_LIM(0) & IND_CW_LIM(4); 

  IND_DATA(16 to 19) <= IND_CW_STEP(7) & IND_CW_STEP(6) & IND_CW_STEP(5) & IND_CW_STEP(3);
  IND_DATA(20 to 23) <= IND_CW_STEP(2) & IND_CW_STEP(1) & IND_CW_STEP(0) & IND_CW_STEP(4); 
  IND_DATA(24 to 27) <= IND_CCW_STEP(7) & IND_CCW_STEP(6) & IND_CCW_STEP(5) & IND_CCW_STEP(3); 
  IND_DATA(28 to 31) <= IND_CCW_STEP(2) & IND_CCW_STEP(1) & IND_CCW_STEP(0) & IND_CCW_STEP(4); 

  IND_DATA(32 to 35) <= IND_CCW_LIM(7) & IND_CCW_LIM(6) & IND_CCW_LIM(5) & IND_CCW_LIM(3);
  IND_DATA(36 to 39) <= IND_CCW_LIM(2) & IND_CCW_LIM(1) & IND_CCW_LIM(0) & IND_CCW_LIM(4);
  IND_DATA(40 to 43) <= IND_AUXB_LIM(7) & IND_AUXB_LIM(6) & IND_AUXB_LIM(5) & IND_AUXB_LIM(3);
  IND_DATA(44 to 47) <= IND_AUXB_LIM(2) & IND_AUXB_LIM(1) & IND_AUXB_LIM(0) & IND_AUXB_LIM(4);
  
  IND_DATA(48 to 51) <= IND_AUXA_LIM(14) & IND_AUXA_LIM(13) & IND_AUXA_LIM(12) & IND_AUXA_LIM(11);
  IND_DATA(52 to 55) <= IND_AUXA_LIM(10) & IND_AUXA_LIM(9)  & IND_AUXA_LIM(8)  & IND_AUXA_LIM(15);
  IND_DATA(56 to 59) <= IND_CW_LIM(14) & IND_CW_LIM(13) & IND_CW_LIM(12) & IND_CW_LIM(11);
  IND_DATA(60 to 63) <= IND_CW_LIM(10) & IND_CW_LIM(9)  & IND_CW_LIM(8)  & IND_CW_LIM(15);

  IND_DATA(64 to 67) <= IND_CW_STEP(14) & IND_CW_STEP(13) & IND_CW_STEP(12) & IND_CW_STEP(11);
  IND_DATA(68 to 71) <= IND_CW_STEP(10) & IND_CW_STEP(9)  & IND_CW_STEP(8)  & IND_CW_STEP(15);
  IND_DATA(72 to 75) <= IND_CCW_STEP(14) & IND_CCW_STEP(13) & IND_CCW_STEP(12) & IND_CCW_STEP(11);
  IND_DATA(76 to 79) <= IND_CCW_STEP(10) & IND_CCW_STEP(9)  & IND_CCW_STEP(8)  & IND_CCW_STEP(15);

  IND_DATA(80 to 83) <= IND_CCW_LIM(14) & IND_CCW_LIM(13) & IND_CCW_LIM(12) & IND_CCW_LIM(11);
  IND_DATA(84 to 87) <= IND_CCW_LIM(10) & IND_CCW_LIM(9)  & IND_CCW_LIM(8)  & IND_CCW_LIM(15);
  IND_DATA(88 to 91) <= IND_AUXB_LIM(14) & IND_AUXB_LIM(13) & IND_AUXB_LIM(12) & IND_AUXB_LIM(11);
  IND_DATA(92 to 95) <= IND_AUXB_LIM(10) & IND_AUXB_LIM(9)  & IND_AUXB_LIM(8)  & IND_AUXB_LIM(15);

   IND_DATA(96 to 103) <= (others => '0');
--	
 
  -- indication
    --  inputs
      --  CLK_32MHZ
      --  IND_DATA
      --  SPI_NCS_PIN
      --  SPI_SCK_PIN
      --  SPI_MOSI_PIN
    --  outputs
      --  SPI_MISO
  MCI_INDICATION_INST: MCI_INDICATION
    generic map (XFER_BYTES => XFER_BYTES, ACTIVE => ACTIVE)
    port map (
      CLK => CLK_32MHZ, RST => RST, IND_DATA => IND_DATA,
      SPI_NCS => SPI_NCS_PIN, SPI_SCK => SPI_SCK_PIN, SPI_MOSI => SPI_MOSI_PIN, SPI_MISO => SPI_MISO
    );

  -- temporary assignments
   -- LED <= OUTP(0 to 5);
	
--	LED(0) <= IDXR_DIR_PIN(0);
	LED(0) <= INP(0);
--	LED(0) <= '0';

--	LED(1) <= IDXR_DIR(0);	
--	LED(1) <= OUTP(0);	
	LED(1) <= INP(1);	
--	LED(1) <= '0';

--	LED(2) <= DOUT(0);	
	LED(2) <= INP(2);	
--	LED(2) <= '0';

	LED(3) <= INP(3);
--	LED(3) <= '0';

	LED(4) <= OUTP(0);	
--	LED(4) <= '0';	

	LED(5) <= DOUT(0);
	
  -- output pin assignments
	IDXR_LIM_GEN: for i in 0 to 15 generate
		IDXR_CCW_LIM_PIN(i) <= IDXR_LIM_ACTIVE when IDXR_CCW_LIM(i) = ACTIVE else not IDXR_LIM_ACTIVE;
		IDXR_CW_LIM_PIN(i)  <= IDXR_LIM_ACTIVE when IDXR_CW_LIM(i) = ACTIVE  else not IDXR_LIM_ACTIVE;
	end generate;

	DRVR_PULSE_GEN: for i in 0 to 15 generate
		DRVR_CCW_PIN(i) <= DRVR_STEP_ACTIVE when DRVR_CCW(i) = ACTIVE else not DRVR_STEP_ACTIVE;
		DRVR_CW_PIN(i)  <= DRVR_STEP_ACTIVE when DRVR_CW(i) = ACTIVE  else not DRVR_STEP_ACTIVE;
	end generate;

	OUTP_GEN: for i in 0 to 7 generate
		OUTP_PIN(i) <= OUTP_ACTIVE(i) when OUTP(i) = '1' else not OUTP_ACTIVE(i);
	end generate;

--  OUTP_PIN <= OUTP;
  
  SPI_MISO_PIN <= SPI_MISO when SPI_NCS_PIN = '0' else 'Z'; -- TODO: check if pullup needed

	DOUT_GEN: for i in 0 to 15 generate
		DOUT_PIN(i) <= DOUT_ACTIVE(i) when DOUT(i) = '1' else not DOUT_ACTIVE(i);
	end generate;

  LED_GEN: for i in 0 to 5 generate
		LED_PIN(i) <= LED_ON when LED(i) = '1' else not LED_ON;
  end generate;

end behavioral;
