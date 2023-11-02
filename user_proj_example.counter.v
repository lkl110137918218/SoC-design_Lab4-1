// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */
`define MPRJ_IO_PADS_1 19	/* number of user GPIO pads on user1 side */
`define MPRJ_IO_PADS_2 19	/* number of user GPIO pads on user2 side */
`define MPRJ_IO_PADS (`MPRJ_IO_PADS_1 + `MPRJ_IO_PADS_2)

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    // wire [`MPRJ_IO_PADS-1:0] io_in;
    // wire [`MPRJ_IO_PADS-1:0] io_out;
    // wire [`MPRJ_IO_PADS-1:0] io_oeb;
    
    wire [BITS-1:0] rdata; 
    wire [BITS-1:0] wdata;

    wire [BITS-1:0] count;
    wire [31:0] la_write;

    wire [3:0] bram_we;
    // wire [31:0] bram_addr;

    reg  [3:0] delay_cnt;

    wire valid;
    reg ready;
    wire decoded;

     // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i && decoded; 
    assign bram_we = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;
    assign wbs_ack_o = ready;

    assign decoded = wbs_adr_i[31:20] == 12'h380 ? 1'b1 : 1'b0;   

    // version 1 error
    // assign valid = (ready) ? wbs_cyc_i && wbs_stb_i && decoded: 1'b0; 
    // assign bram_we = (ready) ? wbs_sel_i & {4{wbs_we_i}} : 4'd0;
    // assign wdata = (ready) ? wbs_dat_i : 32'd0;
    // assign bram_addr = (wbs_cyc_i && wbs_stb_i && decoded && (wbs_sel_i & {4{wbs_we_i}} == 4'b1111)) ? (ready) ? wbs_adr_i : 32'd0 : (delay_cnt == DELAYS) ? wbs_adr_i : 32'd0; 
    // assign wbs_ack_o = ready;
    // assign wbs_dat_o = rdata;

    // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;
       
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            ready <= 1'b0;
            delay_cnt <= 16'b0;
        end else begin
            ready <= 1'b0;
            if ( valid && !ready ) begin
                if ( delay_cnt == DELAYS ) begin
                    delay_cnt <= 16'b0;
                    ready <= 1'b1;
                end else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
        end
    end

    bram user_bram (
        .CLK(wb_clk_i),
        .WE0(bram_we),
        .EN0(valid),
        .Di0(wdata),
        .Do0(rdata),
        .A0(wbs_adr_i)
    );


endmodule



`default_nettype wire
