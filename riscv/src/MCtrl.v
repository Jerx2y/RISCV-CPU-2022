`include "defines.v"

module MCtrl (
    input wire clk, rst, rdy,

    // ICache
    input wire          ins_sgn_in,
    input wire [31 : 0] ins_addr,
    output reg          ins_sgn_out,
    output reg [31 : 0] ins_val,

    // DCache
    // TODO

    // RAM
    input wire [ 7 : 0] mem_din,
    output reg [ 7 : 0] mem_dout,
    output reg [31 : 0] mem_a,
    output reg          mem_rw, // 0 for read, 1 for write
    input wire          io_buffer_full
);

    reg [1 : 0] ins_offset;
    reg [31 : 0] ins_tmp;

    always @(*) begin
        if (rdy) begin
            if (ins_sgn_in) begin
                mem_a = ins_addr + ins_offset;
                mem_dout = 0;
                mem_rw = 0;
            end
        end else begin
            mem_a = 0;
            mem_dout = 0;
            mem_rw = 0;
        end

        ins_val = {mem_din, ins_tmp[23 : 0]};
    end

    always @(posedge clk) begin
        if (rdy) begin
            if (ins_sgn_in) begin
                ins_sgn_out <= (ins_offset == 2'b11);
                ins_offset <= -(~ins_offset);
            end

            case (ins_offset)
                2'b01: ins_tmp[ 7 :  0] = mem_din;
                2'b10: ins_tmp[15 :  8] = mem_din;
                2'b11: ins_tmp[23 : 16] = mem_din;
            endcase
        end
    end

endmodule