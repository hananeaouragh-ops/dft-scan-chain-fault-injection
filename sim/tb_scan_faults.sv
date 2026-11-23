
`timescale 1ns/1ps

module tb_scan_faults;
    reg clk = 0;
    reg rst_n = 0;
    reg scan_enable = 0;
    reg scan_in = 0;
    reg load = 0;
    reg [7:0] data_in = 0;

    wire good_out;
    wire [7:0] good_q;
    wire [7:0] sa0_out;
    wire [7:0] sa1_out;

    bit [7:0] detected_sa0 = 0;
    bit [7:0] detected_sa1 = 0;
    int detected_count = 0;

    always #5 clk = ~clk;

    scan_register good (
        .clk(clk), .rst_n(rst_n),
        .scan_enable(scan_enable), .scan_in(scan_in),
        .load(load), .data_in(data_in),
        .scan_out(good_out), .q(good_q)
    );

    // Each instance contains one permanently forced state bit.
    generate
        for (genvar g=0; g<8; g++) begin : faults
            wire [7:0] q0, q1;

            scan_register stuck0 (
                .clk(clk), .rst_n(rst_n),
                .scan_enable(scan_enable), .scan_in(scan_in),
                .load(load), .data_in(data_in),
                .scan_out(sa0_out[g]), .q(q0)
            );

            scan_register stuck1 (
                .clk(clk), .rst_n(rst_n),
                .scan_enable(scan_enable), .scan_in(scan_in),
                .load(load), .data_in(data_in),
                .scan_out(sa1_out[g]), .q(q1)
            );

            initial begin
                force stuck0.q[g] = 1'b0;
                force stuck1.q[g] = 1'b1;
            end
        end
    endgenerate

    task test_pattern(input logic [7:0] pattern);
        // Load through scan.
        for (int k=7; k>=0; k--) begin
            @(negedge clk);
            scan_enable = 1;
            scan_in = pattern[k];
            @(posedge clk);
            #1;
        end

        // Observe only serial scan outputs.
        for (int k=7; k>=0; k--) begin
            @(negedge clk);
            scan_in = 0;

            if (good_out !== pattern[k])
                $fatal(1, "Fault-free reference failed");

            for (int b=0; b<8; b++) begin
                if ($isunknown({sa0_out[b], sa1_out[b]}))
                    $fatal(1, "Unknown fault-model output");

                if (sa0_out[b] != good_out)
                    detected_sa0[b] = 1;

                if (sa1_out[b] != good_out)
                    detected_sa1[b] = 1;
            end

            @(posedge clk);
            #1;
        end

        $display("Pattern %02h applied and observed", pattern);
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;

        test_pattern(8'h00);
        test_pattern(8'hFF);
        test_pattern(8'h55);
        test_pattern(8'hAA);

        for (int b=0; b<8; b++) begin
            $display("q[%0d]: SA0 detected=%0b SA1 detected=%0b",
                     b, detected_sa0[b], detected_sa1[b]);
            if (detected_sa0[b]) detected_count++;
            if (detected_sa1[b]) detected_count++;
        end

        $display("Selected state-bit faults detected: %0d / 16",
                 detected_count);

        if (detected_count != 16)
            $fatal(1, "Some selected faults were not detected");

        $display("FAULT TEST PASS");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "Fault test timeout");
    end
endmodule

