// Copyright (c) 2023 Beijing Institute of Open Source Chip
// wdg is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_WDG_TEST_SV
`define INC_WDG_TEST_SV

`include "apb4_master.sv"
`include "wdg_define.sv"

class WDGTest extends APB4Master;
  string                 name;
  int                    wr_val;
  int                    magic_num;
  virtual apb4_if.master apb4;
  virtual wdg_if.tb      wdg;

  extern function new(string name = "wdg_test", virtual apb4_if.master apb4, virtual wdg_if.tb wdg);
  extern task automatic test_reset_reg();
  extern task automatic test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task automatic test_clk_div(input bit [31:0] run_times = 10);
  extern task automatic test_rtc_clk();
  extern task automatic test_inc_cnt(input bit [31:0] run_times = 10);
  extern task automatic test_irq(input bit [31:0] run_times = 1000);
endclass

function WDGTest::new(string name, virtual apb4_if.master apb4, virtual wdg_if.tb wdg);
  super.new("apb4_master", apb4);
  this.name      = name;
  this.wr_val    = 0;
  this.magic_num = 32'h5F37_59DF;
  this.apb4      = apb4;
  this.wdg       = wdg;
endfunction

task automatic WDGTest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  this.rd_check(`WDG_CTRL_ADDR, "CTRL REG", 32'b0 & {`WDG_CTRL_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`WDG_PSCR_ADDR, "PSCR REG", 32'b0 & {`WDG_PSCR_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`WDG_CMP_ADDR, "CMP REG", 32'b0 & {`WDG_CMP_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`WDG_STAT_ADDR, "STAT REG", 32'b0 & {`WDG_STAT_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`WDG_KEY_ADDR, "KEY REG", 32'b0 & {`WDG_KEY_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task automatic WDGTest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    this.write(`WDG_KEY_ADDR, this.magic_num);
    this.wr_rd_check(`WDG_CTRL_ADDR, "CTRL REG", $random & {`WDG_CTRL_WIDTH{1'b1}}, Helper::EQUL);
    this.write(`WDG_KEY_ADDR, this.magic_num);
    this.wr_rd_check(`WDG_CMP_ADDR, "CMP REG", $random & {`WDG_CMP_WIDTH{1'b1}}, Helper::EQUL);
    this.write(`WDG_KEY_ADDR, this.magic_num);
    this.wr_rd_check(`WDG_FEED_ADDR, "FEED REG", $random & {`WDG_FEED_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`WDG_KEY_ADDR, "KEY REG", $random & {`WDG_KEY_WIDTH{1'b1}}, Helper::EQUL);
  end
  // verilog_format: on
endtask

task automatic WDGTest::test_clk_div(input bit [31:0] run_times = 10);
  $display("=== [test wdg clk div] ===");
  repeat (200) @(posedge this.apb4.pclk);
  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b0 & {`WDG_CTRL_WIDTH{1'b1}});

  repeat (200) @(posedge this.apb4.pclk);
  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_PSCR_ADDR, 32'd9 & {`WDG_PSCR_WIDTH{1'b1}});

  repeat (200) @(posedge this.apb4.pclk);
  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_PSCR_ADDR, 32'd3 & {`WDG_PSCR_WIDTH{1'b1}});

  repeat (200) @(posedge this.apb4.pclk);
  for (int i = 0; i < run_times; i++) begin
    this.wr_val = ($random % 20) & {`WDG_PSCR_WIDTH{1'b1}};
    this.write(`WDG_KEY_ADDR, this.magic_num);
    this.wr_rd_check(`WDG_PSCR_ADDR, "PSCR REG", this.wr_val, Helper::EQUL);
    repeat (200) @(posedge this.apb4.pclk);
  end
endtask

task automatic WDGTest::test_rtc_clk();
  $display("=== [test wdg rtc clk] ===");
  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b010 & {`WDG_CTRL_WIDTH{1'b1}});
  $display("%t", $time);
  repeat (200) @(posedge this.apb4.pclk);
endtask

task automatic WDGTest::test_inc_cnt(input bit [31:0] run_times = 10);
  $display("=== [test wdg inc cnt] ===");
  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b0 & {`WDG_CTRL_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_PSCR_ADDR, 32'd3 & {`WDG_PSCR_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CMP_ADDR, 32'hF & {`WDG_CMP_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b100 & {`WDG_CTRL_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_FEED_ADDR, 32'b1 & {`WDG_FEED_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_FEED_ADDR, 32'b0 & {`WDG_FEED_WIDTH{1'b1}});

  repeat (200) @(posedge this.apb4.pclk);
endtask

task automatic WDGTest::test_irq(input bit [31:0] run_times = 1000);
  super.test_irq();
  this.read(`WDG_STAT_ADDR);

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b0 & {`WDG_CTRL_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_PSCR_ADDR, 32'd5 & {`WDG_PSCR_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CMP_ADDR, 32'hF & {`WDG_CMP_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b101 & {`WDG_CTRL_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_FEED_ADDR, 32'b1 & {`WDG_FEED_WIDTH{1'b1}});

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_FEED_ADDR, 32'b0 & {`WDG_FEED_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);

  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b100 & {`WDG_CTRL_WIDTH{1'b1}});
  wait(this.wdg.rst_o);
  this.read(`WDG_STAT_ADDR);
  $display("super.rd_data: %h", super.rd_data);
  repeat (200) @(posedge this.apb4.pclk);
  this.write(`WDG_KEY_ADDR, this.magic_num);
  this.write(`WDG_CTRL_ADDR, 32'b101 & {`WDG_CTRL_WIDTH{1'b1}});
endtask
`endif
