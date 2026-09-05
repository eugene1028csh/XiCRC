module xicrc_accelerator_unit (
    input  wire [31:0] rs1_data,    	// Data payload from register file
    input  wire [31:0] rs2_seed,    	// Initial seed from register file
    input  wire [6:0]  funct7,      	// Instruction funct7 field for decoding
    input  wire [2:0]  funct3,      	// Instruction funct3 field (selects byte/half/word)
    output wire [31:0] rd_data,     	// Final computed CRC checksum result
    output wire        ext_ready,   	// Handshake signal: extension is handling this
    output wire        ext_writeback,   // Handshake signal: write result back to rd
    output wire        ext_illegal  	// Exception signal: invalid instruction variant
);

    // --------------------------------------------------------
    // 1. Internal Decoder / Controller Logic
    // --------------------------------------------------------
    // Check if funct7 matches our custom CRC extension identifier (0x40)
    wire is_crc_inst = (funct7 == 7'b1000000);

    // Check if the funct3 variant is valid (000 = Byte, 001 = Half, 010 = Word)
    wire valid_funct3 = (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010);

    // Generate internal crc_sel:
    // If it's our instruction and valid, pass funct3. Otherwise, idle with 4'b1111.
    wire [3:0] crc_sel = (is_crc_inst && valid_funct3) ? {1'b0, funct3} : 4'b1111;

    // Drive the control/handshake and exception outputs matching the port names
    assign ext_ready     = is_crc_inst;
    assign ext_writeback = is_crc_inst && valid_funct3;
    assign ext_illegal   = is_crc_inst && !valid_funct3;

    // --------------------------------------------------------
    // 2. Instantiate the CRC Execution Unit
    // --------------------------------------------------------
    xicrc_exec crc_accelerator_inst (
        .rs1_data(rs1_data),
        .rs2_seed(rs2_seed),
        .crc_sel(crc_sel),
        .rd_data(rd_data)
    );

endmodule


module xicrc_exec (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_seed,
    input  wire [3:0]  crc_sel,
    output reg  [31:0] rd_data
);

    localparam POLY = 16'h1021;  // polynomial from CRC16-CCITT-FALSE OR known as CRC-16/IBM-3740

    function [15:0] calc_bit(input [15:0] crc, input d_bit);
        begin
	    // modulo division with checking and bring down next number as in long division
	    // implemented using LFSR approach
            calc_bit = (crc << 1) ^ ((crc[15] ^ d_bit) ? POLY : 16'h0); 
        end
    endfunction

    integer i;
    reg [15:0] crc_result;

    always @(*) begin
        crc_result = rs2_seed[15:0]; 
        
        // Compact loop formatting using raw binary for selectors
        case (crc_sel)
            4'b0000: for (i = 7;  i >= 0; i = i - 1) crc_result = calc_bit(crc_result, rs1_data[i]); // Byte, crcb
            4'b0001: for (i = 15; i >= 0; i = i - 1) crc_result = calc_bit(crc_result, rs1_data[i]); // HWORD, crch
            4'b0010: for (i = 31; i >= 0; i = i - 1) crc_result = calc_bit(crc_result, rs1_data[i]); // WORD, crcw
            default: crc_result = 16'b0;
        endcase
        
        // Assign final result or zero out if invalid selector
        rd_data = (crc_sel <= 4'b0010) ? {16'b0, crc_result} : 32'b0;
    end

endmodule
