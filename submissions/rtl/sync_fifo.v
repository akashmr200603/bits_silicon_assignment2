module sync_fifo #(
    parameter integer DATA_WIDTH = 8,
    parameter integer DEPTH      = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,      
    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire                   wr_full,
    input  wire                   rd_en,
    output reg  [DATA_WIDTH-1:0]  rd_data,
    output wire                   rd_empty,
    output wire [$clog2(DEPTH):0] count
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Internal Hardware Structure
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];     
    reg [ADDR_WIDTH-1:0] wr_ptr;              
    reg [ADDR_WIDTH-1:0] rd_ptr;              
    reg [ADDR_WIDTH:0]   occ_count;           

    // Continuous Assignments for Output Flags
    assign count    = occ_count;
    assign wr_full  = (occ_count == DEPTH);   
    assign rd_empty = (occ_count == 0);       

    // Synchronous Logic 
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr    <= 0;
            rd_ptr    <= 0;
            occ_count <= 0;
        end else begin
            
            // Write Operation
            if (wr_en && !wr_full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr      <= (wr_ptr == DEPTH - 1) ? 0 : wr_ptr + 1;
            end
            
            // Read Operation
            if (rd_en && !rd_empty) begin
                rd_data <= mem[rd_ptr];
                rd_ptr  <= (rd_ptr == DEPTH - 1) ? 0 : rd_ptr + 1;
            end
            
            // Occupancy Counter Logic
            case ({ (wr_en && !wr_full), (rd_en && !rd_empty) })
                2'b10: occ_count <= occ_count + 1; 
                2'b01: occ_count <= occ_count - 1; 
                2'b11: occ_count <= occ_count;     
                2'b00: occ_count <= occ_count;     
            endcase
        end
    end

endmodule
