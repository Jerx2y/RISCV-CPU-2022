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
    reg [ 5 : 0] last_opcode;
    wire         is_IO = dat_addr[17:16] == 2'b11;

    always @(*) begin
        if (rst || !rdy) begin
            mem_a = 0;
            mem_rw = 0;
            mem_dout = 0;
        end else begin
            // $display("*", ins_now, " ", dat_now, " ", ins_sgn_in, " ", dat_sgn_in, " ", mem_a);
            if (!ins_now && dat_sgn_in && !dat_sgn_out && !(is_IO && io_buffer_full)) begin
                case (dat_opcode)
                    `LB, `LH, `LW, `LBU, `LHU: begin
                        mem_rw = 0;
                        mem_a = dat_addr + dat_offset;
                    end
                    `SB, `SH, `SW: begin
                        mem_rw = dat_now;
                        if (dat_now)
                            mem_a = dat_addr + dat_offset;
                        else mem_a = 0;
                    end
                    default: begin
                        mem_a = 0;
                        mem_rw = 0;
                    end
                endcase

                case (dat_opcode)
                    `SB, `SH, `SW:
                        case (dat_offset)
                            2'b00: mem_dout = dat_val_in[ 7 :  0];
                            2'b01: mem_dout = dat_val_in[15 :  8];
                            2'b10: mem_dout = dat_val_in[23 : 16];
                            2'b11: mem_dout = dat_val_in[31 : 24];
                        endcase
                    default: mem_dout = 0;
                endcase

            end else if (!dat_now && ins_sgn_in && !dat_sgn_out) begin // 各种原因导致这个地方 ins_sgn_in 为 false 且 dat_sgn_in 为 true，但是下面posedge处两者都为 true，从而这里执行而下面未执行。 
                mem_a = ins_addr + ins_offset;
                mem_rw = 0;
                mem_dout = 0;
            end else begin
                mem_a = 0;
                mem_rw = 0;
                mem_dout = 0;
            end
        end
    end

    always @(*) begin
        ins_val = {mem_din, ins_tmp[23 : 0]};
        case (last_opcode)
            `LB:     dat_val_out = {{24{mem_din[7]}}, mem_din};
            `LBU:    dat_val_out = {{24'b0}, mem_din};
            `LH:     dat_val_out = {{16{mem_din[7]}}, mem_din, dat_tmp[7 : 0]};
            `LHU:    dat_val_out = {{16'b0}, mem_din, dat_tmp[7 : 0]};
            `LW:     dat_val_out = {mem_din, dat_tmp[23 : 0]};
            default: dat_val_out = 0;
        endcase
    end

    reg [31 : 0] debug;

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
            if (dat_now && dat_sgn_in && !(is_IO && io_buffer_full) && !ins_now) begin // 必须先判断 data 
                // $display("#", dat_sgn_in, dat_now, ins_sgn_in, ins_now);
                ins_sgn_out <= `False;
                case (dat_opcode)
                    `LH, `LHU: begin
                        dat_sgn_out <= `True;
                        dat_now <= `False;
                        dat_offset <= 0;
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
                    `SB: begin
                        dat_sgn_out <= `True;
                        dat_now <= `False;
                        dat_offset <= 0;
                    end
                    `SH: begin
                        dat_sgn_out <= (dat_offset == 2'b01);
                        dat_now <= (dat_offset != 2'b01);
                        dat_offset <= (dat_offset ^ 2'b01);
                    end
                    `SW: begin
                        dat_sgn_out <= (dat_offset == 2'b11);
                        dat_now <= (dat_offset != 2'b11);
                        dat_offset <= -(~dat_offset);
                    end
                endcase

            end else if (ins_now && ins_sgn_in && !dat_now) begin
                // $display("$", dat_sgn_in, dat_now, ins_sgn_in, ins_now);
                dat_sgn_out <= `False;
                ins_sgn_out <= (ins_offset == 2'b11);
                ins_now <= (ins_offset != 2'b11);
                ins_offset <= -(~ins_offset);
                case (ins_offset)
                    2'b01: ins_tmp[ 7 :  0] <= mem_din;
                    2'b10: ins_tmp[15 :  8] <= mem_din;
                    2'b11: ins_tmp[23 : 16] <= mem_din;
                endcase
            end else if (dat_sgn_in && !dat_sgn_out && !ins_sgn_out && !(is_IO && io_buffer_full) && !ins_now) begin
                // $display("&", dat_sgn_in, dat_now, ins_sgn_in, ins_now);
                ins_sgn_out <= `False;
                last_opcode <= dat_opcode;

                // if (dat_opcode == `SB && dat_addr == 196608)
                //     $display("@", dat_val_in, "@");

                case (dat_opcode)
                    `LB, `LBU: begin
                        dat_sgn_out <= `True;
                        dat_now <= `False;
                        dat_offset <= 0;
                    end
                    `LH, `LHU, `LW: begin
                        dat_sgn_out <= `False;
                        dat_now     <= `True;
                        dat_offset  <= -(~dat_offset);
                    end
                    `SB, `SH, `SW: begin
                        dat_sgn_out <= `False;
                        dat_now     <= `True;
                        dat_offset <= 0;
                    end
                endcase
            end else if (ins_sgn_in && !dat_sgn_out && !ins_sgn_out && !dat_now) begin
                // $display("%", dat_sgn_in, dat_now, ins_sgn_in, ins_now);
                dat_sgn_out <= `False;
                ins_sgn_out <= `False;
                ins_offset <= -(~ins_offset);
                ins_now <= `True;
            end else begin
                ins_sgn_out <= `False;
                dat_sgn_out <= `False;
                ins_offset <= 2'b00;
                dat_offset <= 2'b00;
                ins_now <= `False;
                dat_now <= `False;
            end
        end
    end

endmodule