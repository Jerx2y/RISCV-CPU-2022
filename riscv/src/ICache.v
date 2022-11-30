// instruction cache
`include "defines.v"

module ICache (
    input wire clk, rst, rdy,

    // MCtrl
    input  wire          MC_val_sgn,
    input  wire [31 : 0] MC_val,
    output wire          MC_addr_sgn,
    output wire [31 : 0] MC_addr,

    // IFetcher
    input wire          IF_addr_sgn,
    input wire [31 : 0] IF_addr,
    output reg          IF_val_sgn,
    output reg [31 : 0] IF_val
);


    reg               valid     [`ICSZ - 1 : 0];
    reg   [31 : 0]    val       [`ICSZ - 1 : 0];
    reg   [`TGID]     tag       [`ICSZ - 1 : 0];
    
    wire [31 : 0] pc = IF_addr;
    wire [`ICID] index = pc[`ICID];
    wire miss = !valid[index] || tag[index] != pc[`TGID];

    assign MC_addr_sgn = miss && !MC_val_sgn;
    assign MC_addr = pc;

    always @(posedge clk) begin
        if (rdy && IF_addr_sgn) begin
            if (valid[index]) begin
                if (!miss) begin
                    IF_val_sgn <= `True;
                    IF_val <= val[index];
                end else begin
                    IF_val_sgn <= MC_val_sgn;
                    IF_val <= MC_val;
                end
            end

            if (MC_val_sgn) begin
                valid[index] <= `True;
                val[index] <= MC_val;
                tag[index] <= pc[`TGID];
            end
        end
    end
    
endmodule