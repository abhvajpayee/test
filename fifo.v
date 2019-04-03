`timescale 1ns/10ps

module fifo #(
    parameter ADDR   = 4,
    parameter DATA   = 8,
    parameter OFFSET = 4,
    parameter LOWER  = 1,
    parameter UPPER  = 12)(
    clk,
    inbusy,
    we,
    din,
    outbusy,
    rd,
    dout,
    rdout,
    hfull,
    rst);
    // Half full FIFO model
    // clk  = Clock 
    // inbusy = Input bus is busy
    // we     = Input bus write enable
    // din    = Input bus data input
    // 
    // inclk  = Clock Input for read
    // outbusy= Output bus is busy
    // rd     = Output bus read enable
    // dout   = Output bus data output
    // rdout  = Output bus data can be read
    // hfull  = Buffer half full
    // rst    = Reset
    // ADDR   = Size of Address bus
    // DATA   = Size of Data bus
    // OFFSET = Size of half full mark
    // LOWER  = Size of lower limit for buffer after which buffer can be read
    // UPPER  = Size of upper limit for buffer after which buffer can not be written

    input  wire clk;
    output reg  inbusy;
    input  wire we;
    input  wire [DATA-1:0] din;
    output reg  outbusy;
    input  wire rd;
    output reg  [DATA-1:0] dout;
    output wire rdout;
    output wire hfull;
    input wire  rst;

    reg rdoutt;
    reg noread;
    reg hfullt;
    wire [ADDR:0] diff;
    reg [ADDR:0] b_addr;
    reg [ADDR:0] a_addr;
    reg [DATA-1:0] mem [0:2**ADDR-1];
    wire [DATA-1:0] test;
    
    assign test = mem[0];
    
    initial begin
        a_addr <= 0;
        inbusy <= 0;
        hfullt <= 0;
        dout <= 0;
        rdoutt <= 0;
        b_addr <= 0;
    end

    always @(posedge clk) begin
        if (rst == 1) begin
            a_addr <= 0;
            inbusy <= 0;
        end
        else begin
            if (we) begin
                a_addr <= (a_addr + 1);
            end
            if ((diff >= UPPER)) begin
                inbusy <= 1;
            end
            else begin
                inbusy <= 0;
            end
        end
    end


    always @(posedge clk) begin: WRITE_MEM_LOGIC
        if (we) begin
            mem[a_addr & 2**ADDR-1] <= din;
        end
    end


    always @(posedge clk) begin: READ_PORT
        if (rst == 1) begin
            hfullt <= 0;
            dout <= 0;
            rdoutt <= 0;
            b_addr <= 0;
        end
        else begin
            dout <= mem[b_addr & 2**ADDR-1];
            if ((rd && hfullt && (!noread))) begin
                b_addr <= (b_addr + 9'h1);
                rdoutt <= rd;
            end
            else begin
                rdoutt <= 0;
            end
            if ((diff >= OFFSET)) begin
                hfullt <= 1;
            end
            if ((diff <= LOWER)) begin
                hfullt <= 0;
            end
        end
    end



    assign hfull = hfullt;
    assign rdout = rdoutt;
    assign diff = (a_addr - b_addr);


    always @(diff) begin
        //level = diff;
        if ((diff <= LOWER)) begin
            outbusy = 1;
            noread = 1;
        end
        else begin
            outbusy = 0;
            noread = 0;
        end
    end

endmodule
