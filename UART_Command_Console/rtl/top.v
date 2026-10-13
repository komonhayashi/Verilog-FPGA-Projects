
module top(
    input  wire       clk,
    input  wire       rx,
    input  wire [3:0] sw,
    output wire       tx,
    output reg        led = 0
);

    wire [7:0] received_data;
    wire received_valid;

    uart_rx receiver (
        .clk(clk),
        .rx(rx),
        .data(received_data),
        .valid(received_valid)
    );

    reg [7:0] tx_data = 0;
    reg tx_start = 0;
    wire tx_busy;

    uart_tx transmitter (
        .clk(clk),
        .start(tx_start),
        .data(tx_data),
        .tx(tx),
        .busy(tx_busy)
    );

    reg [7:0] echo_data = 0;

    reg [8*32-1:0] response_msg = 0;
    reg [5:0] response_len = 0;
    reg [5:0] char_index = 0;

    localparam IDLE           = 3'd0;
    localparam ECHO_SEND      = 3'd1;
    localparam ECHO_WAIT_BUSY = 3'd2;
    localparam ECHO_WAIT_DONE = 3'd3;
    localparam MSG_SEND       = 3'd4;
    localparam MSG_WAIT_BUSY  = 3'd5;
    localparam MSG_WAIT_DONE  = 3'd6;

    reg [2:0] state = IDLE;

    always @(posedge clk) begin

        tx_start <= 1'b0;

        case (state)

            IDLE: begin
                if (received_valid) begin

                    echo_data  <= received_data;
                    char_index <= 0;

                    
                    case (received_data)

                        // '1' = LED ON
                        8'h31: begin
                        led <= 1'b1;
                        response_msg <= {" ON", 8'h0D, 8'h0A};
                        response_len <= 5;
                    end

                        // '0' = LED OFF
                        8'h30: begin
                        led <= 1'b0;
                        response_msg <= {" OFF", 8'h0D, 8'h0A};
                        response_len <= 6;
                    end

                        // 'S' or 's' = Read switches
                        8'h53, 8'h73: begin
                        response_msg <= {
                            " SW=",
                            (sw[3] ? 8'h31 : 8'h30),
                            (sw[2] ? 8'h31 : 8'h30),
                            (sw[1] ? 8'h31 : 8'h30),
                            (sw[0] ? 8'h31 : 8'h30),
                            8'h0D, 8'h0A
                        };
                        response_len <= 10;
                    end

                        // 'H' or 'h' = Help
                        8'h48, 8'h68: begin
                        response_msg <= {
                            " 1=ON 0=OFF S=SW H=HELP",
                            8'h0D, 8'h0A
                        };
                        response_len <= 25;
                    end

                        // Unknown command
                    default: begin
                        response_msg <= {" ?", 8'h0D, 8'h0A};
                        response_len <= 4;
                     end

            endcase


                    state <= ECHO_SEND;
                end
            end

            ECHO_SEND: begin
                if (!tx_busy) begin
                    tx_data  <= echo_data;
                    tx_start <= 1'b1;
                    state    <= ECHO_WAIT_BUSY;
                end
            end

            ECHO_WAIT_BUSY: begin
                if (tx_busy)
                    state <= ECHO_WAIT_DONE;
            end

            ECHO_WAIT_DONE: begin
                if (!tx_busy)
                    state <= MSG_SEND;
            end

            MSG_SEND: begin
                if (char_index == response_len) begin
                    state <= IDLE;
                end
                else if (!tx_busy) begin
                    tx_data <= response_msg[
                        ((response_len - char_index) * 8) - 1
                        -: 8
                    ];
                    tx_start <= 1'b1;
                    state <= MSG_WAIT_BUSY;
                end
            end

            MSG_WAIT_BUSY: begin
                if (tx_busy)
                    state <= MSG_WAIT_DONE;
            end

            MSG_WAIT_DONE: begin
                if (!tx_busy) begin
                    char_index <= char_index + 1'b1;
                    state <= MSG_SEND;
                end
            end

            default: state <= IDLE;

        endcase
    end

endmodule
