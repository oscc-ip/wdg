// Copyright (c) 2023 Beijing Institute of Open Source Chip
// wdg is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_WDG_DEF_SV
`define INC_WDG_DEF_SV

/* register mapping
 * WDG_CTRL:
 * BITS:   | 31:3 | 2  | 1   | 0    |
 * FIELDS: | RES  | EN | ETR | OVIE |
 * PERMS:  | NONE | RW | RW  | RW   |
 * ----------------------------------
 * WDG_PSCR:
 * BITS:   | 31:20 | 19:0 |
 * FIELDS: | RES   | PSCR |
 * PERMS:  | NONE  | W    |
 * ----------------------------------
 * WDG_CNT:
 * BITS:   | 31:0 |
 * FIELDS: | CNT  |
 * PERMS:  | none |
 * ----------------------------------
 * WDG_CMP:
 * BITS:   | 31:0 |
 * FIELDS: | CMP  |
 * PERMS:  | RW   |
 * ----------------------------------
 * WDG_STAT:
 * BITS:   | 31:1  | 0    |
 * FIELDS: | RES   | OVIF |
 * PERMS:  | NONE  | R    |
 * ----------------------------------
 * WDG_KEY:
 * BITS:   | 31:0 |
 * FIELDS: | KEY  |
 * PERMS:  | RW   |
 * ----------------------------------
 * WDG_FEED:
 * BITS:   | 31:1 | 0    |
 * FIELDS: | RES  | FEED |
 * PERMS:  | NONE | RW   |
 * ----------------------------------
*/

// verilog_format: off
`define WDG_CTRL 4'b0000 // BASEADDR + 0x00
`define WDG_PSCR 4'b0001 // BASEADDR + 0x04
`define WDG_CNT  4'b0010 // BASEADDR + 0x08
`define WDG_CMP  4'b0011 // BASEADDR + 0x0C
`define WDG_STAT 4'b0100 // BASEADDR + 0x10
`define WDG_KEY  4'b0101 // BASEADDR + 0x14
`define WDG_FEED 4'b0110 // BASEADDR + 0x18

`define WDG_CTRL_ADDR {26'b0, `WDG_CTRL, 2'b00}
`define WDG_PSCR_ADDR {26'b0, `WDG_PSCR, 2'b00}
`define WDG_CNT_ADDR  {26'b0, `WDG_CNT , 2'b00}
`define WDG_CMP_ADDR  {26'b0, `WDG_CMP , 2'b00}
`define WDG_STAT_ADDR {26'b0, `WDG_STAT, 2'b00}
`define WDG_KEY_ADDR  {26'b0, `WDG_KEY , 2'b00}
`define WDG_FEED_ADDR {26'b0, `WDG_FEED, 2'b00}

`define WDG_CTRL_WIDTH 3
`define WDG_PSCR_WIDTH 20
`define WDG_CNT_WIDTH  32
`define WDG_CMP_WIDTH  32
`define WDG_STAT_WIDTH 1
`define WDG_KEY_WIDTH  32
`define WDG_FEED_WIDTH 1

`define WDG_PSCR_MIN_VAL  {{(`WDG_PSCR_WIDTH-2){1'b0}}, 2'd2}
// verilog_format: on

interface wdg_if (
    input logic rtc_clk_i
);
  logic rst_o;

  modport dut(input rtc_clk_i, output rst_o);
  modport tb(input rtc_clk_i, input rst_o);
endinterface

`endif
