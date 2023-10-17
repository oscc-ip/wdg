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
`define TIM_CTRL 4'b0000 //BASEADDR+0x00
`define TIM_PSCR 4'b0001 //BASEADDR+0x04
`define TIM_CNT  4'b0010 //BASEADDR+0x08
`define TIM_CMP  4'b0011 //BASEADDR+0x0C
// verilog_format: on

/* register mapping
 * TIM_CTRL:
 * BITS:   | 31:3 | 2  | 1    | 0     |
 * FIELDS: | RES  | EN | OVIE | OVIF  |
 * PERMS:  | NONE | RW | RW   | RC_W0 |
 * ------------------------------------
 * TIM_PSCR:
 * BITS:   | 31:20 | 19:0 |
 * FIELDS: | RES   | PSCR |
 * PERMS:  | NONE  | W    |
 * ------------------------------------
 * TIM_CNT:
 * BITS:   | 31:0 |
 * FIELDS: | CNT  |
 * PERMS:  | none |
 * ------------------------------------
 * TIM_CMP:
 * BITS:   | 31:0 |
 * FIELDS: | CMP  |
 * PERMS:  | RW   |
*/
module apb4_timer (
    // verilog_format: off
    apb4_if.slave apb4,
    // verilog_format: on
    input logic   rtc_clk_i,
    output logic  rst_o
);

  logic [3:0] s_apb_addr;
  logic [31:0] s_tim_ctrl_d, s_tim_ctrl_q;
  logic [31:0] s_tim_pscr_d, s_tim_pscr_q;
  logic [31:0] s_tim_cnt_d, s_tim_cnt_q;
  logic [31:0] s_tim_cmp_d, s_tim_cmp_q;
  logic s_valid, s_ready, s_done, s_tc_clk;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk, s_normal_mode;
  logic s_ov_irq;

  assign s_apb_addr      = apb.paddr[5:2];
  assign s_apb4_wr_hdshk = apb.psel && apb.penable && apb.pwrite;
  assign s_apb4_rd_hdshk = apb.psel && apb.penable && (~apb.pwrite);
  assign s_normal_mode   = s_tim_ctrl_q[2] & s_done;
  assign s_ov_irq        = s_tim_ctrl_q[1] & s_tim_ctrl_q[0];
  assign rst_o           = s_ov_irq;

  always_comb begin
    s_tim_pscr_d = s_tim_pscr_q;
    if (s_apb4_wr_hdshk && s_apb_addr == `TIM_DIV) begin
      s_tim_pscr_d = apb4.pwdata < 2 ? 32'd2 : abp4.pwdata;
    end
  end

  dffr #(32) u_tim_pscr_dffr (
      .clk_i  (apb4.hclk),
      .rst_n_i(apb4.hresetn),
      .dat_i  (s_tim_pscr_d),
      .dat_o  (s_tim_pscr_q)
  );

  assign s_valid = s_apb4_wr_hdshk && s_apb_addr == `TIM_PSCR && s_done;
  clk_int_even_div_simple u_clk_int_even_div_simple (
      .clk_i      (apb4.hclk),
      .rst_n_i    (apb4.hresetn),
      .div_i      (s_tim_pscr_q),
      .div_valid_i(s_valid),
      .div_ready_o(s_ready),
      .div_done_o (s_done),
      .clk_o      (s_tc_clk)
  );

  always_comb begin
    s_tim_cnt_d = s_tim_cnt_q;
    if (s_normal_mode) begin
      if (s_tim_cnt_q == s_tim_cmp_q) begin
        s_tim_cnt_d = '0;
      end else begin
        s_tim_cnt_d = s_tim_cnt_q + 1'b1;
      end
    end
  end

  dffr #(32) u_tim_cnt_dffr (
      s_tc_clk,
      apb4.hresetn,
      s_tim_cnt_d,
      s_tim_cnt_q
  );

  always_comb begin
    s_tim_ctrl_d = s_tim_ctrl_q;
    if (s_apb4_wr_hdshk && s_apb_addr == `TIM_CTRL) begin
      s_tim_ctrl_d = apb4.pwdata;
    end else if (s_normal_mode) begin
      if (s_tim_cnt_q == s_tim_cmp_q) begin
        s_tim_ctrl_d[0] = 1'b1;
      end
    end
  end

  dffr #(32) u_tim_ctrl_dffr (
      apb4.hclk,
      apb4.hresetn,
      s_tim_ctrl_d,
      s_tim_ctrl_q
  );

  assign s_tim_cmp_d = (s_apb4_wr_hdshk && s_apb_addr == `TIM_CMP) ? apb4.pwdata : s_tim_cmp_q;
  dffr #(32) u_tim_cmp_dffr (
      apb4.hclk,
      apb4.hresetn,
      s_tim_cmp_d,
      s_tim_cmp_q
  );

  always_comb begin
    apb.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb_addr)
        `TIM_CTRL: apb.prdata = s_tim_ctrl_q;
        `TIM_PSCR: apb4.prdata = s_tim_pscr_q;
        `TIM_CMP:  apb.prdata = s_tim_cmp_q;
      endcase
    end
  end

  assign apb.pready  = 1'b1;
  assign apb.pslverr = 1'b0;

endmodule

