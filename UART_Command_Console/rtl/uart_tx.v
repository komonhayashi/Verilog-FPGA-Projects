module uart_tx(
    input  wire clk,
    input  wire start,
    input  wire [7:0] data,

    output reg tx,
    output reg busy
);

    reg [9:0] baud_counter = 0;
    reg [2:0] i = 0;
    reg [7:0] data_reg = 0;
    
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state = IDLE;

    initial begin
        tx   = 1'b1;
        busy = 1'b0;
    end


    always @(posedge clk) begin

        case (state)

            IDLE: begin

                tx<= 1'b1;
                busy<= 1'b0;
                baud_counter<= 0;
                i<= 0;

                if (start) begin
                    data_reg<= data;
                    busy<= 1'b1;
                    tx<= 1'b0;
                    state<= START;
                end

            end

            START: begin

                if (baud_counter == 867) begin
                    baud_counter<= 0;
                    i<= 0;
                    tx<= data_reg[0];
                    state<= DATA;
                end
                else begin
                    baud_counter<= baud_counter + 1;
                end

            end

            DATA: begin

                if (baud_counter == 867) begin

                    baud_counter<= 0;

                    if (i == 7) begin
                        tx<= 1'b1;
                        state<= STOP;
                    end
                    else begin
                        i<= i + 1;
                        tx<= data_reg[i + 1];
                    end

                end
                else begin
                    baud_counter<= baud_counter + 1;
                end

            end
            
            STOP: begin

                if (baud_counter == 867) begin
                    baud_counter<= 0;
                    busy<= 1'b0;
                    state<= IDLE;
                end
                else begin
                    baud_counter<= baud_counter + 1;
                end

            end

            default: begin
                state <= IDLE;
                tx    <= 1'b1;
                busy  <= 1'b0;
            end

        endcase

    end

endmodule