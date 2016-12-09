------------------------------------------------------------------------------
--  LEON3 Demonstration design test bench
--  Copyright (C) 2004 Jiri Gaisler, Gaisler Research
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2016, Cobham Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

library ieee;
use ieee.std_logic_1164.all;
library gaisler;
use gaisler.libdcom.all;
use gaisler.sim.all;
use work.debug.all;
library techmap;
use techmap.gencomp.all;
library micron;
use micron.components.all;
library grlib;
use grlib.stdlib.all;

use work.config.all;	-- configuration


entity testbench is
  generic (
    fabtech   : integer := CFG_FABTECH;
    memtech   : integer := CFG_MEMTECH;
    padtech   : integer := CFG_PADTECH;
    clktech   : integer := CFG_CLKTECH;
    disas     : integer := CFG_DISAS;	-- Enable disassembly to console
    dbguart   : integer := CFG_DUART;	-- Print UART on console
    pclow     : integer := CFG_PCLOW;

    clkperiod : integer := 20;		-- system clock period
    romdepth  : integer := 22		-- rom address depth (flash 4 MB)
 --   sramwidth  : integer := 32;		-- ram data width (8/16/32)
 --   sramdepth  : integer := 20;		-- ram address depth
 --   srambanks  : integer := 2		-- number of ram banks
  );
end;

architecture behav of testbench is

constant promfile  : string := "prom.srec";  -- rom contents
constant sramfile  : string := "ram.srec";  -- ram contents
constant sdramfile : string := "ram.srec"; -- sdram contents


signal SW     : std_logic_vector(4 downto 1);
signal clk : std_logic := '0';
signal Rst    : std_logic := '0';			-- Reset
constant ct : integer := clkperiod/2;

signal address  : std_logic_vector(21 downto 0);
signal data     : std_logic_vector(31 downto 24);

signal romsn    : std_logic;
signal oen      : std_logic;
signal writen   : std_logic;
signal dsuen, dsutx, dsurx, dsubre, dsuact : std_logic;
signal dsurst   : std_logic;
signal error    : std_logic;

signal sdcke    : std_logic;
signal sdcsn    : std_logic;
signal sdwen    : std_logic;                       -- write en
signal sdrasn   : std_logic;                       -- row addr stb
signal sdcasn   : std_logic;                       -- col addr stb
signal dram_ldqm : std_logic;
signal dram_udqm : std_logic;
signal sdclk    : std_logic;
signal dram_ba  : std_logic_vector(1 downto 0);



constant lresp : boolean := false;


signal sa      	: std_logic_vector(12 downto 0);
signal sd   	: std_logic_vector(15 downto 0);


begin

  clk <= not clk after ct * 1 ns; --50 MHz clk
  rst <= dsurst; --reset
  dsuen <= '1';
  dsubre <= '1'; -- inverted on the board
  sw(1) <= rst;

  d3 : entity work.leon3mp
        generic map ( fabtech, memtech, padtech, clktech, disas, dbguart, pclow )
        port map (
            CLK50  => clk,
            LEDS   => open,
            SW     => SW,
            dram_addr => sa,
            dram_ba_0	=> dram_ba(0),
            dram_ba_1	=> dram_ba(1),
            dram_dq	=> sd(15 downto 0),
            dram_clk  	=> sdclk,
            dram_cke  	=> sdcke,
            dram_cs_n   => sdcsn,
            dram_we_n  	=> sdwen,
            dram_ras_n  => sdrasn,
            dram_cas_n  => sdcasn,
            dram_ldqm	  => dram_ldqm,
            dram_udqm	  => dram_udqm,
            uart_txd  	=> dsutx,
            uart_rxd  	=> dsurx);

    u1: entity work.mt48lc16m16a2 generic map (addr_bits => 13, col_bits => 9, index => 1024, fname => sdramfile)
	PORT MAP(
            Dq => sd(15 downto 0), Addr => sa(12 downto 0),
            Ba => dram_ba, Clk => sdclk, Cke => sdcke,
            Cs_n => sdcsn, Ras_n => sdrasn, Cas_n => sdcasn, We_n => sdwen,
            Dqm(0) => dram_ldqm, Dqm(1) => dram_udqm );



  error <= 'H';			  -- ERROR pull-up

   iuerr : process
   begin
     wait for 2500 ns;
     if to_x01(error) = '1' then wait on error; end if;
     assert (to_x01(error) = '1')
       report "*** IU in error mode, simulation halted ***"
         severity failure ;
   end process;

  data <= buskeep(data) after 5 ns;
  sd <= buskeep(sd) after 5 ns;

  dsucom : process
    variable w32 : std_logic_vector(31 downto 0);
    constant txp : time := 160 * 1 ns;
    procedure writeReg(signal dsutx : out std_logic;  address : integer; value : integer) is
    begin
        txc(dsutx, 16#c0#, txp); --control byte
        txa(dsutx, (address / (256*256*256)) , (address / (256*256)), (address / (256)),  address, txp); --adress
        txa(dsutx, (value / (256*256*256)) , (value / (256*256)), (value / (256)), value, txp); --write data
    end;

    procedure readReg(signal dsurx : in std_logic; signal dsutx : out std_logic;  address : integer; value: out std_logic_vector) is

    begin
        txc(dsutx, 16#a0#, txp); --control byte
        txa(dsutx, (address / (256*256*256)) , (address / (256*256)), (address / (256)), address, txp); --adress
        rxi(dsurx, value, txp, lresp); --write data
    end;

    procedure dsucfg(signal dsurx : in std_logic; signal dsutx : out std_logic) is
    variable c8  : std_logic_vector(7 downto 0);
    begin
        dsutx <= '1';
    dsurst <= '0'; --reset low
    wait for 500 ns;
    dsurst <= '1'; --reset high
    --wait; --evig w8
    wait for 5000 ns;
    txc(dsutx, 16#55#, txp);
    --dsucfg(dsutx, dsurx);
    writeReg(dsutx,16#40000000#,16#12345678#);
    writeReg(dsutx,16#40000004#,16#22222222#);
    writeReg(dsutx,16#40000008#,16#33333333#);
    writeReg(dsutx,16#4000000C#,16#44444444#);

    readReg(dsurx,dsutx,16#40000000#,w32);
    readReg(dsurx,dsutx,16#40000004#,w32);
    readReg(dsurx,dsutx,16#40000008#,w32);
    readReg(dsurx,dsutx,16#4000000C#,w32);

    end;

  begin
  dsucfg(dsutx, dsurx);


    wait;
 end process;
end ;

