----------------------------------------------------------------------------------
-- 
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package DEBOUNCE_PKG is
  component DEBOUNCE is
    generic (
      DELAY   : integer := 32;
      INVERT  : boolean := false
    );
    port (
      CLK   : in  STD_LOGIC;
      RST   : in  STD_LOGIC;
      I     : in  STD_LOGIC;
      O     : out STD_LOGIC
    );
  end component;
end DEBOUNCE_PKG;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity DEBOUNCE is
  generic (
    DELAY   : integer := 32;
    INVERT  : boolean := false
  );
  port (
    CLK   : in  STD_LOGIC;
    RST   : in  STD_LOGIC;
    I     : in  STD_LOGIC;
    O     : out STD_LOGIC
  );
end DEBOUNCE;

architecture Behavioral of DEBOUNCE is
	constant CNT_WIDTH : integer := integer(ceil(log2(real(DELAY))));
	signal SYNC_REG : STD_LOGIC_VECTOR(0 to 2);
	signal DEB_CNT : STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0);
	
	constant DEB_CNT_LOW : STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0) := (others => '0');
	constant DEB_CNT_HIGH : STD_LOGIC_VECTOR(CNT_WIDTH-1 downto 0) := (others => '1');

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

  O_PROC   : process(CLK)
  begin
    if CLK'event and CLK = '1' then
			if RST = '1' or DEB_CNT = DEB_CNT_LOW then 
				if INVERT then
					O <= '1';
				else
					O <= '0';
				end if;
			elsif DEB_CNT = DEB_CNT_HIGH then
				if INVERT then
					O <= '0';
				else
					O <= '1';
				end if;
			end if;
    end if;
  end process;

end Behavioral;
