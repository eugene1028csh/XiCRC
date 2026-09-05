`timescale 1ns/1ps

module xicrc_exec_tb;

    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    reg  [1:0]  crc_sel;
    wire [15:0] crc_result;

    integer errors;

    xicrc_exec #(
        .POLY(16'h1021)
    ) dut (
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        .crc_sel    (crc_sel),
        .crc_result (crc_result)
    );

    task check_result;
        input [255:0] name;
        input [31:0]  test_data;
        input [15:0]  test_crc;
        input [1:0]   test_sel;
        input [15:0]  expected;
        begin
            rs1_data = test_data;
            rs2_data = {16'h0000, test_crc};
            crc_sel  = test_sel;
            #1;

            if (crc_result === expected)
                $display("PASS | %0s | result=%04h", name, crc_result);
            else begin
                $display("FAIL | %0s | expected=%04h got=%04h", name, expected, crc_result);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("xicrc_exec.vcd");
        $dumpvars(0, xicrc_exec_tb);
        errors = 0;

        // Fixed vectors for the provisional 0x1021, MSB-first implementation.
        check_result("CRCB 0x0D seed 0000",   32'h0000000D, 16'h0000, 2'b00, 16'hD1AD);
        check_result("CRCB 0x00 seed 8000",   32'h00000000, 16'h8000, 2'b00, 16'h9188);
        check_result("CRCH 0x1234",            32'h00001234, 16'h0000, 2'b01, 16'h13C6);
        check_result("CRCW 0x12345678",        32'h12345678, 16'h0000, 2'b10, 16'hB42C);
        check_result("CRCH all ones",          32'h0000FFFF, 16'h0000, 2'b01, 16'h1D0F);
        check_result("CRCW all ones",          32'hFFFFFFFF, 16'h0000, 2'b10, 16'h99CF);

        // Standard CRC-16/CCITT-FALSE check vector "123456789".
        // This also verifies that rs2_data can act as a running CRC state:
        //   CRCW("1234", FFFF) -> state 1
        //   CRCW("5678", state1) -> state 2
        //   CRCB("9",    state2) -> 29B1
        rs1_data = 32'h31323334; rs2_data = 32'h0000FFFF; crc_sel = 2'b10; #1;
        rs2_data = {16'h0000, crc_result}; rs1_data = 32'h35363738; crc_sel = 2'b10; #1;
        rs2_data = {16'h0000, crc_result}; rs1_data = 32'h00000039; crc_sel = 2'b00; #1;
        if (crc_result === 16'h29B1)
            $display("PASS | chained 123456789 | result=%04h", crc_result);
        else begin
            $display("FAIL | chained 123456789 | expected=29B1 got=%04h", crc_result);
            errors = errors + 1;
        end

        // Invalid selector should give deterministic zero.
        rs1_data = 32'hDEADBEEF;
        rs2_data = 32'h00001234;
        crc_sel  = 2'b11;
        #1;
        if (crc_result === 16'h0000)
            $display("PASS | invalid selector -> 0000");
        else begin
            $display("FAIL | invalid selector | expected=0000 got=%04h", crc_result);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL XICRC EXEC TESTS PASSED");
        else
            $display("%0d XICRC EXEC TEST(S) FAILED", errors);

        $finish;
    end

endmodule
