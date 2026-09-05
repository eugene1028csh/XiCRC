`timescale 1ns/1ps

module xicrc_accelerator_unit_tb;

    reg  [31:0] ext_rs1_data;
    reg  [31:0] ext_rs2_data;
    reg  [6:0]  ext_funct7;
    reg  [2:0]  ext_funct3;

    wire        ext_ready;
    wire [31:0] ext_result;
    wire        ext_writeback;
    wire        ext_illegal;

    integer errors;

    xicrc_accelerator_unit #(
        .POLY(16'h1021)
    ) dut (
        .ext_rs1_data  (ext_rs1_data),
        .ext_rs2_data  (ext_rs2_data),
        .ext_funct7    (ext_funct7),
        .ext_funct3    (ext_funct3),
        .ext_ready     (ext_ready),
        .ext_result    (ext_result),
        .ext_writeback (ext_writeback),
        .ext_illegal   (ext_illegal)
    );

    task check_outputs;
        input [255:0] name;
        input         ready_e;
        input         wb_e;
        input         illegal_e;
        input [31:0]  result_e;
        begin
            #1;
            if ((ext_ready === ready_e) &&
                (ext_writeback === wb_e) &&
                (ext_illegal === illegal_e) &&
                (ext_result === result_e))
                $display("PASS | %0s", name);
            else begin
                $display("FAIL | %0s | ready=%b wb=%b illegal=%b result=%08h",
                         name, ext_ready, ext_writeback, ext_illegal, ext_result);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("xicrc_accelerator_unit.vcd");
        $dumpvars(0, xicrc_accelerator_unit_tb);
        errors = 0;

        // CRCB
        ext_rs1_data = 32'h0000000D;
        ext_rs2_data = 32'h00000000;
        ext_funct7   = 7'b1000000;
        ext_funct3   = 3'b000;
        check_outputs("CRCB decode/writeback", 1'b1, 1'b1, 1'b0, 32'h0000D1AD);

        // CRCH
        ext_rs1_data = 32'h00001234;
        ext_rs2_data = 32'h00000000;
        ext_funct3   = 3'b001;
        check_outputs("CRCH decode/writeback", 1'b1, 1'b1, 1'b0, 32'h000013C6);

        // CRCW
        ext_rs1_data = 32'h12345678;
        ext_rs2_data = 32'h00000000;
        ext_funct3   = 3'b010;
        check_outputs("CRCW decode/writeback", 1'b1, 1'b1, 1'b0, 32'h0000B42C);

        // Xicrc funct7 with unsupported funct3 is completed as illegal.
        ext_funct3 = 3'b111;
        check_outputs("invalid Xicrc variant", 1'b1, 1'b0, 1'b1, 32'h00000000);

        // Zmmul funct7 must not be claimed by the CRC unit.
        ext_funct7 = 7'b0000001;
        ext_funct3 = 3'b000;
        check_outputs("non-Xicrc extension not claimed", 1'b0, 1'b0, 1'b0, 32'h00000000);

        if (errors == 0)
            $display("ALL XICRC WRAPPER TESTS PASSED");
        else
            $display("%0d XICRC WRAPPER TEST(S) FAILED", errors);

        $finish;
    end

endmodule
