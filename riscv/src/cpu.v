// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"

module cpu(
    input  wire                 clk_in,         // system clock signal
    input  wire                 rst_in,         // reset signal
    input  wire                 rdy_in,         // ready signal, pause cpu when low
  
    input  wire [ 7:0]          mem_din,        // data input bus
    output wire [ 7:0]          mem_dout,       // data output bus
    output wire [31:0]          mem_a,          // address bus (only 17:0 is used)
    output wire                 mem_wr,         // write/read signal (1 for write)
    
    input  wire                 io_buffer_full, // 1 if uart buffer is full
    
    output wire [31:0]          dbgreg_dout     // cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire          MC_IC_ins_sgn_out;
wire [31 : 0] MC_IC_ins_val;
wire          MC_DC_dat_sgn_out;
wire [31 : 0] MC_DC_dat_val_out;

wire          IC_MC_addr_sgn;
wire [31 : 0] IC_MC_addr;
wire          IC_IF_val_sgn;
wire [31 : 0] IC_IF_val;

wire          IF_IC_pc_sgn;
wire [31 : 0] IF_IC_pc;
wire          IF_IS_ins_sgn;
wire [31 : 0] IF_IS_ins;
wire          IF_IS_jump_flag;
wire [31 : 0] IF_IS_jump_pc;

wire          IS_ROB_sgn;
wire          IS_ROB_ready;
wire [ 5 : 0] IS_ROB_opcode;
wire [31 : 0] IS_ROB_value;
wire [ 4 : 0] IS_ROB_dest;
wire          IS_ROB_jumped;
wire [31 : 0] IS_ROB_jumpto;
wire          IS_RS_sgn;
wire [ 5 : 0] IS_RS_opcode;
wire [31 : 0] IS_RS_rs1_val;
wire [31 : 0] IS_RS_rs2_val;
wire          IS_RS_rs1_rdy;
wire          IS_RS_rs2_rdy;
wire          IS_LSB_sgn;
wire [ 5 : 0] IS_LSB_opcode;
wire [31 : 0] IS_LSB_adr_val;
wire [31 : 0] IS_LSB_val_val;
wire          IS_LSB_adr_rdy;
wire          IS_LSB_val_rdy;
wire [ 4 : 0] IS_REG_rs1;
wire [ 4 : 0] IS_REG_rs2;
wire          IS_REG_sgn;
wire [ 4 : 0] IS_REG_rd;

wire          ROB_IF_jp_wrong;
wire [31 : 0] ROB_IF_jp_tar;
wire          ROB_IF_ROB_full;
wire          ROB_IF_jump_sgn;
wire          ROB_IF_need_jump;
wire [`ROBID] ROB_IS_ROB_name;
wire          ROB_IS_ROB_full;
wire [`ROBID] ROB_RS_ROB_name;
wire [`ROBID] ROB_LSB_ROB_name;
wire          ROB_LSB_commit_sgn;
wire [`LSBID] ROB_LSB_commit_dest;
wire [31 : 0] ROB_LSB_commit_value;
wire [`ROBID] ROB_REG_ROB_name;
wire          ROB_REG_rdy1;
wire          ROB_REG_rdy2;
wire [31 : 0] ROB_REG_val1;
wire [31 : 0] ROB_REG_val2;
wire          ROB_REG_commit_sgn;
wire [`REGID] ROB_REG_commit_dest;
wire [31 : 0] ROB_REG_commit_value;
wire [`ROBID] ROB_REG_commit_ROB_name;
wire          jp_wrong;

wire          RS_IS_RS_full;
wire          RS_ALU_sgn;
wire [ 5 : 0] RS_ALU_opcode;
wire [`ROBID] RS_ALU_name;
wire [31 : 0] RS_ALU_lhs;
wire [31 : 0] RS_ALU_rhs;

wire          ALU_IF_sgn;
wire [31 : 0] ALU_IF_pc;
wire          ALU_LSB_sgn;
wire [31 : 0] ALU_LSB_result;
wire [`ROBID] ALU_LSB_ROB_name;
wire          CDBA_sgn;
wire [31 : 0] CDBA_result;
wire [`ROBID] CDBA_ROB_name;

wire          LSB_IF_LSB_full;
wire [`LSBID] LSB_IS_LSB_name;
wire          LSB_DC_sgn;
wire [31 : 0] LSB_DC_addr;
wire [31 : 0] LSB_DC_val;
wire [ 5 : 0] LSB_DC_opcode;

wire           DC_LSB_sgn_out;
wire           DC_MEM_sgn_out;
wire [31 : 0]  DC_MEM_addr;
wire [31 : 0]  DC_MEM_val_out;
wire [ 5 : 0]  DC_MEM_opcode;
wire           CDBD_sgn;
wire [31 : 0]  CDBD_result;
wire [`ROBID]  CDBD_ROB_name;

wire [31 : 0] REG_IS_rs1_val;
wire [31 : 0] REG_IS_rs2_val;
wire          REG_IS_rs1_rdy;
wire          REG_IS_rs2_rdy;
wire [`ROBID] REG_ROB_ord1;
wire [`ROBID] REG_ROB_ord2;

MCtrl mctrl(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  
    // ICache
    .ins_sgn_in(IC_MC_addr_sgn),
    .ins_addr(IC_MC_addr),
    .ins_sgn_out(MC_IC_ins_sgn_out),
    .ins_val(MC_IC_ins_val),
  
    // DCache
    .dat_sgn_in(DC_MEM_sgn_out),
    .dat_addr(DC_MEM_addr),
    .dat_val_in(DC_MEM_val_out),
    .dat_opcode(DC_MEM_opcode),
    .dat_sgn_out(MC_DC_dat_sgn_out),
    .dat_val_out(MC_DC_dat_val_out),
  
    // RAM
    .mem_din(mem_din),
    .mem_dout(mem_dout),
    .mem_a(mem_a),
    .mem_rw(mem_wr),
    .io_buffer_full(io_buffer_full)
);

ICache icache(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // MCtrl
    .MC_val_sgn(MC_IC_ins_sgn_out),
    .MC_val(MC_IC_ins_val),
    .MC_addr_sgn(IC_MC_addr_sgn),
    .MC_addr(IC_MC_addr),

    // IFetcher
    .IF_addr_sgn(IF_IC_pc_sgn),
    .IF_addr(IF_IC_pc),
    .IF_val_sgn(IC_IF_val_sgn),
    .IF_val(IC_IF_val)
);

IFetcher ifetcher(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // ICache
    .IC_ins_sgn(IC_IF_val_sgn),
    .IC_ins(IC_IF_val),
    .IC_pc_sgn(IF_IC_pc_sgn),
    .IC_pc(IF_IC_pc),

    // Issue
    .IS_ins_sgn(IF_IS_ins_sgn),
    .IS_ins(IF_IS_ins),
    .IS_jump_flag(IF_IS_jump_flag),
    .IS_jump_pc(IF_IS_jump_pc),

    // ALU
    .ALU_sgn(ALU_IF_sgn),
    .ALU_pc(ALU_IF_pc),

    // ROB
    .ROB_jp_wrong(ROB_IF_jp_wrong),
    .ROB_jp_tar(ROB_IF_jp_tar),
    .ROB_full(ROB_IF_ROB_full),
    .ROB_jump_sgn(ROB_IF_jump_sgn),
    .ROB_need_jump(ROB_IF_need_jump),

    // LSB
    .LSB_full(LSB_IF_LSB_full)
);

Issue issue(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // IFetcher
    .IF_ins_sgn(IF_IS_ins_sgn),
    .IF_ins(IF_IS_ins),
    .IF_jump_flag(IF_IS_jump_flag),
    .IF_jump_pc(IF_IS_jump_pc),

    // ROB
    .ROB_name(ROB_IS_ROB_name),
    .ROB_full(ROB_IS_ROB_full),
    .ROB_sgn(IS_ROB_sgn),
    .ROB_ready(IS_ROB_ready),
    .ROB_opcode(IS_ROB_opcode),
    .ROB_value(IS_ROB_value),
    .ROB_dest(IS_ROB_dest),
    .ROB_jumped(IS_ROB_jumped),
    .ROB_jumpto(IS_ROB_jumpto),

    // RS
    .RS_full(RS_IS_RS_full),
    .RS_sgn(IS_RS_sgn),
    .RS_opcode(IS_RS_opcode),
    .RS_rs1_val(IS_RS_rs1_val),
    .RS_rs2_val(IS_RS_rs2_val),
    .RS_rs1_rdy(IS_RS_rs1_rdy),
    .RS_rs2_rdy(IS_RS_rs2_rdy),

    // LSB
    .LSB_name(LSB_IS_LSB_name),
    .LSB_sgn(IS_LSB_sgn),
    .LSB_opcode(IS_LSB_opcode),
    .LSB_adr_val(IS_LSB_adr_val),
    .LSB_val_val(IS_LSB_val_val),
    .LSB_adr_rdy(IS_LSB_adr_rdy),
    .LSB_val_rdy(IS_LSB_val_rdy),

    // REG
    .REG_rs1_val(REG_IS_rs1_val),
    .REG_rs2_val(REG_IS_rs2_val),
    .REG_rs1_rdy(REG_IS_rs1_rdy),
    .REG_rs2_rdy(REG_IS_rs2_rdy),
    .REG_rs1(IS_REG_rs1),
    .REG_rs2(IS_REG_rs2),
    .REG_sgn(IS_REG_sgn),
    .REG_rd(IS_REG_rd),
    
    // CDBA
    .CDBA_sgn(CDBA_sgn),
    .CDBA_result(CDBA_result),
    .CDBA_ROB_name(CDBA_ROB_name),

    // CDBD
    .CDBD_sgn(CDBD_sgn),
    .CDBD_result(CDBD_result),
    .CDBD_ROB_name(CDBD_ROB_name)
);

ROB rob(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // IFetcher
    .IF_ROB_full(ROB_IF_ROB_full),
    .IF_jp_wrong(ROB_IF_jp_wrong),
    .IF_jp_tar(ROB_IF_jp_tar),
    .IF_jump_sgn(ROB_IF_jump_sgn),
    .IF_need_jump(ROB_IF_need_jump),

    // Issue
    .IS_sgn(IS_ROB_sgn),
    .IS_ready(IS_ROB_ready),
    .IS_opcode(IS_ROB_opcode),
    .IS_value(IS_ROB_value),
    .IS_dest(IS_ROB_dest),
    .IS_jumped(IS_ROB_jumped),
    .IS_jumpto(IS_ROB_jumpto),
    .IS_ROB_name(ROB_IS_ROB_name),
    .IS_ROB_full(ROB_IS_ROB_full),

    // RS
    .RS_ROB_name(ROB_RS_ROB_name),

    // LSB
    .LSB_ROB_name(ROB_LSB_ROB_name),
    .LSB_commit_sgn(ROB_LSB_commit_sgn),
    .LSB_commit_dest(ROB_LSB_commit_dest),
    .LSB_commit_value(ROB_LSB_commit_value),

    // REG
    .REG_ord1(REG_ROB_ord1),
    .REG_ord2(REG_ROB_ord2),
    .REG_ROB_name(ROB_REG_ROB_name),
    .REG_rdy1(ROB_REG_rdy1),
    .REG_rdy2(ROB_REG_rdy2),
    .REG_val1(ROB_REG_val1),
    .REG_val2(ROB_REG_val2),

    .REG_commit_sgn(ROB_REG_commit_sgn),
    .REG_commit_dest(ROB_REG_commit_dest),
    .REG_commit_value(ROB_REG_commit_value),
    .REG_commit_ROB_name(ROB_REG_commit_ROB_name),

    // CDBA
    .CDBA_sgn(CDBA_sgn),
    .CDBA_result(CDBA_result),
    .CDBA_ROB_name(CDBA_ROB_name),

    // CDBD
    .CDBD_sgn(CDBD_sgn),
    .CDBD_result(CDBD_result),
    .CDBD_ROB_name(CDBD_ROB_name),

    // jp_wrong
    .jp_wrong(jp_wrong)
);

RS rs(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // Issue
    .IS_sgn(IS_RS_sgn),
    .IS_opcode(IS_RS_opcode),
    .IS_rs1_val(IS_RS_rs1_val),
    .IS_rs2_val(IS_RS_rs2_val),
    .IS_rs1_rdy(IS_RS_rs1_rdy),
    .IS_rs2_rdy(IS_RS_rs2_rdy),
    .IS_RS_full(RS_IS_RS_full),

    // ROB
    .ROB_name(ROB_RS_ROB_name),

    // ALU
    .ALU_sgn(RS_ALU_sgn),
    .ALU_opcode(RS_ALU_opcode),
    .ALU_name(RS_ALU_name),
    .ALU_lhs(RS_ALU_lhs),
    .ALU_rhs(RS_ALU_rhs),

    // CDBA
    .CDBA_sgn(CDBA_sgn),
    .CDBA_result(CDBA_result),
    .CDBA_ROB_name(CDBA_ROB_name),

    // CDBD
    .CDBD_sgn(CDBD_sgn),
    .CDBD_result(CDBD_result),
    .CDBD_ROB_name(CDBD_ROB_name),

    // jp_wrong
    .jp_wrong(jp_wrong)
);

ALU alu(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // RS
    .RS_sgn(RS_ALU_sgn),
    .RS_opcode(RS_ALU_opcode),
    .RS_ROB_name(RS_ALU_name),
    .RS_lhs(RS_ALU_lhs),
    .RS_rhs(RS_ALU_rhs),

    // IF
    .IF_sgn(ALU_IF_sgn),
    .IF_pc(ALU_IF_pc),

    // LSB
    .LSB_sgn(ALU_LSB_sgn),
    .LSB_result(ALU_LSB_result),
    .LSB_ROB_name(ALU_LSB_ROB_name),

    // CDB
    .CDB_sgn(CDBA_sgn),
    .CDB_result(CDBA_result),
    .CDB_ROB_name(CDBA_ROB_name)
);

LSB lsb(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // IF
    .IF_LSB_full(LSB_IF_LSB_full),

    // ISSUE
    .IS_sgn(IS_LSB_sgn),
    .IS_opcode(IS_LSB_opcode),
    .IS_adr_val(IS_LSB_adr_val),
    .IS_val_val(IS_LSB_val_val),
    .IS_adr_rdy(IS_LSB_adr_rdy),
    .IS_val_rdy(IS_LSB_val_rdy),
    .IS_LSB_name(LSB_IS_LSB_name),

    // ROB
    .ROB_name(ROB_LSB_ROB_name),
    .ROB_commit_sgn(ROB_LSB_commit_sgn),
    .ROB_commit_dest(ROB_LSB_commit_dest),
    .ROB_commit_value(ROB_LSB_commit_value),

    // DCache
    .DC_sgn_in(DC_LSB_sgn_out),
    .DC_sgn(LSB_DC_sgn),
    .DC_addr(LSB_DC_addr),
    .DC_val(LSB_DC_val),
    .DC_opcode(LSB_DC_opcode),

    // CDBA
    .CDBA_sgn(CDBA_sgn),
    .CDBA_result(CDBA_result),
    .CDBA_ROB_name(CDBA_ROB_name),

    // CDBD
    .CDBD_sgn(CDBD_sgn),
    .CDBD_result(CDBD_result),
    .CDBD_ROB_name(CDBD_ROB_name),

    // ALU
    .ALU_sgn(ALU_LSB_sgn),
    .ALU_result(ALU_LSB_result),
    .ALU_ROB_name(ALU_LSB_ROB_name),

    // jp_wrong
    .jp_wrong(jp_wrong)
);

DCache dcache(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // LSB
    .LSB_sgn_in(LSB_DC_sgn),
    .LSB_addr(LSB_DC_addr),
    .LSB_val_in(LSB_DC_val),
    .LSB_opcode(LSB_DC_opcode),
    .LSB_sgn_out(DC_LSB_sgn_out),

    // MC
    .MEM_sgn_in(MC_DC_dat_sgn_out),
    .MEM_val_in(MC_DC_dat_val_out),
    .MEM_sgn_out(DC_MEM_sgn_out),
    .MEM_addr(DC_MEM_addr),
    .MEM_val_out(DC_MEM_val_out),
    .MEM_opcode(DC_MEM_opcode),

    // CDBD
    .CDBD_sgn(CDBD_sgn),
    .CDBD_result(CDBD_result),
    .CDBD_ROB_name(CDBD_ROB_name)
);

REG Reg(
    .clk(clk_in), .rst(rst_in), .rdy(rdy_in),

    // ISSUE
    .IS_rs1(IS_REG_rs1),
    .IS_rs2(IS_REG_rs2),
    .IS_sgn(IS_REG_sgn),
    .IS_rd(IS_REG_rd),
    .IS_rs1_val(REG_IS_rs1_val),
    .IS_rs2_val(REG_IS_rs2_val),
    .IS_rs1_rdy(REG_IS_rs1_rdy),
    .IS_rs2_rdy(REG_IS_rs2_rdy),

    // ROB
    .ROB_name(ROB_REG_ROB_name),
    .ROB_rdy1(ROB_REG_rdy1),
    .ROB_rdy2(ROB_REG_rdy2),
    .ROB_val1(ROB_REG_val1),
    .ROB_val2(ROB_REG_val2),
    .ROB_ord1(REG_ROB_ord1),
    .ROB_ord2(REG_ROB_ord2),
    .ROB_commit_sgn(ROB_REG_commit_sgn),
    .ROB_commit_dest(ROB_REG_commit_dest),
    .ROB_commit_value(ROB_REG_commit_value),
    .ROB_commit_ROB_name(ROB_REG_commit_ROB_name)
);

endmodule