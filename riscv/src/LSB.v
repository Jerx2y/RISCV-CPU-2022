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

    // CDBA
    input wire               CDBA_sgn,
    input wire    [31 : 0]   CDBA_result,
    input wire    [`ROBID]   CDBA_ROB_name
);

    reg             ready     [`LSBSZ];
    reg  [ 5 : 0]   opcode    [`LSBSZ];
    reg  [`ROBID]   name      [`LSBSZ];
    reg  [31 : 0]   adr_val   [`LSBSZ];
    reg  [31 : 0]   val_val   [`LSBSZ];
    reg             adr_rdy   [`LSBSZ];
    reg             val_rdy   [`LSBSZ];

    reg  [`LSBID]   front, rear;

    assign IS_LSB_name = rear;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            
        end else if (!rdy) begin
            
        end else begin
            if (IS_sgn) begin
                rear <= -(~rear);

                ready[rear]   <= (IS_opcode == `LB || IS_opcode == `LH || IS_opcode == `LW || IS_opcode == `LBU || IS_opcode == `LHU);
                opcode[rear]  <= IS_opcode;
                name[rear]    <= ROB_name;
                adr_val[rear] <= IS_adr_val;
                val_rdy[rear] <= IS_val_rdy;
                adr_val[rear] <= IS_adr_val;
                val_rdy[rear] <= IS_val_rdy;
            end

            if (CDBA_sgn) begin
                for (i = 0; i < `LSBSI; i = i + 1)
                    if (!val_rdy[i] && val_val[i][`ROBID] == CDBA_ROB_name) begin
                        val_rdy[i] <= `True;
                        val_val[i] <= CDBA_result;
                    end
            end
        end
    end

endmodule