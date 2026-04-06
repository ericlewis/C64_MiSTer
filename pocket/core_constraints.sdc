#
# user core constraints
#
# APF already creates the raw 74.25 MHz clocks and derives the PLL clocks.
# Complete clock uncertainty derivation here, then cut only the genuinely
# asynchronous domains used by the Pocket wrapper.
#

derive_clock_uncertainty

#
# The core uses separate asynchronous domains for:
# - APF bridge SPI clock
# - the raw 74.25 MHz inputs
# - each Pocket PLL output crossing via synchronizers / async FIFOs
#
# The previous constraint file referenced an old mf_pllbase instance that no
# longer exists, so those cuts were not reliably matching the current design.
# Match both the current pocket_pll instance name and the older path variant so
# the constraint stays stable across regenerations.
#

set_clock_groups -asynchronous \
 -group [get_clocks {bridge_spiclk}] \
 -group [get_clocks {clk_74a}] \
 -group [get_clocks {clk_74b}] \
 -group [get_clocks -nowarn {*|pll|pll_inst|general[0].gpll~PLL_OUTPUT_COUNTER|divclk *|mp1|mf_pllbase_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
 -group [get_clocks -nowarn {*|pll|pll_inst|general[1].gpll~PLL_OUTPUT_COUNTER|divclk *|mp1|mf_pllbase_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] \
 -group [get_clocks -nowarn {*|pll|pll_inst|general[2].gpll~PLL_OUTPUT_COUNTER|divclk *|mp1|mf_pllbase_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] \
 -group [get_clocks -nowarn {*|pll|pll_inst|general[3].gpll~PLL_OUTPUT_COUNTER|divclk *|mp1|mf_pllbase_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk}] \
 -group [get_clocks -nowarn {*|pll|pll_inst|general[4].gpll~PLL_OUTPUT_COUNTER|divclk *|mp1|mf_pllbase_inst|altera_pll_i|general[4].gpll~PLL_OUTPUT_COUNTER|divclk}]

#
# These board-facing status inputs are asynchronous to the core and are
# synchronized in RTL before use.
#
set_false_path -from [get_ports {vblank port_ir_rx dbg_rx user2 aux_sda cram0_wait cram1_wait}]

#
# The Pocket board interfaces below do not have a source-synchronous timing
# contract in this core. Exclude pure chip I/O timing at the package boundary
# so TimeQuest focuses on internal closure instead of unconstrained external
# interface paths.
#
set_false_path -to [get_ports {
    cart_tran_bank2[*] cart_tran_bank2_dir
    cart_tran_bank3[*] cart_tran_bank3_dir
    cart_tran_bank1[*] cart_tran_bank1_dir
    cart_tran_bank0[*] cart_tran_bank0_dir
    cart_tran_pin30 cart_tran_pin30_dir cart_pin30_pwroff_reset
    cart_tran_pin31 cart_tran_pin31_dir
    port_ir_tx port_ir_rx_disable
    port_tran_si port_tran_si_dir port_tran_so port_tran_so_dir
    port_tran_sck port_tran_sck_dir port_tran_sd port_tran_sd_dir
    cram0_a[*] cram0_clk cram0_adv_n cram0_cre cram0_ce0_n cram0_ce1_n cram0_oe_n cram0_we_n cram0_ub_n cram0_lb_n
    cram1_a[*] cram1_clk cram1_adv_n cram1_cre cram1_ce0_n cram1_ce1_n cram1_oe_n cram1_we_n cram1_ub_n cram1_lb_n
    dram_a[*] dram_ba[*] dram_dqm[*] dram_clk dram_cke dram_ras_n dram_cas_n dram_we_n
    sram_a[*] sram_oe_n sram_we_n sram_ub_n sram_lb_n
    dbg_tx user1 aux_scl vpll_feed
    video_rgb[*] video_rgb_clock video_rgb_clock_90 video_de video_skip video_vs video_hs
    audio_mclk audio_dac audio_lrck
}]
