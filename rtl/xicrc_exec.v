module xicrc_exec #(
    parameter [15:0] POLY = 16'h1021   // provisional until officially verified
)(
    input  wire [31:0] data_i,
    input  wire [15:0] crc_i,
    input  wire [1:0]  crc_sel,

    output reg  [15:0] crc_o
);

    integer i;

    reg [15:0] crc8_result;
    reg [15:0] crc16_result;
    reg [15:0] crc32_result;


    // Performs ONE bit of the CRC calculation
    function [15:0] crc_next_bit;
        input [15:0] crc;
        input        data_bit;

        reg feedback;

        begin
            feedback = crc[15] ^ data_bit;

            crc_next_bit = crc << 1;

            if (feedback)
                crc_next_bit = crc_next_bit ^ POLY;
        end
    endfunction


    always @(*) begin

        // -------------------------
        // CRCB: process 8 bits
        // -------------------------
        crc8_result = crc_i;

        for (i = 7; i >= 0; i = i - 1)
            crc8_result =
                crc_next_bit(crc8_result, data_i[i]);


        // -------------------------
        // CRCH: process 16 bits
        // -------------------------
        crc16_result = crc_i;

        for (i = 15; i >= 0; i = i - 1)
            crc16_result =
                crc_next_bit(crc16_result, data_i[i]);


        // -------------------------
        // CRCW: process 32 bits
        // -------------------------
        crc32_result = crc_i;

        for (i = 31; i >= 0; i = i - 1)
            crc32_result =
                crc_next_bit(crc32_result, data_i[i]);


        // Select result
        case (crc_sel)

            2'b00:
                crc_o = crc8_result;

            2'b01:
                crc_o = crc16_result;

            2'b10:
                crc_o = crc32_result;

            default:
                crc_o = 16'h0000;

        endcase

    end

endmodule