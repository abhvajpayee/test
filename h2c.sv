`timescale 1ps / 1ps
//
// Stream H2C
//
module ST_h2c #
   ( parameter BIT_WIDTH = 64,
     C_H2C_TUSER_WIDTH = 55,
     parameter PATT_WIDTH = 16
    )
    ( input  axi_aclk,
      input  axi_aresetn,
      input [31:0] control_reg,
      input  control_run,
      input  [31:0] h2c_txr_size,
      input  [BIT_WIDTH-1:0] h2c_tdata,
      input  h2c_tvalid,
      input  h2c_tlast,
      input   [10:0] h2c_tuser_qid /* synthesis syn_keep = 1 */,
      input   [2:0]  h2c_tuser_port_id, 
      input          h2c_tuser_err, 
      input   [31:0] h2c_tuser_mdata, 
      input   [5:0]  h2c_tuser_mty, 
      input          h2c_tuser_zero_byte, 
      input  clr_match,
      output reg h2c_tready,
      output reg [31:0] h2c_count,
      output h2c_match,
      input inbusy,
      output we,
     output [BIT_WIDTH-1:0] din
    );

localparam INC_DATA = (BIT_WIDTH == 64 ) ? 8 : (BIT_WIDTH == 128 ) ? 16 : (BIT_WIDTH == 256 ) ? 32 : 64;   // Total bytes per beat
//Increment pattern every 8bits or 16 bits.
localparam PAT_INC = (PATT_WIDTH == 16) ? ((BIT_WIDTH == 64 ) ? 4 : (BIT_WIDTH == 128 ) ? 8 : (BIT_WIDTH == 256 ) ? 16 : 32)
                                             :((BIT_WIDTH == 64 ) ? 8 : (BIT_WIDTH == 128 ) ? 16 : (BIT_WIDTH == 256 ) ? 32 : 64); // Total bytes per beat
   localparam TCQ = 1;
   
   reg [ PATT_WIDTH-1:0] dat[0:63];

(* mark_debug = "true" *)wire [INC_DATA-1:0] cmp_val;
(* mark_debug = "true" *) reg match;
(* mark_debug = "true" *) reg h2c_fail;
   reg 	     control_run_d1;
   reg 	     h2c_tlast_d1, h2c_tlast_d2;
   wire [INC_DATA-1:0] h2c_tkeep = {INC_DATA{1'b1}};
   reg [15:0] 	       bp_lfsr;
   wire 	       loopback_st;
   wire 	       back_pres;
   wire [5:0] 	       emt_eop = h2c_tuser_mty[5:0];
   wire [5:0] 	       emt_sop = 6'b0;
   wire  	       zero_byte = h2c_tuser_zero_byte;

   // Tuser formate
   // [10:0] Qid
   // [11] wbc
   // [14:12] Port id
   // [15] err
   // [47:16] metadata
   // [53:48] mty
   // [54] zero_byte

   reg [31:0] h2c_count_1;
   reg 	   h2c_tvalid_t1;

assign h2c_tready = inbusy;
assign we = h2c_tvalid & h2c_tready;
assign din = h2c_tdata;
    
assign loopback_st = control_reg[0];
assign back_pres   = control_reg[1];


always @(posedge axi_aclk) begin
    control_run_d1 <= control_run;
    h2c_tlast_d1 <= h2c_tlast;
    h2c_tlast_d2 <= h2c_tlast_d1;
    h2c_tvalid_t1 <= h2c_tvalid;
end
   
    
assign h2c_match = match;

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match | loopback_st)
        match <= 1'b0;
    else
      match <= (h2c_count_1 > 0) ? ~h2c_fail : match;
end

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match | loopback_st)
        h2c_fail <= 1'b0;
    else if (h2c_tvalid && h2c_tready && (~&cmp_val) && ~zero_byte)
        h2c_fail <= 1'b1;
end

always @(posedge axi_aclk) begin
   if (~axi_aresetn)
     h2c_count <= 0;
   else if (h2c_tlast_d1)
     h2c_count <= h2c_count_1;
end

always @(posedge axi_aclk) begin
    if (~axi_aresetn | clr_match) begin
        h2c_count_1 <= 0;
        for (integer j=0; j<PAT_INC; j++)
             dat[j] <= #TCQ j;
        end
    else if (h2c_tvalid && h2c_tready) begin
         h2c_count_1 <= h2c_count_1 + 1;
         for (integer j=0; j<PAT_INC; j++)
             dat[j] <= #TCQ dat[j]+PAT_INC;
        end
//    else if (h2c_tvalid && h2c_tready && tkeep_half1 ) begin   // for 512 bits two transfer
//         h2c_count_1 <= h2c_count_1 + 1;
//         for (integer j=0; j<INC_DATA; j++)
//             dat[j] <= #TCQ dat[j]+INC_DATA/2;
//        end
end



   

endmodule
