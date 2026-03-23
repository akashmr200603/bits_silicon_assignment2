`timescale 1ns/1ps

module tb_sync_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // DUT Signals
    reg clk;
    reg rst_n;
    reg wr_en;
    reg [DATA_WIDTH-1:0] wr_data;
    wire wr_full;
    reg rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire rd_empty;
    wire [ADDR_WIDTH:0] count;

    // Golden Model Variables
    reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];
    integer model_wr_ptr;
    integer model_rd_ptr;
    integer model_count;
    reg [DATA_WIDTH-1:0] model_rd_data;

    // Manual Coverage Counters
    integer cov_full;
    integer cov_empty;
    integer cov_wrap;
    integer cov_simul;
    integer cov_overflow;
    integer cov_underflow;
    
    // Initializing cycle
    integer cycle = 0;

    // Instantiating the DUT
    sync_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .wr_full(wr_full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .rd_empty(rd_empty),
        .count(count)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Cycle Counter Updates
    always @(posedge clk) begin
        if (!rst_n) cycle <= 0;
        else cycle <= cycle + 1;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            model_wr_ptr = 0;
            model_rd_ptr = 0;
            model_count = 0;
            model_rd_data = 0;
        end else begin
            // Simultaneous Read/Write
            if (wr_en && (model_count < DEPTH) && rd_en && (model_count > 0)) begin
                model_mem[model_wr_ptr] = wr_data;
                model_wr_ptr = (model_wr_ptr == DEPTH - 1) ? 0 : model_wr_ptr + 1;
                
                model_rd_data = model_mem[model_rd_ptr];
                model_rd_ptr = (model_rd_ptr == DEPTH - 1) ? 0 : model_rd_ptr + 1;
                cov_simul = cov_simul + 1;
            end
            // Write Only
            else if (wr_en && model_count < DEPTH) begin
                model_mem[model_wr_ptr] = wr_data;
                if (model_wr_ptr == DEPTH - 1) cov_wrap = cov_wrap + 1;
                model_wr_ptr = (model_wr_ptr == DEPTH - 1) ? 0 : model_wr_ptr + 1;
                model_count = model_count + 1;
            end
            // Read Only
            else if (rd_en && model_count > 0) begin
                model_rd_data = model_mem[model_rd_ptr];
                if (model_rd_ptr == DEPTH - 1) cov_wrap = cov_wrap + 1;
                model_rd_ptr = (model_rd_ptr == DEPTH - 1) ? 0 : model_rd_ptr + 1;
                model_count = model_count - 1;
            end
            
            // Track coverage for illegal operations
            if (wr_en && model_count == DEPTH) cov_overflow = cov_overflow + 1;
            if (rd_en && model_count == 0) cov_underflow = cov_underflow + 1;
            if (model_count == DEPTH) cov_full = cov_full + 1;
            if (model_count == 0) cov_empty = cov_empty + 1;
        end
    end


    // SCOREBOARD
    always @(negedge clk) begin
        if (rst_n) begin
            
            // Check Count
            if (count !== model_count) begin
                $display("\n=== SCOREBOARD ERROR: Count Mismatch ===");
                $display("Time: %0t | Cycle: %0d", $time, cycle);
                $display("Expected count = %0d, Got = %0d", model_count, count);
                $finish;
            end
            
            // Check Read Empty Flag
            if (rd_empty !== (model_count == 0)) begin
                $display("\n=== SCOREBOARD ERROR: Empty Flag Mismatch ===");
                $display("Time: %0t | Cycle: %0d", $time, cycle);
                $display("Expected empty = %b, Got = %b", (model_count == 0), rd_empty);
                $finish;
            end
            
            // Check Write Full Flag
            if (wr_full !== (model_count == DEPTH)) begin
                $display("\n=== SCOREBOARD ERROR: Full Flag Mismatch ===");
                $display("Time: %0t | Cycle: %0d", $time, cycle);
                $display("Expected full = %b, Got = %b", (model_count == DEPTH), wr_full);
                $finish;
            end
        end
    end


    // DIRECTED TESTS
    initial begin
        // Initialize inputs and coverage
        rst_n = 1; wr_en = 0; rd_en = 0; wr_data = 0;
        cov_full = 0; cov_empty = 0; cov_wrap = 0; 
        cov_simul = 0; cov_overflow = 0; cov_underflow = 0;

        $display("Starting Directed Tests...");

        // Reset Test
        $display("Running Reset Test...");
        rst_n = 0;
        #15;
        rst_n = 1;
        #10;

        // Single Write / Read Test
        $display("Running Single Write/Read Test...");
        @(posedge clk);
        wr_en = 1; wr_data = 8'hAA;
        @(posedge clk);
        wr_en = 0;
        #10;
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;

        // Fill Test
        $display("Running Fill Test...");
        wr_en = 1;
        repeat(DEPTH) begin
            wr_data = $random;
            @(posedge clk);
        end
        wr_en = 0;

        // Overflow Attempt Test
        $display("Running Overflow Attempt Test...");
        wr_en = 1; wr_data = 8'hFF;
        @(posedge clk);
        wr_en = 0;

        // Drain Test
        $display("Running Drain Test...");
        rd_en = 1;
        repeat(DEPTH) @(posedge clk);
        rd_en = 0;

        // Underflow Attempt Test
        $display("Running Underflow Attempt Test...");
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;

        // Simultaneous Read/Write Test
        wr_en = 1; wr_data = 8'h11; @(posedge clk);
        $display("Running Simultaneous Read/Write Test...");
        wr_en = 1; rd_en = 1; wr_data = 8'h22;
        @(posedge clk);
        wr_en = 0; rd_en = 0;

        // Pointer Wrap-Around Test
        $display("Running Pointer Wrap-Around Test...");
        wr_en = 1;
        repeat(DEPTH + 2) begin
            wr_data = $random;
            @(posedge clk);
            if (wr_full) begin
                wr_en = 0; rd_en = 1;
            end else begin
                rd_en = 0;
            end
        end
        wr_en = 0; rd_en = 0;

        // End of Simulation: Print Coverage
        #20;
        $display("ALL TESTS PASSED SUCCESSFULLY");
        $display("--- Coverage Summary ---");
        $display("Full States Hit: %0d", cov_full);
        $display("Empty States Hit: %0d", cov_empty);
        $display("Pointer Wraps: %0d", cov_wrap);
        $display("Simultaneous R/W: %0d", cov_simul);
        $display("Overflow Attempts: %0d", cov_overflow);
        $display("Underflow Attempts: %0d", cov_underflow);
        $finish;
    end

endmodule
