----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package INDICATION_PKG is
  component MCI_INDICATION is
    generic (
      XFER_BYTES   : integer := 13;
			ACTIVE : STD_LOGIC := '1'
    );
    port (
      CLK   : in  STD_LOGIC;
      RST   : in  STD_LOGIC;
      IND_DATA     : in  STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);
			SPI_NCS      : in  STD_LOGIC;
			SPI_SCK      : in  STD_LOGIC;
			SPI_MOSI     : in  STD_LOGIC;
      SPI_MISO     : out STD_LOGIC
    );
  end component;
end INDICATION_PKG;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity MCI_INDICATION is
	generic (
    XFER_BYTES   : integer := 13;
    ACTIVE : STD_LOGIC := '1'
	);
	port (
		CLK   : in  STD_LOGIC;
		RST   : in  STD_LOGIC;
		IND_DATA     : in  STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);
		SPI_NCS      : in  STD_LOGIC;
		SPI_SCK      : in  STD_LOGIC;
		SPI_MOSI     : in  STD_LOGIC;
		SPI_MISO     : out STD_LOGIC
	);
end MCI_INDICATION;

architecture Behavioral of MCI_INDICATION is
	signal NCS_SYNC_REG : STD_LOGIC_VECTOR(0 to 3);

	signal MOSI_LD : STD_LOGIC;
	signal MISO_LD : STD_LOGIC;
	signal ACC_CLR : STD_LOGIC;

	signal MOSI_SR : STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);
	signal MISO_ACC : STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);
	signal MISO_SR : STD_LOGIC_VECTOR(0 to 8*XFER_BYTES-1);

	signal IND_TEST : STD_LOGIC;
	
begin
  NCS_SYNC_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
      NCS_SYNC_REG <= SPI_NCS & NCS_SYNC_REG(0 to 2);
    end if;
  end process;
	
	MOSI_LD <= '1' when NCS_SYNC_REG(2 to 3) = "10" else '0';
	MISO_LD <= '1' when NCS_SYNC_REG(2 to 3) = "01" else '0';

  ACC_CLR_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			ACC_CLR <=  MISO_LD;
    end if;
  end process;

  MISO_ACC_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			if ACC_CLR = '1' then
				if IND_TEST = ACTIVE then				
					MISO_ACC(0 to 8*XFER_BYTES-1) <= (others => '1'); -- TODO: verify
				else
					MISO_ACC(0 to 95) <= IND_DATA(0 to 95);
          if IND_TEST = ACTIVE then
            MISO_ACC(96) <= '1'; 
          else
            MISO_ACC(96) <= '0'; 
          end if;
					MISO_ACC(97 to 103) <= (others => '0');      
				end if;
			else 
				MISO_ACC(0 to 95)<= IND_DATA(0 to 95) or MISO_ACC(0 to 95);
			end if;
    end if;
  end process;

  MISO_SR_PROC   : process(MISO_LD, IND_DATA, MISO_ACC, SPI_SCK)
  begin
    if MISO_LD = '1' then 
			MISO_SR <= IND_DATA or MISO_ACC;
		elsif SPI_SCK'event and SPI_SCK = '0' then
			if SPI_NCS = '0' then 
				MISO_SR <= "0" & MISO_SR(0 to 8*XFER_BYTES-2);
			end if;
    end if;
  end process;
	
  SPI_MISO_PROC   : process(SPI_SCK)
  begin
    if SPI_SCK'event and SPI_SCK = '0' then
			if SPI_NCS = '0' then 
				SPI_MISO <= MISO_SR(8*XFER_BYTES-1);
			end if;
    end if;
  end process;

  MOSI_SR_PROC   : process(SPI_SCK)
  begin
    if SPI_SCK'event and SPI_SCK = '1' then
			if SPI_NCS = '0' then 
				MOSI_SR <= SPI_MOSI & MOSI_SR(0 to 8*XFER_BYTES-2);
			end if;
    end if;
  end process;

	IND_TEST_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			if RST = '1' then
				IND_TEST <= '1';     
			elsif MOSI_LD = '1' then
				if MOSI_SR(0) = '0' then  -- TODO: use correct bit
          IND_TEST <= ACTIVE;
        else
         IND_TEST <= not ACTIVE;
        end if;
			end if;
    end if;
  end process; 
	
end Behavioral;
