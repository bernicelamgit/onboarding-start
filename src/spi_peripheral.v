`default_nettype none

module spi_peripheral (
    input wire clk,
    input wire rst_n,
    input wire sclk, 
    input wire ncs,
    input wire copi, 
    output reg [7:0] pwm_val
);
    reg [2:0] sclk_sync;
    reg [2:0] ncs_sync;
    reg [2:0] copi_sync;

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            ncs_sync <= 3'b111;
            copi_sync <= 3'b000;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk };
            ncs_sync <= {ncs_sync[1:0], ncs };
            copi_sync <= {copi_sync[1:0], copi };
        end
    end

    wire sclk_rising_edge = sclk_sync[2]==0 && sclk_sync[1]==1;
    
    reg [15:0] shift_reg;
    reg [4:0] bit_counter;

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <=5'd0;
            shift_reg<=16'd0;
        end else if (ncs_sync[1]) begin
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
        end else  if(sclk_rising_edge) begin
                bit_counter <= bit_counter + 1'b1;
                shift_reg <= {shift_reg[14:0], copi_sync[1]};
            end

            
        end
    end

    localparam MAX_ADDRESS = 7'h04;
    wire ncs_rising_edge = (ncs_sync[2]== 0 && ncs_sync[1]==1);
    wire transaction_ready = ncs_rising_edge && bit_counter == 5'd16 && shift_reg[14:8]<=MAX_ADDRESS;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_val <= 8'b0;
        end else if (transaction_ready) begin
            pwm_val <= shift_reg [7:0];
            
        end
    end









        


endmodule