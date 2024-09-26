// Copyright (c) 2023 Beijing Institute of Open Source Chip
// wdg is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "register.sv"
`include "clk_int_div.sv"
`include "cdc_sync.sv"
`include "wdg_define.sv"

module apb4_wdg (
    apb4_if.slave apb4,
    wdg_if.dut    wdg
);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;
  logic [`WDG_CTRL_WIDTH-1:0] s_wdg_ctrl_d, s_wdg_ctrl_q;
  logic s_wdg_ctrl_en;
  logic [`WDG_PSCR_WIDTH-1:0] s_wdg_pscr_d, s_wdg_pscr_q;
  logic s_wdg_pscr_en;
  logic [`WDG_CNT_WIDTH-1:0] s_wdg_cnt_d, s_wdg_cnt_q;
  logic s_wdg_cnt_en;
  logic [`WDG_CMP_WIDTH-1:0] s_wdg_cmp_d, s_wdg_cmp_q;
  logic s_wdg_cmp_en;
  logic [`WDG_STAT_WIDTH-1:0] s_wdg_stat_d, s_wdg_stat_q;
  logic s_wdg_stat_en;
  logic [`WDG_KEY_WIDTH-1:0] s_wdg_key_d, s_wdg_key_q;
  logic s_wdg_key_en;
  logic [`WDG_FEED_WIDTH-1:0] s_wdg_feed_d, s_wdg_feed_q;
  logic s_wdg_feed_en;
  logic s_valid, s_done, s_in_trg, s_ext_trg, s_tc_trg, s_normal_mode;
  logic s_bit_ovie, s_bit_etr, s_bit_en, s_bit_ovif;
  logic s_ov_irq_trg, s_key_match;

  assign s_apb4_addr     = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready     = 1'b1;
  assign apb4.pslverr    = 1'b0;

  assign s_bit_ovie      = s_wdg_ctrl_q[0];
  assign s_bit_etr       = s_wdg_ctrl_q[1];
  assign s_bit_en        = s_wdg_ctrl_q[2];
  assign s_bit_ovif      = s_wdg_stat_q[0];
  assign s_tc_trg        = s_bit_etr ? s_ext_trg : s_in_trg;
  assign s_normal_mode   = s_bit_en & s_done;
  assign s_key_match     = s_wdg_key_q == 32'h5F37_59DF;
  assign wdg.rst_o       = s_bit_ovif;

  assign s_wdg_ctrl_en   = s_apb4_wr_hdshk && s_apb4_addr == `WDG_CTRL && s_key_match;
  assign s_wdg_ctrl_d    = apb4.pwdata[`WDG_CTRL_WIDTH-1:0];
  dffer #(`WDG_CTRL_WIDTH) u_wdg_ctrl_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_ctrl_en,
      s_wdg_ctrl_d,
      s_wdg_ctrl_q
  );

  assign s_wdg_pscr_en = s_apb4_wr_hdshk && s_apb4_addr == `WDG_PSCR && s_key_match;
  assign s_wdg_pscr_d  = apb4.pwdata[`WDG_PSCR_WIDTH-1:0];
  dffer #(`WDG_PSCR_WIDTH) u_wdg_pscr_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_pscr_en,
      s_wdg_pscr_d,
      s_wdg_pscr_q
  );

  assign s_valid = s_apb4_wr_hdshk && (s_apb4_addr == `WDG_PSCR) && s_key_match && s_done;
  clk_int_div_simple #(`WDG_PSCR_WIDTH) u_clk_int_div_simple (
      .clk_i      (apb4.pclk),
      .rst_n_i    (apb4.presetn),
      .div_i      (s_wdg_pscr_q),
      .div_valid_i(s_valid),
      .div_ready_o(),
      .div_done_o (s_done),
      .clk_cnt_o  (),
      .clk_trg_o  (s_in_trg),
      .clk_o      ()
  );

  assign s_wdg_cnt_en = s_normal_mode && s_tc_trg;
  always_comb begin
    s_wdg_cnt_d = s_wdg_cnt_q;
    if (s_normal_mode) begin
      if (s_wdg_feed_q) begin
        s_wdg_cnt_d = '0;
      end else if (s_wdg_cnt_q >= s_wdg_cmp_q - 1) begin
        s_wdg_cnt_d = '0;
      end else begin
        s_wdg_cnt_d = s_wdg_cnt_q + 1'b1;
      end
    end
  end
  dffer #(`WDG_CNT_WIDTH) u_wdg_cnt_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_cnt_en,
      s_wdg_cnt_d,
      s_wdg_cnt_q
  );

  assign s_wdg_cmp_en = s_apb4_wr_hdshk && s_apb4_addr == `WDG_CMP && s_key_match;
  assign s_wdg_cmp_d  = apb4.pwdata[`WDG_CMP_WIDTH-1:0];
  dffer #(`WDG_CMP_WIDTH) u_wdg_cmp_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_cmp_en,
      s_wdg_cmp_d,
      s_wdg_cmp_q
  );

  cdc_sync #(
      .STAGE     (2),
      .DATA_WIDTH(1)
  ) u_ext_trg_cdc_sync (
      apb4.pclk,
      apb4.presetn,
      wdg.rtc_clk_i,
      s_ext_trg
  );

  cdc_sync #(
      .STAGE     (2),
      .DATA_WIDTH(1)
  ) u_irq_cdc_sync (
      apb4.pclk,
      apb4.presetn,
      s_wdg_cnt_q >= s_wdg_cmp_q - 1,
      s_ov_irq_trg
  );

  assign s_wdg_stat_en = (s_bit_ovif && s_apb4_rd_hdshk && s_apb4_addr == `WDG_STAT) || (~s_bit_ovif && s_bit_en && s_bit_ovie && s_ov_irq_trg);
  always_comb begin
    s_wdg_stat_d = s_wdg_stat_q;
    if (s_bit_ovif && s_apb4_rd_hdshk && s_apb4_addr == `WDG_STAT) begin
      s_wdg_stat_d = '0;
    end else if (~s_bit_ovif && s_bit_en && s_bit_ovie && s_ov_irq_trg) begin
      s_wdg_stat_d = '1;
    end
  end
  dffer #(`WDG_STAT_WIDTH) u_wdg_stat_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_stat_en,
      s_wdg_stat_d,
      s_wdg_stat_q
  );

  assign s_wdg_key_en = s_apb4_wr_hdshk;
  always_comb begin
    s_wdg_key_d = s_wdg_key_q;
    if (s_apb4_wr_hdshk) begin
      if (s_apb4_addr == `WDG_KEY) begin
        s_wdg_key_d = apb4.pwdata[`WDG_KEY_WIDTH-1:0];
      end else begin
        s_wdg_key_d = '0;
      end
    end
  end
  dffer #(`WDG_KEY_WIDTH) u_wdg_key_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_key_en,
      s_wdg_key_d,
      s_wdg_key_q
  );

  assign s_wdg_feed_en = s_apb4_wr_hdshk && s_apb4_addr == `WDG_FEED && s_key_match;
  assign s_wdg_feed_d  = apb4.pwdata[`WDG_FEED_WIDTH-1:0];
  dffer #(`WDG_FEED_WIDTH) u_wdg_feed_dffer (
      apb4.pclk,
      apb4.presetn,
      s_wdg_feed_en,
      s_wdg_feed_d,
      s_wdg_feed_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `WDG_CTRL: apb4.prdata[`WDG_CTRL_WIDTH-1:0] = s_wdg_ctrl_q;
        `WDG_PSCR: apb4.prdata[`WDG_PSCR_WIDTH-1:0] = s_wdg_pscr_q;
        `WDG_CMP:  apb4.prdata[`WDG_CMP_WIDTH-1:0] = s_wdg_cmp_q;
        `WDG_STAT: apb4.prdata[`WDG_STAT_WIDTH-1:0] = s_wdg_stat_q;
        `WDG_KEY:  apb4.prdata[`WDG_KEY_WIDTH-1:0] = s_wdg_key_q;
        `WDG_FEED: apb4.prdata[`WDG_FEED_WIDTH-1:0] = s_wdg_feed_q;
        default:   apb4.prdata = '0;
      endcase
    end
  end

endmodule
