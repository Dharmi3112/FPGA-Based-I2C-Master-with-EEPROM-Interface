module i2c_master(
    input clk,
    input rst,
    input start,
    input rw,
    input [6:0] address,
    input [7:0] write_data,
    output reg [7:0] read_data,
    output reg scl,
    inout sda,
    output reg busy
);

reg sda_out,sda_en;

assign sda=sda_en?sda_out:1'bz;

parameter IDLE=0,START=1,ADDR=2,ACK1=3,WRITE=4,READ=5,ACK2=6,STOP=7;

reg [2:0] state;
reg [7:0] shift_reg;
reg [3:0] bit_count,clk_div;

always@(posedge clk or posedge rst)
begin

    if(rst)
    begin
        state<=IDLE;
        scl<=1;
        sda_out<=1;
        sda_en<=1;
        busy<=0;
        shift_reg<=0;
        bit_count<=0;
        clk_div<=0;
        read_data<=0;
    end

    else
    begin
        clk_div<=clk_div+1;
        case(state)

        IDLE:
        begin
            scl<=1;
            sda_en<=1;
            sda_out<=1;
            busy<=0;

            if(start)
            begin
                busy<=1;
                shift_reg<={address,rw};
                bit_count<=7;
                clk_div<=0;
                state<=START;
            end
        end

        START:
        begin
            if(clk_div==0)
            begin
                scl<=1;
                sda_en<=1;
                sda_out<=1;
            end
          
            else if(clk_div==2)
                sda_out<=0;
          
            else if(clk_div==5)
                scl<=0;
          
            else if(clk_div==10)
            begin
                clk_div<=0;
                state<=ADDR;
            end
        end

        ADDR,WRITE:
        begin
            if(clk_div==0)
            begin
                scl<=0;
                sda_en<=1;
            end

            else if(clk_div==2)
                sda_out<=(state==ADDR&&bit_count==0)?rw:shift_reg[bit_count];

            else if(clk_div==5)
                scl<=1;

            else if(clk_div==10)
            begin
                scl<=0;
                clk_div<=0;

                if(bit_count==0)
                    state<=(state==ADDR)?ACK1:ACK2;
                else
                    bit_count<=bit_count-1;
            end
        end

        ACK1:
        begin
            if(clk_div==0)
                scl<=0;

            else if(clk_div==2)
                sda_en<=0;

            else if(clk_div==5)
                scl<=1;

            else if(clk_div==10)
            begin
                scl<=0;
                clk_div<=0;
                bit_count<=7;

                if(rw)
                    state<=READ;

                else
                begin
                    shift_reg<=write_data;
                    state<=WRITE;
                end
            end
        end

        READ:
        begin
            if(clk_div==0)
            begin
                scl<=0;
                sda_en<=0;
            end

            else if(clk_div==5)
            begin
                scl<=1;
                read_data[bit_count]<=sda;
            end

            else if(clk_div==10)
            begin
                scl<=0;
                clk_div<=0;

                if(bit_count==0)
                    state<=ACK2;
                else
                    bit_count<=bit_count-1;
            end
        end

        ACK2:
        begin
            if(clk_div==0)
            begin
                scl<=0;
                sda_en<=rw?1:0;
                sda_out<=1;
            end

            else if(clk_div==5)
                scl<=1;

            else if(clk_div==10)
            begin
                clk_div<=0;
                state<=STOP;
            end
        end

        STOP:
        begin
            if(clk_div==0)
            begin
                scl<=0;
                sda_en<=1;
                sda_out<=0;
            end

            else if(clk_div==5)
                scl<=1;

            else if(clk_div==8)
                sda_out<=1;

            else if(clk_div==10)
            begin
                busy<=0;
                clk_div<=0;
                state<=IDLE;
            end
        end
          
        default:state<=IDLE;
          
        endcase
    end
end
endmodule
