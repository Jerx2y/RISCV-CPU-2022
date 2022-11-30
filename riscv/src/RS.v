`include "defines.v"

module RS (
    input wire  clk, rst, rdy,

    // Issue
    input  wire              IS_sgn,
    input  wire   [ 5 : 0]   IS_opcode,
    input  wire   [31 : 0]   IS_rs1_val,
    input  wire   [31 : 0]   IS_rs2_val,
    input  wire              IS_rs1_rdy,
    input  wire              IS_rs2_rdy,
    output wire              IS_RS_full,

    // ROB
    input  wire   [`ROBSZ]   ROB_name,

    // ALU
    output reg               ALU_sgn,
    output reg    [ 5 : 0]   ALU_opcode,
    output reg    [`ROBID]   ALU_name,
    output reg    [31 : 0]   ALU_lhs,
    output reg    [31 : 0]   ALU_rhs,

    // CDBA
    input wire               CDBA_sgn,
    input wire    [31 : 0]   CDBA_result,
    input wire    [`ROBID]   CDBA_ROB_name
);

    reg   [`RSSZ]    busy;
    reg   [ 5 : 0]   opcode  [`RSSZ];
    reg   [31 : 0]   val1    [`RSSZ];
    reg   [31 : 0]   val2    [`RSSZ];
    reg   [`RSSZ]    rdy1;
    reg   [`RSSZ]    rdy2;
    reg   [`ROBSZ]   name    [`RSSZ];

    wire  [`RSSZ]    ready = rdy1 & rdy2 & busy;
    wire  [`RSSZ]    ready_pos = ready & (-ready);
    wire  [`RSSZ]    free_pos = (~busy) & (-(~busy));

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            
        end else if (!rdy) begin

        end else begin
            if (IS_sgn) begin
                for (i = 0; i < `RSSI; i = i + 1) if (free_pos[i]) begin
                    busy[i]    <=  `True;
                    opcode[i]  <=  IS_opcode;
                    val1[i]    <=  IS_rs1_val;
                    val2[i]    <=  IS_rs2_val;
                    rdy1[i]    <=  IS_rs1_rdy;
                    rdy2[i]    <=  IS_rs2_rdy;
                    name[i]    <=  ROB_name;
                end
            end

            if (ready_pos != 0) begin
                ALU_sgn <= `True;
                for (i = 0; i < `RSSI; i = i + 1) if (ready_pos[i]) begin
                    ALU_opcode <= opcode[i];
                    ALU_lhs    <= val1[i];
                    ALU_rhs    <= val2[i];
                    ALU_name   <= name[i];
                    busy[i]    <= `False;
                end
            end else begin
                ALU_sgn <= `False;
            end

            if (CDBA_sgn) begin
                for (i = 0; i < `RSSI; i = i + 1) begin
                    if (!rdy1[i] && val1[i][`ROBID] == CDBA_ROB_name) begin
                        rdy1[i] <= `True;
                        val1[i] <= CDBA_result;
                    end
                    if (!rdy2[i] && val2[i][`ROBID] == CDBA_ROB_name) begin
                        rdy2[i] <= `True;
                        val2[i] <= CDBA_result;
                    end               
                end
            end

        end
    end

endmodule