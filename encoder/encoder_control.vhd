library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder_draw is
    generic (
        POS_MAX : natural := 719  -- limite de la position (horizontal ou vertical)
    );
    port (
        i_clk_50    : in  std_logic;  -- horloge FPGA 50 MHz
        i_rst_n     : in  std_logic;  -- reset actif bas
        ENC_A       : in  std_logic;  -- encodeur A
        ENC_B       : in  std_logic;  -- encodeur B
        o_position  : out natural     -- position actuelle limitée
    );
end entity encoder_draw;

architecture rtl of encoder_draw is

    -- Anti-rebond et synchronisation
    signal a_sync, b_sync : std_logic_vector(1 downto 0) := (others => '0');
    signal a_clean, b_clean : std_logic := '0';

    -- Historique quadrature
    signal ab_last : std_logic_vector(1 downto 0) := "00";

    -- Compteur de position
    signal position_int : natural := 0;

begin

    --------------------------------------------------------------------
    -- 1. Synchronisation et anti-rebond des signaux A et B
    --------------------------------------------------------------------
    process(i_clk_50, i_rst_n)
    begin
        if i_rst_n = '0' then
            a_sync  <= (others => '0');
            b_sync  <= (others => '0');
            a_clean <= '0';
            b_clean <= '0';
        elsif rising_edge(i_clk_50) then
            a_sync <= a_sync(0) & ENC_A;
            b_sync <= b_sync(0) & ENC_B;

            if a_sync = "11" then
                a_clean <= '1';
            elsif a_sync = "00" then
                a_clean <= '0';
            end if;

            if b_sync = "11" then
                b_clean <= '1';
            elsif b_sync = "00" then
                b_clean <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- 2. Quadrature 4X counting avec limite POS_MAX
    --------------------------------------------------------------------
    process(i_clk_50, i_rst_n)
        variable ab_now : std_logic_vector(1 downto 0);
    begin
        if i_rst_n = '0' then
            position_int <= 0;
            ab_last <= "00";
        elsif rising_edge(i_clk_50) then
            ab_now := a_clean & b_clean;

            case ab_last is
                when "00" =>
                    if ab_now = "01" then position_int <= (position_int + POS_MAX) mod (POS_MAX+1);
                    elsif ab_now = "10" then position_int <= (position_int + 1) mod (POS_MAX+1);
                    end if;
                when "01" =>
                    if ab_now = "11" then position_int <= (position_int + POS_MAX) mod (POS_MAX+1);
                    elsif ab_now = "00" then position_int <= (position_int + 1) mod (POS_MAX+1);
                    end if;
                when "11" =>
                    if ab_now = "10" then position_int <= (position_int + POS_MAX) mod (POS_MAX+1);
                    elsif ab_now = "01" then position_int <= (position_int + 1) mod (POS_MAX+1);
                    end if;
                when "10" =>
                    if ab_now = "00" then position_int <= (position_int + POS_MAX) mod (POS_MAX+1);
                    elsif ab_now = "11" then position_int <= (position_int + 1) mod (POS_MAX+1);
                    end if;
                when others => null;
            end case;

            ab_last <= ab_now;
        end if;
    end process;

    -- Mise à jour de la valeur de position à la sortie
    o_position <= position_int;

end architecture rtl;
