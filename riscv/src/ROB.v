`include "defines.v"

module ROB (
    input wire clk, rst, rdy,

    // IFetcher
    output wire             IF_jp_wrong,
    output reg   [31 : 0]   IF_jp_tar,
    output wire             IF_ROB_full,

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
    output reg   [`LSBID]   LSB_commit_dest,
    output reg   [31 : 0]   LSB_commit_value,

    // REG
    input  wire  [`ROBID]   REG_ord1,
    input  wire  [`ROBID]   REG_ord2,
    output wire  [`ROBID]   REG_ROB_name,
    output wire             REG_rdy1,
    output wire             REG_rdy2,
    output wire  [31 : 0]   REG_val1,
    output wire  [31 : 0]   REG_val2,

    output reg              REG_commit_sgn,
    output reg  [`REGID]    REG_commit_dest,
    output reg  [31 : 0]    REG_commit_value,
    output reg  [`ROBID]    REG_commit_ROB_name,

    // CDBA
    input wire              CDBA_sgn,
    input wire   [31 : 0]   CDBA_result,
    input wire   [`ROBID]   CDBA_ROB_name,

    // CDBD
    input wire              CDBD_sgn,
    input wire   [31 : 0]   CDBD_result,
    input wire   [`ROBID]   CDBD_ROB_name,

    // jp_wrong
    output reg              jp_wrong
);

    reg [`ROBSZ]    ready;
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

    assign IF_jp_wrong  = jp_wrong;
    assign IF_ROB_full  = (front == (-(~rear)));

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            front <= 0;
            rear  <= 0;
            ready <= 0;
        end else if (!rdy) begin

        end else begin

            if (IS_sgn) begin
                rear <= -(~rear);

                // $display("#", IS_ready, " ", IS_opcode, " ", rear, " ##", ready[6]);

                ready[rear] <= IS_ready;
                value[rear] <= IS_value;
                dest[rear] <= IS_dest;
                opcode[rear] <= IS_opcode;
                
            end
        
            // CDB of ALU
            if (CDBA_sgn) begin
                if (opcode[CDBA_ROB_name] != `LTYPE && opcode[CDBA_ROB_name] != `STYPE) begin // without l/s instruction
                    ready[CDBA_ROB_name] <= `True;
                    value[CDBA_ROB_name] <= CDBA_result;
                end
                for (i = 0; i < `ROBSI; i = i + 1) begin
                    if (opcode[i] == `STYPE && !ready[i] && value[i][3 : 0] == CDBA_ROB_name) begin
                        ready[i] <= `True;
                        value[i] <= CDBA_result;
                    end
                end
            end

            // CDB of DCache
            if (CDBD_sgn) begin
                ready[CDBD_ROB_name] <= `True;
                value[CDBD_ROB_name] <= CDBD_result;
                for (i = 0; i < `ROBSI; i = i + 1) begin
                    if (opcode[i] == `STYPE && !ready[i] && value[i][3 : 0] == CDBD_ROB_name) begin
                        ready[i] <= `True;
                        value[i] <= CDBD_result;
                    end
                end
            end

            // commit
            // $display(front, " ", rear, " @ ", opcode[front], " ", dest[front]);
            if (front != rear && ready[front]) begin
                // ready[front] <= `False;
                front <= -(~front);

                REG_commit_dest     <= dest[front];
                REG_commit_value    <= value[front];
                REG_commit_ROB_name <= front;
                LSB_commit_dest     <= dest[front][`LSBID];
                LSB_commit_value    <= value[front];

                case (opcode[front])
                    `LUI: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                    `AUIPC: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                    `JAL: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                    `JALR: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                    `BTYPE: begin
                        jp_wrong <= jumped[front] != value[front][0];
                        REG_commit_sgn <= `False;
                        LSB_commit_sgn <= `False;
                        IF_jp_tar <= jumpto[front];
                    end
                    `LTYPE: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                    `STYPE: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `False;
                        LSB_commit_sgn <= `True;
                    end
                    `ITYPE: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                    `RTYPE: begin
                        jp_wrong <= `False;
                        REG_commit_sgn <= `True;
                        LSB_commit_sgn <= `False;
                    end
                endcase
            end else begin
                jp_wrong <= `False;
                REG_commit_sgn <= `False;
                LSB_commit_sgn <= `False;
            end
    
        end
    end
    
endmodule