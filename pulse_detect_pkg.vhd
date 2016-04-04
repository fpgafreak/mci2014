----------------------------------------------------------------------------------
-- 
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package PULSE_DETECT_PKG is
  component PULSE_DETECT is
    generic (
      DELAY   : integer := 32;
      EDGE    : string := "RISING";
      OUTPUT_ACTIVE : STD_LOGIC := '1'
    );
    port (
      CLK   : in  STD_LOGIC;
      RST   : in  STD_LOGIC;
      I     : in  STD_LOGIC;
      O     : out STD_LOGIC
    );
  end component;
end PULSE_DETECT_PKG;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity PULSE_DETECT is
  generic (
    DELAY   : integer := 32;
    EDGE    : string := "RISING";
    OUTPUT_ACTIVE : STD_LOGIC := '1'
  );
  port (
    CLK   : in  STD_LOGIC;
    RST   : in  STD_LOGIC;
    I     : in  STD_LOGIC;
    O     : out STD_LOGIC
  );
end PULSE_DETECT;

architecture Behavioral of PULSE_DETECT is
	constant CNT_WIDTH : integer := integer(ceil(log2(real(DELAY))));
	signal SYNC_REG : STD_LOGIC_VECTOR(0 to 2);
	signal DEB_CNT : STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0);
	constant DEB_CNT_LOW : STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0) := (others => '0');
	constant DEB_CNT_HIGH : STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0) := (others => '1');
	signal DLY_REG : STD_LOGIC;

begin
  SYNC_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
        SYNC_REG <= I & SYNC_REG(0 to 1);
    end if;
  end process;
	
  DEB_CNT_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			if RST = '1' then 
				DEB_CNT <= (others => '0');
			elsif SYNC_REG(2) = '0' and DEB_CNT /= DEB_CNT_LOW then
        DEB_CNT <= DEB_CNT - 1;
			elsif SYNC_REG(2) = '1' and DEB_CNT /= DEB_CNT_HIGH then
        DEB_CNT <= DEB_CNT + 1;
			end if;
    end if;
  end process;

  DLY_REG_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			if RST = '1' or (SYNC_REG(2) = '0' and DEB_CNT = DEB_CNT_LOW) then
        DLY_REG <= '0';
			elsif SYNC_REG(2) = '1' and DEB_CNT = DEB_CNT_HIGH then
        DLY_REG <= '1';
			end if;
    end if;
  end process;

  O_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			if RST = '1' then
					O <= not OUTPUT_ACTIVE;
			elsif (EDGE = "RISING") then
				if (SYNC_REG(2) = '1') and (DEB_CNT = DEB_CNT_HIGH) and (DLY_REG = '0') then
					O <= OUTPUT_ACTIVE;
				else
					O <= not OUTPUT_ACTIVE;
				end if;
			elsif EDGE = "FALLING" then
				if (SYNC_REG(2) = '0') and (DEB_CNT = DEB_CNT_LOW) and (DLY_REG = '1') then
					O <= OUTPUT_ACTIVE;
				else
					O <= not OUTPUT_ACTIVE;
				end if;
			end if;
    end if;
  end process;

end Behavioral;

