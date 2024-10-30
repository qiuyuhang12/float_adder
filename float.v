module float_add(input [31:0] x,
                 input [31:0] y,
                 input clk,
                 input rst,
                 output reg [31:0] z,
                 output reg [1:0] overflow);
reg [24:0] tail_x,tail_y,tail_z;
reg [7:0] exp_x,exp_y,exp_z;
reg [2:0] st_now,st_next;
reg sign_x,sign_y,sign_z;

parameter start = 3'b000,zero_check = 3'b001,eq_check = 3'b010,add = 3'b011,normal = 3'b100,over = 3'b101;
always @(posedge clk or negedge rst)begin
    if (!rst)begin
        st_now <= start;
    end
    else begin
        st_now <= st_next;
    end
end

always @(tail_x,tail_y,tail_z,exp_x,exp_y,exp_z,sign_x,sign_y,sign_z,st_now,st_next)begin
    case (st_now)
        start:begin
            tail_x <= {1'b0,1'b1,x[22:0]};
            tail_y <= {1'b0,1'b1,y[22:0]};
            exp_x  <= x[30:23];
            exp_y  <= y[30:23];
            sign_x <= x[31];
            sign_y <= y[31];
            if ((exp_x == 8'd255&&tail_x[22:0]!= 0)||(exp_y == 8'd255&&tail_y[22:0]!= 0)||(exp_x == 8'b11111111 && exp_y == 8'b11111111 && sign_x!=sign_y))begin
                st_next  <= over;
                sign_z   <= 1'b0;
                exp_z    <= 8'b11111111;
                tail_z   <= 23'b11111111111111111111111;
                overflow <= 2'b11;
            end
            else if (exp_x == 8'b11111111)begin
                st_next  <= over;
                sign_z   <= sign_x;
                exp_z    <= 8'b11111111;
                tail_z   <= 23'b0;
                overflow <= 2'b11;
            end
			else if (exp_y == 8'b11111111)begin
                st_next  <= over;
                sign_z   <= sign_y;
                exp_z    <= 8'b11111111;
                tail_z   <= 23'b0;
                overflow <= 2'b11;
            end
            else if ((exp_x == 8'b0 && tail_x[22:0]!= 23'b0) || (exp_y == 8'b0 && tail_y[22:0]!= 23'b0))begin
                st_next  <= over;
                sign_z   <= 1'b0;
                exp_z    <= 8'b0;
                tail_z   <= 23'b0;
                overflow <= 2'b11;
            end
            else begin
                overflow <= 2'b00;
                st_next  <= zero_check;
            end
        end
        zero_check:begin
            if (exp_x == 8'b0 && tail_x[22:0] == 23'b0)begin
                st_next <= over;
                sign_z  <= sign_y;
                exp_z   <= exp_y;
                tail_z  <= tail_y;
            end
            else if (exp_y == 8'b0 && tail_y[22:0] == 23'b0)begin
                st_next <= over;
                sign_z  <= sign_x;
                exp_z   <= exp_x;
                tail_z  <= tail_x;
            end
            else begin
                st_next <= eq_check;
            end
        end
        eq_check:begin
            if (exp_x == exp_y)begin
                st_next <= add;
            end
            else begin
                if (exp_x > exp_y)begin
                    tail_y <= {1'b0,tail_y[24:1]};
                    exp_y  <= exp_y + 1;
                    if (tail_y == 24'b0)begin
                        sign_z  <= sign_x;
                        exp_z   <= exp_x;
                        tail_z  <= tail_x;
                        st_next <= over;
                    end
                    else begin
                        st_next <= eq_check;
                    end
                end
                else begin
                    tail_x <= {1'b0,tail_x[24:1]};
                    exp_x  <= exp_x + 1;
                    if (tail_x == 24'b0)begin
                        sign_z  <= sign_y;
                        exp_z   <= exp_y;
                        tail_z  <= tail_y;
                        st_next <= over;
                    end
                    else begin
                        st_next <= eq_check;
                    end
                end
            end
        end
        add:begin
            if (sign_x == sign_y)begin
                tail_z  <= tail_x + tail_y;
                exp_z   <= exp_x;
                sign_z  <= sign_x;
                st_next <= normal;
            end
            else begin
                if (tail_x > tail_y)begin
                    tail_z  <= tail_x - tail_y;
                    exp_z   <= exp_x;
                    sign_z  <= sign_x;
                    st_next <= normal;
                end
                else if (tail_x < tail_y)begin
                    tail_z  <= tail_y - tail_x;
                    exp_z   <= exp_y;
                    sign_z  <= sign_y;
                    st_next <= normal;
                end
                else begin
                    tail_z   <= 24'b0;
                    exp_z    <= 0;
                    sign_z   <= 0;
                    st_next	 <= over;
                end
            end
        end
        normal:begin
            if (tail_z[24])begin
                tail_z  <= {1'b0,tail_z[24:1]};
                exp_z   <= exp_z + 1;
                st_next <= over;
            end
            else if (!tail_z[23])begin
                tail_z  <= {tail_z[23:0],1'b0};
                exp_z   <= exp_z - 1;
                st_next <= normal;
            end
            else begin
                st_next <= over;
            end
        end
        over:begin
			// $display("exp_z=%b",exp_z);
            st_next <= over;
            if (overflow)begin
            	z = {sign_z,exp_z[7:0],tail_z[22:0]};
				overflow<=overflow;
            end
            else if (exp_z == 8'd255)begin
				z = {sign_z,8'b11111111,23'b0};
				// $display("overflow:",overflow);
                overflow <= 2'b01;
            end
            else if (exp_z == 8'b0&&tail_z[22:0]!= 23'b0)begin
				z = {sign_z,8'b0,tail_z[22:0]};
                overflow <= 2'b10;
            end
            else begin
				z = {sign_z,exp_z[7:0],tail_z[22:0]};
                overflow <= 2'b00;
            end
            
        end
        default:begin
        end
    endcase
end
endmodule
