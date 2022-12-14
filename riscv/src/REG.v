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
    output wire   [`ROBID]   ROB_ord2,
    input  wire              ROB_commit_sgn,
    input  wire   [`REGID]   ROB_commit_dest,
    input  wire   [31 : 0]   ROB_commit_value,
    input  wire   [`ROBID]   ROB_commit_ROB_name
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

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_val[i] <= 0;
                reg_rdy[i] <= `True;
            end
        end else if (!rdy) begin
            
        end else begin
            if (IS_sgn && IS_rd != 0) begin
                reg_rdy[IS_rd] <= `False;
                reg_ord[IS_rd] <= ROB_name;
            end
            if (ROB_commit_sgn && ROB_commit_dest != 0) begin
                if (!reg_rdy[ROB_commit_dest] && reg_ord[ROB_commit_dest] == ROB_commit_ROB_name) begin
                    reg_rdy[ROB_commit_dest] <= (!IS_sgn || IS_rd != ROB_commit_dest);
                    reg_val[ROB_commit_dest] <= ROB_commit_value;
                end
            end


            // if (IS_sgn && ROB_commit_sgn && IS_rd == ROB_commit_dest && IS_rd != 0) begin
            //     reg_rdy[IS_rd] <= `False;
            //     reg_ord[IS_rd] <= ROB_name;
            //     // reg_val[IS_rd] <= ROB_commit_value;
            // end else begin
            //     if (IS_sgn && IS_rd != 0) begin
            //         reg_rdy[IS_rd] <= `False;
            //         reg_ord[IS_rd] <= ROB_name;
            //     end 
            //     if (ROB_commit_sgn && ROB_commit_dest != 0) begin
            //         if (!reg_rdy[ROB_commit_dest] && reg_ord[ROB_commit_dest] == ROB_commit_ROB_name) begin
            //             reg_rdy[ROB_commit_dest] <= `True;
            //             reg_val[ROB_commit_dest] <= ROB_commit_value;
            //         end
            //     end
            // end
        end
    end

endmodule