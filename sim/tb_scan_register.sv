
`timescale 1ns/1ps

module tb_scan_register;
    reg clk = 0;
    reg rst_n = 0;
    reg scan_enable = 0;
    reg scan_in = 0;
    reg load = 0;
    reg [7:0] data_in = 0;
    wire scan_out;
    wire [7:0] q;

    int checks = 0;

    always #5 clk = ~clk;

    scan_register dut (
        .clk(clk), .rst_n(rst_n),
        .scan_enable(scan_enable),
        .scan_in(scan_in), .scan_out(scan_out),
        .load(load), .data_in(data_in), .q(q)
    );

    task check_q(input logic [7:0] expected);
        if (q !== expected)
            $fatal(1, "Expected=%02h Actual=%02h", expected, q);
        checks++;
    endtask

    // Shift MSB first; sample outgoing bit before the clock edge.
    task shift_byte(input logic [7:0] value,
                    output logic [7:0] shifted_out);
        for (int k=7; k>=0; k--) begin
            @(negedge clk);
            scan_enable = 1;
            load = 0;
            scan_in = value[k];
            shifted_out[k] = scan_out;
            @(posedge clk);
            #1;
        end
    endtask

    task capture(input logic [7:0] value);
        @(negedge clk);
        scan_enable = 0;
        load = 1;
        data_in = value;
        @(posedge clk);
        #1;
        check_q(value);
        @(negedge clk);
        load = 0;
    endtask

    logic [7:0] observed;

    initial begin
        // Reset.
        repeat (3) @(negedge clk);
        check_q(8'h00);
        rst_n = 1;
        $display("PASS: reset");

        // Normal parallel loading.
        capture(8'h3C);
        $display("PASS: normal capture = 3C");

        // Shift out 3C while loading A5.
        shift_byte(8'hA5, observed);
        if (observed !== 8'h3C)
            $fatal(1, "Scan-out expected 3C, got %02h", observed);
        checks++;
        check_q(8'hA5);
        $display("PASS: scan-out = 3C, scan-in = A5");

        // Read back the scanned-in pattern.
        shift_byte(8'h00, observed);
        if (observed !== 8'hA5)
            $fatal(1, "Scan-out expected A5, got %02h", observed);
        checks++;
        check_q(8'h00);
        $display("PASS: scanned pattern A5 read back");

        // Capture a functional result, then observe it through scan.
        capture(8'h96);
        shift_byte(8'hFF, observed);
        if (observed !== 8'h96)
            $fatal(1, "Captured value expected 96, got %02h", observed);
        checks++;
        check_q(8'hFF);
        $display("PASS: capture 96 then scan-out 96");

        // Hold when neither scan nor load is enabled.
        @(negedge clk);
        scan_enable = 0;
        load = 0;
        data_in = 8'h12;
        repeat (3) begin
            @(posedge clk);
            #1;
            check_q(8'hFF);
        end
        $display("PASS: normal hold");

        // Reset a non-zero register.
        @(negedge clk);
        rst_n = 0;
        #1;
        check_q(8'h00);
        $display("PASS: reset after scan");

        $display("SCAN TEST PASS: checks=%0d", checks);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "Test timeout");
    end
endmodule

