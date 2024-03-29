`include "defines.v"

// 当前问题：ALU算出来给 LSB 的内容不能被别的地方监听到，应该开辟专线
 
module LSB (
    input wire             clk, rst, rdy,

    // IF
    output wire            IF_LSB_full,

    // ISSUE
    input wire             IS_sgn,
    input wire  [ 5 : 0]   IS_opcode,
    input wire  [31 : 0]   IS_adr_val,
    input wire  [31 : 0]   IS_val_val,
    input wire             IS_adr_rdy,
    input wire             IS_val_rdy,
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

    // ALU
    input wire             ALU_sgn,
    input wire  [31 : 0]   ALU_result,
    input wire  [`ROBID]   ALU_ROB_name,

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
    reg             full;

    assign IS_LSB_name = rear;

    assign DC_addr     = adr_val[front];
    assign DC_val      = val_val[front];
    assign DC_opcode   = opcode[front];

    assign IF_LSB_full = DC_sgn_in ? (full && IS_sgn) : (full || (IS_sgn && (front == -(~rear))));

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            front <= 0;
            rear <= 0;
            for (i = 0; i < `LSBSI; i = i + 1) begin
                val_rdy[i] <= 0;
                adr_rdy[i] <= 0;
            end
            full <= `False;
        end else if (!rdy) begin
            
        end else begin
            full <= DC_sgn_in ? (full && IS_sgn) : (full || (IS_sgn && (front == -(~rear))));

            if (IS_sgn) begin
                rear <= -(~rear);
                // TODO: 判断 SLB 已满

                opcode[rear]  <= IS_opcode;
                name[rear]    <= ROB_name;
                adr_rdy[rear] <= IS_adr_rdy;
                adr_val[rear] <= IS_adr_val;
                val_rdy[rear] <= IS_val_rdy;
                val_val[rear] <= IS_val_val;

            end

            // commit
            // $display(front, " ", adr_rdy[front], " ", val_rdy[front]);
            if ((full || rear != front) && (adr_rdy[front] && val_rdy[front])) begin
                // $display(front, "#", DC_sgn_in, "@", DC_addr);


                if (DC_sgn_in) begin // TODO: 需要 DC_sgn_in 及时变回去 
                //    if (opcode[front] == `SB && adr_val[front] == 196608)
                //        $display("@", val_val[front],"@");

                //    if (opcode[front] == `SB && adr_val[front] == 196608)
                //        $display("ok");

                    front <= -(~front);
                    DC_sgn <= `False;
                end else begin
                    DC_sgn <= `True;
                end
            end else begin
                DC_sgn <= `False;
            end

            if (ALU_sgn) begin
                for (i = 0; i < `LSBSI; i = i + 1)
                    if (!adr_rdy[i] && adr_val[i][`ROBID] == ALU_ROB_name) begin
                        adr_rdy[i] <= `True;
                        adr_val[i] <= ALU_result;
                    end
            end

            if (ROB_commit_sgn) begin
                val_rdy[ROB_commit_dest] <= `True;
                val_val[ROB_commit_dest] <= ROB_commit_value;
                // if (opcode[ROB_commit_dest] == `SB && adr_val[ROB_commit_dest] == 196608)
                //     $display("#", val_val[ROB_commit_dest]);
            end
            // if (CDBA_sgn) begin
            //     for (i = 0; i < `LSBSI; i = i + 1) begin
            //         // if (!val_rdy[i] && val_val[i][`ROBID] == CDBA_ROB_name) begin
            //         //     val_rdy[i] <= `True;
            //         //     val_val[i] <= CDBA_result;
            //         // end
            //         if (!adr_rdy[i] && adr_val[i][`ROBID] == CDBA_ROB_name) begin
            //             adr_rdy[i] <= `True;
            //             adr_val[i] <= CDBA_result;
            //         end
            //     end
            // end

            // if (CDBD_sgn) begin
            //     for (i = 0; i < `LSBSI; i = i + 1)
            //         if (!val_rdy[i] && val_val[i][`ROBID] == CDBD_ROB_name) begin
            //             val_rdy[i] <= `True;
            //             val_val[i] <= CDBD_result;
            //         end
            // end

        end
    end

endmodule