`include "defines.v"

module DCache (
    input clk, rst, rdy,

    // LSB
    input wire            LSB_sgn_in,
    input wire  [31 : 0]  LSB_addr,
    input wire  [31 : 0]  LSB_val_in,
    input wire  [ 5 : 0]  LSB_opcode,
    output wire           LSB_sgn_out,

    // MEM
    input wire            MEM_sgn_in,
    input wire  [31 : 0]  MEM_val_in,
    output wire           MEM_sgn_out,
    output wire [31 : 0]  MEM_addr,
    output wire [31 : 0]  MEM_val_out,
    output wire [ 5 : 0]  MEM_opcode,

    // CDBD
    output reg            CDBD_sgn,
    output reg  [31 : 0]  CDBD_result,
    output reg  [`ROBID]  CDBD_ROB_name
);

    assign MEM_sgn_out = LSB_sgn_in;
    assign MEM_addr    = LSB_addr;
    assign MEM_val_out = LSB_val_in;
    assign MEM_opcode  = LSB_opcode;
    
    assign LSB_sgn_out = MEM_sgn_in;

    always @(*) begin
        if (MEM_sgn_in && LSB_opcode != `SB && LSB_opcode != `SH && LSB_opcode != `SW) begin
            CDBD_sgn = `True;
            CDBD_result = MEM_val_in;
            CDBD_ROB_name = LSB_val_in[`ROBID];
        end else begin
            CDBD_sgn = `False;
        end
    end

endmodule