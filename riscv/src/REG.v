`include "defines.v"

module REG (
    input wire clk, rst, rdy,

    // ISSUE
    input  wire   [ 4 : 0]   IS_rs1,
    input  wire   [ 4 : 0]   IS_rs2,
    input  wire              IS_sgn,
    input  wire   [ 4 : 0]   IS_rd,
    output wire   [31 : 0]   IS_rs1_val,
    output wire   [31 : 0]   IS_rs2_val,
    output wire              IS_rs1_rdy,
    output wire              IS_rs2_rdy,

    // ROB
    input  wire   [`ROBID]   ROB_name,
    input  wire              ROB_rdy1,
    input  wire              ROB_rdy2,
    input  wire   [31 : 0]   ROB_val1,
    input  wire   [31 : 0]   ROB_val2,
    output wire   [`ROBID]   ROB_ord1,
    output wire   [`ROBID]   ROB_ord2
);

    reg [31 : 0]  reg_val [31 : 0];
    reg [`ROBID]  reg_ord [31 : 0];
    reg           reg_rdy [31 : 0];

    assign ROB_ord1   = reg_ord[IS_rs1];
    assign ROB_ord2   = reg_ord[IS_rs2];

    assign IS_rs1_val = reg_rdy[IS_rs1] ? reg_val[IS_rs1] : (ROB_rdy1 ? ROB_val1 : reg_ord[IS_rs1]);
    assign IS_rs2_val = reg_rdy[IS_rs2] ? reg_val[IS_rs2] : (ROB_rdy2 ? ROB_val2 : reg_ord[IS_rs2]);
    assign IS_rs1_rdy = reg_rdy[IS_rs1] || ROB_rdy1;
    assign IS_rs2_rdy = reg_rdy[IS_rs2] || ROB_rdy2;

    always @(*) begin
        if (IS_sgn) begin
            reg_rdy[IS_rd] = `False;
            reg_ord[IS_rd] = ROB_name;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            
        end else if (!rdy) begin
            
        end else begin
            
        end
    end

endmodule