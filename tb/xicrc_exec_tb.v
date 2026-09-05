`timescale 1ns/1ps

module xicrc_exec_tb;

    reg  [31:0] data_i;
    reg  [15:0] crc_i;
    reg  [1:0]  crc_sel;

    wire [15:0] crc_o;

    integer errors;


    xicrc_exec dut (
        .data_i(data_i),
        .crc_i(crc_i),
        .crc_sel(crc_sel),
        .crc_o(crc_o)
    );


    task check_result;

        input [31:0] test_data;
        input [15:0] test_crc;
        input [1:0]  test_sel;
        input [15:0] expected;

        begin

            data_i  = test_data;
            crc_i   = test_crc;
            crc_sel = test_sel;

            #1;

            if (crc_o === expected) begin

                $display(
                    "PASS | data=%h crc_i=%h sel=%b result=%h",
                    data_i,
                    crc_i,
                    crc_sel,
                    crc_o
                );

            end
            else begin

                $display(
                    "FAIL | data=%h crc_i=%h sel=%b expected=%h got=%h",
                    data_i,
                    crc_i,
                    crc_sel,
                    expected,
                    crc_o
                );

                errors = errors + 1;

            end

        end

    endtask


    initial begin

        $dumpfile("crc.vcd");
        $dumpvars(0, xicrc_exec_tb);

        errors = 0;

        $display("----------------------------------------");
        $display("XICRC TESTBENCH");
        $display("----------------------------------------");


        // CRCB
        check_result(
            32'h0000000D,
            16'h0000,
            2'b00,
            16'hD1AD
        );


        // CRCB with non-zero starting CRC
        check_result(
            32'h00000000,
            16'h8000,
            2'b00,
            16'h9188
        );


        // CRCH
        check_result(
            32'h00001234,
            16'h0000,
            2'b01,
            16'h13C6
        );


        // CRCW
        check_result(
            32'h12345678,
            16'h0000,
            2'b10,
            16'hB42C
        );


        // CRCH all ones
        check_result(
            32'h0000FFFF,
            16'h0000,
            2'b01,
            16'h1D0F
        );


        // CRCW all ones
        check_result(
            32'hFFFFFFFF,
            16'h0000,
            2'b10,
            16'h99CF
        );


        $display("----------------------------------------");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $display("----------------------------------------");

        $finish;

    end

endmodule