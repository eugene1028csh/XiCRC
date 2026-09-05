`timescale 1ns/1ps

module xicrc_exec_tb;

reg  [31:0] rs1_data;
reg  [31:0] rs2_seed;
reg  [1:0]  crc_sel;

wire [15:0] crc_result;

xicrc_exec dut (
    .rs1_data(rs1_data),
    .rs2_seed(rs2_seed),
    .crc_sel(crc_sel),
    .crc_result(crc_result)
);

initial begin

    rs1_data = 32'h12345678;
    rs2_seed = 32'h0000FFFF;

    crc_sel = 2'b00;
    #10;

    $display("CRCB result = %h", crc_result);

    crc_sel = 2'b01;
    #10;

    $display("CRCH result = %h", crc_result);

    crc_sel = 2'b10;
    #10;

    $display("CRCW result = %h", crc_result);

    $finish;

end

endmodule