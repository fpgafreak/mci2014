----------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package IO_EXT_PKG is
	component DESERIALIZER is
		generic (
			SREG_LENGTH : integer := 8;
			SREG_WIDTH : integer := 8;
			DELAY : integer := 256;
			-- INPUT_ACTIVE : STD_LOGIC := '0';  ch 04-08-13
			INPUT_ACTIVE : STD_LOGIC := '1';			
			OUTPUT_ACTIVE : STD_LOGIC := '1'
		);
		port (
			CLK : in STD_LOGIC;
			RST : in STD_LOGIC;
			SR_DATA  : in STD_LOGIC_VECTOR(0 to SREG_WIDTH-1);
			SR_CLK : out STD_LOGIC;
			SR_MODE : out STD_LOGIC;
			SR_OUT  : out STD_LOGIC_VECTOR(0 to SREG_LENGTH*SREG_WIDTH-1)
		);
	end component;
end IO_EXT_PKG;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity DESERIALIZER is
  generic (
    SREG_LENGTH : integer := 8;
		SREG_WIDTH : integer := 8;
    DELAY : integer := 256;
		-- INPUT_ACTIVE : STD_LOGIC := '0'; ch 04-05-13
		INPUT_ACTIVE : STD_LOGIC := '1';		
		-- OUTPUT_ACTIVE : STD_LOGIC := '1'
		OUTPUT_ACTIVE : STD_LOGIC := '0'		
  );
  port (
    CLK : in STD_LOGIC;
		RST : in STD_LOGIC;
		SR_DATA  : in STD_LOGIC_VECTOR(0 to SREG_WIDTH-1);
		SR_CLK : out STD_LOGIC;
		SR_MODE : out STD_LOGIC;
		SR_OUT  : out STD_LOGIC_VECTOR(0 to SREG_LENGTH*SREG_WIDTH-1)
  );
end DESERIALIZER;

architecture Behavioral of DESERIALIZER is
	constant SR_CNT_LEN : integer := integer(ceil(log2(real(4*SREG_LENGTH))));
	signal SR_CNT : STD_LOGIC_VECTOR(SR_CNT_LEN-1 downto 0);
	constant SR_TC : STD_LOGIC_VECTOR(SR_CNT_LEN-1 downto 0) := conv_std_logic_vector(4*SREG_LENGTH-1, SR_CNT_LEN);

	type SR_ARRAY is array (0 to SREG_WIDTH-1) of STD_LOGIC_VECTOR(0 to SREG_LENGTH-1);
	signal SR : SR_ARRAY;

	constant DEB_CNT_LEN : integer := integer(ceil(log2(real(DELAY/4/SREG_LENGTH))));
--	constant DEB_CNT_LEN : integer := integer(ceil(log2(real(DELAY))));
	type DEB_ARRAY is array (0 to SREG_LENGTH*SREG_WIDTH-1) of STD_LOGIC_VECTOR(DEB_CNT_LEN-1 downto 0);
	signal DEB_CNT : DEB_ARRAY;
	constant DEB_CNT_HIGH : STD_LOGIC_VECTOR(DEB_CNT_LEN-1 downto 0) := conv_std_logic_vector(integer(ceil(real(DELAY/4/SREG_LENGTH)))-1, DEB_CNT_LEN);
	constant DEB_CNT_LOW : STD_LOGIC_VECTOR(DEB_CNT_LEN-1 downto 0) := (others => '0');
	
begin
	SR_CNT_PROC : process (CLK)
	begin
		if CLK'event and CLK = '1' then
			if RST = '1' or SR_CNT = SR_TC then
				SR_CNT <= (others => '0');
			else
				SR_CNT <= SR_CNT + 1; 
			end if;
		end if;
	end process;

	SR_CLK_PROC : process (CLK)
	begin
		if CLK'event and CLK = '1' then
			if RST = '1' or SR_CNT(1 downto 0) = "11" then
				SR_CLK <= '0';
			elsif SR_CNT(1 downto 0) = "01" then
				SR_CLK <= '1';
			end if;
		end if;
	end process;

	SR_MODE_PROC : process (CLK)
	begin
		if CLK'event and CLK = '1' then
			if RST = '1' or SR_CNT = SR_TC then
				SR_MODE <= '0';
			elsif SR_CNT = conv_std_logic_vector(3, SR_CNT_LEN) then
				SR_MODE <= '1';
			end if;
		end if;
	end process;

	SR_GEN: for i in 0 to SREG_WIDTH-1 generate
		SR_PROC: process (CLK)
		begin
			if CLK'event and CLK = '1' then
				if RST = '1' then
					SR(i) <= (others => not INPUT_ACTIVE);
				elsif SR_CNT(1 downto 0) = "11" then
					SR(i) <= SR_DATA(i) & SR(i)(0 to SREG_LENGTH-2);
				end if;
			end if;
		end process;
	end generate;

	DEB_GEN: for i in 0 to SREG_WIDTH*SREG_LENGTH-1 generate
		DEB_PROC: process (CLK)
		begin
			if CLK'event and CLK = '1' then
				if RST = '1' then
					DEB_CNT(i) <= (others => '0');
				elsif SR_CNT = conv_std_logic_vector(0, SR_CNT_LEN) then
					if (SR(i/SREG_LENGTH)(i mod SREG_LENGTH) = INPUT_ACTIVE) and (DEB_CNT(i) /= DEB_CNT_HIGH) then
						DEB_CNT(i) <= DEB_CNT(i) + 1;
					elsif (SR(i/SREG_LENGTH)(i mod SREG_LENGTH) = not INPUT_ACTIVE) and (DEB_CNT(i) /= DEB_CNT_LOW) then
						DEB_CNT(i) <= DEB_CNT(i) - 1;
					end if;
				end if;
			end if;
		end process;
	end generate;

	SR_OUT_GEN: for i in 0 to SREG_WIDTH*SREG_LENGTH-1 generate
		SR_OUT_PROC: process (CLK)
		begin
			if CLK'event and CLK = '1' then
				if RST = '1' then
					SR_OUT(i) <= not OUTPUT_ACTIVE;
				elsif SR_CNT = conv_std_logic_vector(0, SR_CNT_LEN) then
					if (SR(i/SREG_LENGTH)(i mod SREG_LENGTH) = not INPUT_ACTIVE) and (DEB_CNT(i) = DEB_CNT_LOW) then
						SR_OUT(i) <= not OUTPUT_ACTIVE;
					elsif (SR(i/SREG_LENGTH)(i mod SREG_LENGTH) = INPUT_ACTIVE) and (DEB_CNT(i) = DEB_CNT_HIGH) then
						SR_OUT(i) <= OUTPUT_ACTIVE;
					end if;
				end if;
			end if;
		end process;
	end generate;

end Behavioral;

