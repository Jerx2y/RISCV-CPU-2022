`include "defines.v"

module MCtrl (
    input wire clk, rst, rdy,

    // ICache
    input wire          ins_sgn_in,
    input wire [31 : 0] ins_addr,
    output reg          ins_sgn_out,
    output reg [31 : 0] ins_val,

    // DCache
    input wire          dat_sgn_in,
    input wire [31 : 0] dat_addr,
    input wire [31 : 0] dat_val_in,
    input wire [ 5 : 0] dat_opcode,
    output reg          dat_sgn_out,
    output reg [31 : 0] dat_val_out,

    // RAM
    input wire [ 7 : 0] mem_din,
    output reg [ 7 : 0] mem_dout,
    output reg [31 : 0] mem_a,
    output reg          mem_rw, // 0 for read, 1 for write
    input wire          io_buffer_full
);

    reg ins_now, dat_now;
    reg [ 1 : 0] ins_offset;
    reg [31 : 0] ins_tmp;
    reg [ 1 : 0] dat_offset;
    reg [31 : 0] dat_tmp;

    always @(*) begin
        if (rst) begin
            
        end else if (!rdy) begin
            mem_a = 0;
            mem_dout = 0;
            mem_rw = 0;
        end else begin
            if (ins_sgn_in) begin
                mem_a = ins_addr + ins_offset;
                mem_dout = 0;
                mem_rw = 0;
            end else if (dat_sgn_in) begin
                mem_a = dat_addr + dat_offset;
                case (dat_opcode)
                    `LB, `LH, `LW, `LBU, `LHU: begin
                        mem_dout = 0;
                        mem_rw = 0;
                    end
                    `SB, `SH, `SW: begin
                        case (dat_offset)
                            2'b00: mem_dout = dat_val_in[ 7 :  0];
                            2'b01: mem_dout = dat_val_in[15 :  8];
                            2'b10: mem_dout = dat_val_in[23 : 16];
                            2'b11: mem_dout = dat_val_in[31 : 24];
                        endcase
                        mem_rw = 1;
                    end
                endcase
            end
        end
    end

    always @(*) begin
        ins_val = {mem_din, ins_tmp[23 : 0]};
        case (dat_opcode)
            `LB:     dat_val_out         = {{24{mem_din[7]}}, mem_din};
            `LBU:    dat_val_out[ 7 : 0] = mem_din;
            `LH:     dat_val_out         = {{16{mem_din[7]}}, mem_din, dat_tmp[7 : 0]};
            `LHU:    dat_val_out[15 : 0] = {mem_din, dat_tmp[7 : 0]};
            `LW:     dat_val_out         = {mem_din, dat_tmp[23 : 0]};
            default: dat_val_out         = 0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            dat_sgn_out <= `False;
            ins_sgn_out <= `False;
            dat_now     <= `False;
            ins_now     <= `False;
            ins_offset  <= 0;
            dat_offset  <= 0;
        end else if (!rdy) begin
            
        end else begin
            if (ins_now) begin
                dat_sgn_out <= `False;
                ins_sgn_out <= (ins_offset == 2'b11);
                ins_now <= (ins_offset != 2'b11);
                ins_offset <= -(~ins_offset);
                case (ins_offset)
                    2'b01: ins_tmp[ 7 :  0] <= mem_din;
                    2'b10: ins_tmp[15 :  8] <= mem_din;
                    2'b11: ins_tmp[23 : 16] <= mem_din;
                endcase
            end else if (dat_now) begin
                ins_sgn_out <= `False;
                case (dat_opcode)
                    `LH, `LHU: begin
                        dat_offset <= 0;
                        dat_now <= `False;
                        dat_sgn_out <= `True;
                        dat_tmp[7 : 0] <= mem_din;
                    end
                    `LW: begin
                        dat_sgn_out <= (dat_offset == 2'b11);
                        dat_now <= (dat_offset != 2'b11);
                        dat_offset <= -(~dat_offset);
                        case (dat_offset)
                            2'b01: dat_tmp[ 7 :  0] <= mem_din;
                            2'b10: dat_tmp[15 :  8] <= mem_din;
                            2'b11: dat_tmp[23 : 16] <= mem_din;
                        endcase
                    end
                    `SH: begin
                        dat_offset <= 0;
                        dat_now <= `False;
                        dat_sgn_out <= `False;
                    end
                    `SW: begin
                        dat_sgn_out <= `False;
                        dat_now <= (dat_offset != 2'b11);
                        dat_offset <= -(~dat_offset);
                    end
                endcase

            end else if (ins_sgn_in) begin
                dat_sgn_out <= `False;
                ins_sgn_out <= `False;
                ins_offset <= -(~ins_offset);
                ins_now <= `True;
            end else if (dat_sgn_in) begin
                ins_sgn_out <= `False;
                case (dat_opcode)
                    `LB, `LBU: dat_sgn_out <= `True;
                    `LH, `LHU, `LW: begin
                        dat_sgn_out <= `False;
                        dat_now     <= `True;
                        dat_offset  <= -(~dat_offset);
                    end
                    `SH, `SW: begin
                        dat_sgn_out <= `False;
                        dat_now     <= `True;
                        dat_offset  <= -(~dat_offset);
                    end
                endcase
            end else begin
                ins_sgn_out <= `False;
                dat_sgn_out <= `False;
            end
        end
    end

endmodule