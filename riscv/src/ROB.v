`include "defines.v"

module ROB (
    input wire clk, rst, rdy,

    // Issue
    input  wire             IS_sgn,
    input  wire             IS_ready,
    input  wire  [ 5 : 0]   IS_opcode,
    input  wire  [31 : 0]   IS_value,
    input  wire  [ 4 : 0]   IS_dest,
    input  wire             IS_jumped,
    input  wire  [31 : 0]   IS_jumpto,
    output wire  [`ROBID]   IS_ROB_name,

    // RS
    output wire  [`ROBID]   RS_ROB_name,

    // LSB
    output wire  [`ROBID]   LSB_ROB_name,
    output reg              LSB_commit_sgn,
    output wire  [`LSBID]   LSB_commit_dest,
    output wire  [31 : 0]   LSB_commit_value,

    // REG
    input  wire  [`ROBID]   REG_ord1,
    input  wire  [`ROBID]   REG_ord2,
    output wire  [`ROBID]   REG_ROB_name,
    output wire             REG_rdy1,
    output wire             REG_rdy2,
    output wire  [31 : 0]   REG_val1,
    output wire  [31 : 0]   REG_val2,

    output reg              REG_commit_sgn,
    output wire  [`REGID]   REG_commit_dest,
    output wire  [31 : 0]   REG_commit_value,
    output wire  [`ROBID]   REG_commit_ROB_name,

    // CDBA
    input wire              CDBA_sgn,
    input wire   [31 : 0]   CDBA_result,
    input wire   [`ROBID]   CDBA_ROB_name,

    // CDBD
    input wire              CDBD_sgn,
    input wire   [31 : 0]   CDBD_result,
    input wire   [`ROBID]   CDBD_ROB_name
);

    reg             ready    [`ROBSZ];
    reg [`REGID]    dest     [`ROBSZ];
    reg [31 : 0]    value    [`ROBSZ];
    reg [ 5 : 0]    opcode   [`ROBSZ];
    reg             jumped   [`ROBSZ];
    reg [31 : 0]    jumpto   [`ROBSZ];

    reg [`ROBID]    front, rear;

    assign RS_ROB_name  = rear;
    assign IS_ROB_name  = rear;
    assign REG_ROB_name = rear;
    assign LSB_ROB_name = rear;

    assign REG_rdy1     = ready[REG_ord1];
    assign REG_val1     = value[REG_ord1];
    assign REG_rdy2     = ready[REG_ord2];
    assign REG_val2     = value[REG_ord2];

    assign REG_commit_dest     = dest[front];
    assign REG_commit_value    = value[front];
    assign REG_commit_ROB_name = front;

    assign LSB_commit_dest  = dest[front][`LSBID];
    assign LSB_commit_value = value[front];
    
    always @(posedge clk) begin
        if (rst) begin
            
        end else if (!rdy) begin

        end else begin
            if (IS_sgn) begin
                rear <= -(~rear);

                ready[rear] <= IS_ready;
                value[rear] <= IS_value;
                dest[rear] <= IS_dest;
                opcode[rear] <= IS_opcode;
                
            end
        
            // CDB of ALU
            if (CDBA_sgn) begin
                if (opcode[CDBA_ROB_name] != `LTYPE) begin // without load instruction
                    ready[CDBA_ROB_name] <= `True;
                    value[CDBA_ROB_name] <= CDBA_result;
                end
            end

            // CDB of DCache
            if (CDBD_sgn) begin
                ready[CDBD_ROB_name] <= `True;
                value[CDBD_ROB_name] <= CDBD_result;
            end

            // commit
            if (ready[front]) begin
                front <= -(~front);
                ready[front] <= `False;

                case (opcode[front])
                    `LUI: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                    `AUIPC: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                    `JAL: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                    `JALR: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                    `BTYPE: begin
                        // TODO;
                    end
                    `LTYPE: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                    `STYPE: begin
                        REG_commit_sgn = `False;
                        LSB_commit_sgn = `True;
                    end
                    `ITYPE: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                    `RTYPE: begin
                        REG_commit_sgn = `True;
                        LSB_commit_sgn = `False;
                    end
                endcase
            end
        end
    end
    
endmodule