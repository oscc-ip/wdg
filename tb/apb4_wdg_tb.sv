// Copyright (c) 2023-2024 Miao Yuchi <miaoyuchi@ict.ac.cn>
// wdg is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "apb4_if.sv"
`include "wdg_define.sv"

module apb4_wdg_tb ();
  localparam CLK_PEROID = 10;
  localparam RTC_CLK_PEROID = 50; // sim set
  logic rst_n_i, clk_i, rtc_clk_i;

  initial begin
    clk_i = 1'b0;
    forever begin
      #(CLK_PEROID / 2) clk_i <= ~clk_i;
    end
  end

  initial begin
    rtc_clk_i = 1'b0;
    forever begin
      #(RTC_CLK_PEROID / 2) rtc_clk_i <= ~rtc_clk_i;
    end
  end

  task sim_reset(int delay);
    rst_n_i = 1'b0;
    repeat (delay) @(posedge clk_i);
    #1 rst_n_i = 1'b1;
  endtask

  initial begin
    sim_reset(40);
  end

  apb4_if u_apb4_if (
      clk_i,
      rst_n_i
  );

  wdg_if u_wdg_if (rtc_clk_i);

  test_top u_test_top (
      .apb4(u_apb4_if.master),
      .wdg (u_wdg_if.tb)
  );
  apb4_wdg u_apb4_wdg (
      .apb4(u_apb4_if.slave),
      .wdg (u_wdg_if.dut)
  );

endmodule
