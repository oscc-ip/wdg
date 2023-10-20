// Copyright (c) 2023 Beijing Institute of Open Source Chip
// timer is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

// verilog_format: off
`define WDG_CTRL 4'b0000 //BASEADDR+0x00
`define WDG_PSCR 4'b0001 //BASEADDR+0x04
`define WDG_CNT  4'b0010 //BASEADDR+0x08
`define WDG_CMP  4'b0011 //BASEADDR+0x0C
`define WDG_KEY  4'b0100 //BASEADDR+0x10
// verilog_format: on

/* register mapping
 * WDG_CTRL:
 * BITS:   | 31:3 | 2  | 1    | 0     |
 * FIELDS: | RES  | EN | OVIE | OVIF  |
 * PERMS:  | NONE | RW | RW   | RC_W0 |
 * ------------------------------------
 * WDG_PSCR:
 * BITS:   | 31:20 | 19:0 |
 * FIELDS: | RES   | PSCR |
 * PERMS:  | NONE  | W    |
 * ------------------------------------
 * WDG_CNT:
 * BITS:   | 31:0 |
 * FIELDS: | CNT  |
 * PERMS:  | none |
 * ------------------------------------
 * WDG_CMP:
 * BITS:   | 31:0 |
 * FIELDS: | CMP  |
 * PERMS:  | RW   |
 * ------------------------------------
 * WDG_KEY:
 * BITS:   | 31:0 |
 * FIELDS: | KEY  |
 * PERMS:  | RW   |
*/

module apb4_wdg (
    // verilog_format: off
    apb4_if.slave apb4,
    // verilog_format: on
    input logic   rtc_clk_i,
    output logic  rst_o
);

  logic [3:0] s_apb_addr;
  logic [31:0] s_wdg_ctrl_d, s_wdg_ctrl_q;
  logic [31:0] s_wdg_pscr_d, s_wdg_pscr_q;
  logic [31:0] s_wdg_cnt_d, s_wdg_cnt_q;
  logic [31:0] s_wdg_cmp_d, s_wdg_cmp_q;
  logic [31:0] s_wdg_key_d, s_wdg_key_q;
  logic s_valid, s_ready, s_done, s_tc_clk;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk, s_normal_mode;
  logic s_ov_irq, s_config_mode_d, s_config_mode_q;

  assign s_apb_addr      = apb.paddr[5:2];
  assign s_apb4_wr_hdshk = apb.psel && apb.penable && apb.pwrite;
  assign s_apb4_rd_hdshk = apb.psel && apb.penable && (~apb.pwrite);
  assign s_normal_mode   = s_wdg_ctrl_q[2] & s_done;
  assign s_ov_irq        = s_wdg_ctrl_q[1] & s_wdg_ctrl_q[0];
  assign rst_o           = s_ov_irq;

  always_comb begin
    s_wdg_pscr_d = s_wdg_pscr_q;
    if (s_apb4_wr_hdshk && (s_apb_addr == `WDG_PSCR) && s_config_mode_q) begin
      s_wdg_pscr_d = apb4.pwdata < 2 ? 32'd2 : abp4.pwdata;
    end
  end

  dffr #(32) u_wdg_pscr_dffr (
      .clk_i  (apb4.hclk),
      .rst_n_i(apb4.hresetn),
      .dat_i  (s_wdg_pscr_d),
      .dat_o  (s_wdg_pscr_q)
  );

  assign s_valid = s_apb4_wr_hdshk && (s_apb_addr == `WDG_PSCR) && s_config_mode_q && s_done;
  clk_int_even_div_simple u_clk_int_even_div_simple (
      .clk_i      (apb4.hclk),
      .rst_n_i    (apb4.hresetn),
      .div_i      (s_wdg_pscr_q),
      .div_valid_i(s_valid),
      .div_ready_o(s_ready),
      .div_done_o (s_done),
      .clk_o      (s_tc_clk)
  );

  always_comb begin
    s_wdg_cnt_d = s_wdg_cnt_q;
    if (s_normal_mode) begin
      if (s_wdg_cnt_q == s_wdg_cmp_q) begin
        s_wdg_cnt_d = '0;
      end else begin
        s_wdg_cnt_d = s_wdg_cnt_q + 1'b1;
      end
    end
  end

  dffr #(32) u_wdg_cnt_dffr (
      s_tc_clk,
      apb4.hresetn,
      s_wdg_cnt_d,
      s_wdg_cnt_q
  );

  always_comb begin
    s_wdg_ctrl_d = s_wdg_ctrl_q;
    if (s_apb4_wr_hdshk && s_apb_addr == `WDG_CTRL && s_config_mode_q) begin
      s_wdg_ctrl_d = apb4.pwdata;
    end else if (s_normal_mode) begin
      if (s_wdg_cnt_q == s_wdg_cmp_q) begin
        s_wdg_ctrl_d[0] = 1'b1;
      end
    end
  end

  dffr #(32) u_wdg_ctrl_dffr (
      apb4.hclk,
      apb4.hresetn,
      s_wdg_ctrl_d,
      s_wdg_ctrl_q
  );

  assign s_wdg_cmp_d = (s_apb4_wr_hdshk && s_apb_addr == `WDG_CMP && s_config_mode_q) ? apb4.pwdata : s_wdg_cmp_q;
  dffr #(32) u_wdg_cmp_dffr (
      apb4.hclk,
      apb4.hresetn,
      s_wdg_cmp_d,
      s_wdg_cmp_q
  );

  always_comb begin
    s_wdg_key_d = s_wdg_key_q;
    if (s_apb4_wr_hdshk) begin
      if (s_apb_addr == `WDG_KEY) begin
        s_wdg_key_d = apb4.pwdata;
      end else if (s_config_mode_q) begin
        s_wdg_key_d = '0;
      end
    end
  end
  dffr #(32) u_wdg_key_dffr (
      apb4.hclk,
      apb4.hresetn,
      s_wdg_key_d,
      s_wdg_key_q
  );

  // magic number: 0x5F3759DF
  always_comb begin
    s_config_mode_d = s_config_mode_q;
    if (s_apb4_wr_hdshk && s_config_mode_q) begin
      s_config_mode_d = 1'b0;
    end else if (s_wdg_key_q == 32'h5F37_59DF) begin
      s_config_mode_d = 1'b1;
    end
  end

  dffr #(1) u_wdg_config_mode_dffr (
      apb4.hclk,
      apb4.hresetn,
      s_config_mode_d,
      s_config_mode_q
  );

  always_comb begin
    apb.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb_addr)
        `WDG_CTRL: apb.prdata = s_wdg_ctrl_q;
        `WDG_PSCR: apb4.prdata = s_wdg_pscr_q;
        `WDG_CMP:  apb.prdata = s_wdg_cmp_q;
      endcase
    end
  end

  assign apb.pready  = 1'b1;
  assign apb.pslverr = 1'b0;

endmodule

