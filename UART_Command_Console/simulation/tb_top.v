
`timescale 1ns / 1ps

module tb_top;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rx = 1;
    reg [3:0] sw = 0;

    wire tx;
    wire led;

    top dut (
        .clk(clk),
        .rx(rx),
        .sw(sw),
        .tx(tx),
        .led(led)
    );

    localparam integer BIT_TIME = 8680;

    reg [7:0] captured [0:255];
    integer received_count = 0;
    integer errors = 0;

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 0;               
            #BIT_TIME;

            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];       
                #BIT_TIME;
            end

            rx = 1;                 
            #BIT_TIME;
        end
    endtask

    reg [7:0] decoded;
    integer bit_num;

    initial begin
        forever begin
            @(negedge tx);

            #(BIT_TIME / 2);

            if (tx !== 1'b0) begin
                $display("FAIL: Invalid start bit");
                errors = errors + 1;
            end

            for (bit_num = 0; bit_num < 8;
                 bit_num = bit_num + 1) begin
                #BIT_TIME;
                decoded[bit_num] = tx;
            end

            #BIT_TIME;

            if (tx !== 1'b1) begin
                $display("FAIL: Invalid stop bit");
                errors = errors + 1;
            end

            captured[received_count] = decoded;
            received_count = received_count + 1;
        end
    end

    task check_command;
        input [7:0] command;
        input [8*32-1:0] expected;
        input integer expected_len;

        integer start_count;
        integer i;
        reg [7:0] expected_byte;

        begin
            start_count = received_count;

            send_byte(command);

            wait (received_count >=
                  start_count + expected_len);

            #1;

            for (i = 0; i < expected_len;
                 i = i + 1) begin

                expected_byte =
                    expected[(expected_len-1-i)*8 +: 8];

                if (captured[start_count+i] !==
                    expected_byte) begin

                    $display(
                        "FAIL: cmd=%c byte=%0d expected=%h got=%h",
                        command, i, expected_byte,
                        captured[start_count+i]
                    );

                    errors = errors + 1;
                end
            end

            $display("Checked command: %c", command);
        end
    endtask

    initial begin

        #1000;

        // Test LED ON
        check_command(
            "1",
            {"1", " ON", 8'h0D, 8'h0A},
            6
        );

        if (led !== 1'b1) begin
            $display("FAIL: LED did not turn ON");
            errors = errors + 1;
        end

        // Test LED OFF
        check_command(
            "0",
            {"0", " OFF", 8'h0D, 8'h0A},
            7
        );

        if (led !== 1'b0) begin
            $display("FAIL: LED did not turn OFF");
            errors = errors + 1;
        end

        // Test switches
        sw = 4'b0110;

        check_command(
            "s",
            {"s", " SW=0110", 8'h0D, 8'h0A},
            11
        );

        // Test help
        check_command(
            "h",
            {"h", " 1=ON 0=OFF S=SW H=HELP",
             8'h0D, 8'h0A},
            26
        );

        // Test unknown command
        check_command(
            "2",
            {"2", " ?", 8'h0D, 8'h0A},
            5
        );

        if (errors == 0)
            $display("PASS: ALL UART TESTS PASSED");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

    initial begin
        #15000000;
        $display("FAIL: Simulation timeout");
        $finish;
    end

endmodule

