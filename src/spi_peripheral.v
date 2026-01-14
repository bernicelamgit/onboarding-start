`default_nettype none

module spi_peripheral (
    input wire clk,
    input wire rst_n,
    input wire sclk, 
    input wire ncs,
    input wire copi, 

    output reg [7:0] en_reg_out_7_0,
    output reg  [7:0]  en_reg_out_15_8,
    output reg  [7:0]  en_reg_pwm_7_0,
    output reg  [7:0]  en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
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
    wire ncs_rising_edge = (ncs_sync[2]== 0 && ncs_sync[1]==1);
    wire ncs_falling_edge = (ncs_sync[2]== 1 && ncs_sync[1]==0);
    reg [15:0] shift_reg;
    reg [4:0] bit_counter;

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <=5'd0;
            shift_reg<=16'd0;
        end else if (ncs_falling_edge) begin
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
        end else  if(!ncs_sync[1] && sclk_rising_edge) begin
            bit_counter <= bit_counter + 1'b1;
            shift_reg <= {shift_reg[14:0], copi_sync[2]};
            

            
        end
    end

    localparam MAX_ADDRESS = 7'h04;
    
    wire transaction_ready = ncs_rising_edge && bit_counter == 5'd16 && shift_reg[15] == 1'b1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0 <= 8'b0;
            en_reg_out_15_8 <= 8'b0;
            en_reg_pwm_7_0 <= 8'b0;
            en_reg_pwm_15_8 <= 8'b0;
            pwm_duty_cycle <= 8'b0;
        end else if (transaction_ready) begin
            case(shift_reg[14:8])
                7'h00: en_reg_out_7_0  <= shift_reg[7:0];
                7'h01: en_reg_out_15_8 <= shift_reg[7:0];
                7'h02: en_reg_pwm_7_0  <= shift_reg[7:0];
                7'h03: en_reg_pwm_15_8 <= shift_reg[7:0];
                7'h04: pwm_duty_cycle  <= shift_reg[7:0];
                default: ;
            endcase

            
        end
    end









        


endmodule