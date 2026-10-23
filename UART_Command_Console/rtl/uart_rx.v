module uart_rx(
    input wire clk,
    input wire rx,
    output reg [7:0] data = 0,
    output reg valid = 0
);


    reg rx_meta = 1;
    reg rx_sync = 1;

    always @(posedge clk) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state = IDLE;

    reg [9:0] baud_counter = 0;
    reg [2:0] bit_index = 0;

    always @(posedge clk) begin

        valid <= 0;

        case (state)

            IDLE: begin
                baud_counter <= 0;
                bit_index <= 0;

                // Detect start bit
                if (rx_sync == 0)
                    state <= START;
            end

            START: begin
                // Wait approximately half a bit
                if (baud_counter == 433) begin
                    baud_counter <= 0;

                    if (rx_sync == 0)
                        state <= DATA;
                    else
                        state <= IDLE;
                end
                else
                    baud_counter <= baud_counter + 1;
            end

            DATA: begin
                if (baud_counter == 867) begin
                    baud_counter <= 0;

                    data[bit_index] <= rx_sync;

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end
                else
                    baud_counter <= baud_counter + 1;
            end

            STOP: begin
                if (baud_counter == 867) begin
                    baud_counter <= 0;
                    state <= IDLE;

                    if (rx_sync == 1)
                        valid <= 1;
                end
                else
                    baud_counter <= baud_counter + 1;
            end

            default: state <= IDLE;

        endcase
    end

endmodule
