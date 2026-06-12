`timescale 1ns/1ps

module i2c_tb;

reg clk;
reg rst;
reg start;
reg rw;

reg [6:0] address;
reg [7:0] write_data;

wire [7:0] read_data;
wire scl;
tri1 sda;
wire busy;

reg sda_slave;
reg [7:0] slave_data;

assign sda =
    (sda_slave == 0) ? 1'b0 :
    (dut.sda_en ? dut.sda_out : 1'bz);

i2c_master dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .rw(rw),
    .address(address),
    .write_data(write_data),
    .read_data(read_data),
    .scl(scl),
    .sda(sda),
    .busy(busy)
);

always #5 clk = ~clk;

initial
begin

    $dumpfile("i2c_wave.vcd");
    $dumpvars(0,i2c_tb);

    clk = 0;
    rst = 1;
    start = 0;
    rw = 0;

    sda_slave = 1;

    address = 7'b1010010;
    write_data = 8'b11001101;

    slave_data = 8'b01010101;

    #100;
    rst = 0;

    #100;

    rw = 0;
    start = 1;

    #20;
    start = 0;

    wait(busy == 0);

    #200;

    rw = 1;
    start = 1;

    #20;
    start = 0;

    wait(busy == 0);

    #500;
    $finish;

end

always @(posedge clk)
begin

    if(dut.state == dut.READ)
    begin

        if(dut.clk_div == 2)
            sda_slave <= slave_data[dut.bit_count];

        else if(dut.bit_count == 0)
            sda_slave <= slave_data[0];

    end

    else if(dut.state == dut.ACK1)
    begin

        if(dut.clk_div >= 2)
            sda_slave <= 0;

    end

    else if(dut.state == dut.ACK2)
    begin

        if(rw)
            sda_slave <= 1;

        else if(dut.clk_div >= 2)
            sda_slave <= 0;

    end

    else
    begin
        sda_slave <= 1;
    end

end

always @(posedge clk)
begin

    $display(
        "TIME=%0t STATE=%0d CLK_DIV=%0d SCL=%b SDA=%b BIT=%0d RW=%b WRITE=%b READ=%b BUSY=%b",
        $time,
        dut.state,
        dut.clk_div,
        scl,
        sda,
        dut.bit_count,
        rw,
        write_data,
        read_data,
        busy
    );

end

endmodule
