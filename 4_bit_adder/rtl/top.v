module top(
    input  wire [10:0] sw,
    output wire [5:0]  led
);

    wire [3:0] A;
    wire [3:0] B;
    wire [2:0] operation;

    assign A = sw[3:0];
    assign B = sw[7:4];
    assign operation = sw[10:8];

    wire [4:0] add_result;
    wire [4:0] sub_result;
    wire [3:0] and_result;
    wire [3:0] or_result;
    wire [3:0] xor_result;
    wire [3:0] not_result;

    assign add_result = A + B;
    assign sub_result = A - B;

    assign and_result = A & B;
    assign or_result  = A | B;
    assign xor_result = A ^ B;
    assign not_result = ~A;

    reg [3:0] result;
    reg carry;

    always @(*) begin

        result = 4'b0000;
        carry  = 1'b0;

        case (operation)

            3'b000: begin       // ADD
                result = add_result[3:0];
                carry  = add_result[4];
            end

            3'b001: begin       // SUBTRACT
                result = sub_result[3:0];
                carry  = sub_result[4];
            end

            3'b010: begin       // AND
                result = and_result;
            end

            3'b011: begin       // OR
                result = or_result;
            end

            3'b100: begin       // XOR
                result = xor_result;
            end

            3'b101: begin       // NOT A
                result = not_result;
            end

            3'b110: begin       // SHIFT A LEFT
                result = A << 1;
            end

            3'b111: begin       // SHIFT A RIGHT
                result = A >> 1;
            end

        endcase
    end

    assign led[3:0] = result;

    assign led[4] = carry;

    assign led[5] = (result == 4'b0000);

endmodule