`include "defines.v"

module LSB (
    input wire             clk, rst, rdy,

    // ISSUE
    input wire             IS_sgn,
    input wire  [ 5 : 0]   IS_opcode,
    input wire  [31 : 0]   IS_adr_val,
    input wire  [31 : 0]   IS_val_val,
    input wire             IS_adr_rdy,
    input wire             IS_val_rdy,
    output wire            IS_LSB_full,
    output wire [`LSBID]   IS_LSB_name,

    // ROB
    input wire  [`ROBID]   ROB_name,
    input wire             ROB_commit_sgn,
    input wire  [`LSBID]   ROB_commit_dest,
    input wire  [31 : 0]   ROB_commit_value,

    // DCache
    input wire             DC_sgn_in,
    output reg             DC_sgn,
    output wire [31 : 0]   DC_addr,
    output wire [31 : 0]   DC_val,
    output wire [ 5 : 0]   DC_opcode,

    // CDBA
    input wire             CDBA_sgn,
    input wire  [31 : 0]   CDBA_result,
    input wire  [`ROBID]   CDBA_ROB_name,

    // CDBD
    input wire             CDBD_sgn,
    input wire  [31 : 0]   CDBD_result,
    input wire  [`ROBID]   CDBD_ROB_name,

    // jp_wrong
    input wire             jp_wrong
);

    reg  [ 5 : 0]   opcode    [`LSBSZ];
    reg  [`ROBID]   name      [`LSBSZ];
    reg  [31 : 0]   adr_val   [`LSBSZ];
    reg  [31 : 0]   val_val   [`LSBSZ];
    reg             adr_rdy   [`LSBSZ];
    reg             val_rdy   [`LSBSZ];

    reg  [`LSBID]   front, rear;

    assign IS_LSB_name = rear;

    assign DC_addr     = adr_val[front];
    assign DC_val      = val_val[front];
    assign DC_opcode   = opcode[front];

    integer i;

    always @(*) begin
        if (ROB_commit_sgn) begin
            val_rdy[ROB_commit_dest] = `True;
            val_val[ROB_commit_dest] = ROB_commit_value;
        end
    end

    always @(posedge clk) begin
        if (rst || jp_wrong) begin
            front <= 0;
            rear <= 0;
        end else if (!rdy) begin
            
        end else begin
            if (IS_sgn) begin
                rear <= -(~rear);
                // TODO: 判断 SLB 已满

                opcode[rear]  <= IS_opcode;
                name[rear]    <= ROB_name;
                adr_val[rear] <= IS_adr_val;
                val_rdy[rear] <= IS_val_rdy;
                adr_val[rear] <= IS_adr_val;
                val_rdy[rear] <= IS_val_rdy;
            end

            if (adr_rdy[front] && val_rdy[front]) begin
                DC_sgn <= `True;
                if (DC_sgn_in) begin
                    front <= -(~front);
                    ;
                end else begin
                    ;
                end
            end else begin
                DC_sgn <= `False;
            end

            if (CDBA_sgn) begin
                for (i = 0; i < `LSBSI; i = i + 1) begin
                    if (!val_rdy[i] && val_val[i][`ROBID] == CDBA_ROB_name) begin
                        val_rdy[i] <= `True;
                        val_val[i] <= CDBA_result;
                    end
                    if (!adr_rdy[i] && adr_val[i][`ROBID] == CDBA_ROB_name) begin
                        adr_rdy[i] <= `True;
                        adr_val[i] <= CDBA_result;
                    end
                end
            end

            if (CDBD_sgn) begin
                for (i = 0; i < `LSBSI; i = i + 1)
                    if (!val_rdy[i] && val_val[i][`ROBID] == CDBD_ROB_name) begin
                        val_rdy[i] <= `True;
                        val_val[i] <= CDBD_result;
                    end
            end

        end
    end

endmodule