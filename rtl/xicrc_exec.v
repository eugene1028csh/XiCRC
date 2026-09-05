module xicrc_exec (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_seed,
    input  wire [1:0]  crc_sel,

    output reg  [15:0] crc_result
);

always @(*) begin

    case (crc_sel)

        2'b00: begin
            // CRCB - process rs1_data[7:0]
            crc_result = rs2_seed[15:0];
        end

        2'b01: begin
            // CRCH - process rs1_data[15:0]
            crc_result = rs2_seed[15:0];
        end

        2'b10: begin
            // CRCW - process rs1_data[31:0]
            crc_result = rs2_seed[15:0];
        end

        default: begin
            crc_result = 16'h0000;
        end

    endcase

end

endmodule