module image_scale
#(
    parameter W_IN  = 800,
    parameter H_IN  = 566,
    parameter W_OUT = 900,
    parameter H_OUT = 700,
    parameter FRAC_BITS = 8,
    parameter MEM_INPUT_SIZE = W_IN * H_IN,
    parameter MEM_OUTPUT_SIZE = W_OUT * H_OUT,
    parameter scale_x = (W_IN << FRAC_BITS) / W_OUT,
    parameter scale_y = (H_IN << FRAC_BITS) / H_OUT,
    parameter CHANNELS = 3
)
(
    input clk,
    input start,
    output reg done
);
localparam DATA_WIDTH = 8*CHANNELS;
localparam X_OUT_BITS = $clog2(W_OUT);
localparam Y_OUT_BITS = $clog2(H_OUT);
localparam X_IN_BITS  = $clog2(W_IN);
localparam Y_IN_BITS  = $clog2(H_IN);
localparam ADDR_OUT_BITS = $clog2(W_OUT * H_OUT);
localparam ADDR_IN_BITS  = $clog2(W_IN * H_IN);


reg write_done;

initial begin
    write_done <= 0;
    $readmemh("h_RGB_image.hex", image_mem);
end // Read buffer 

always @(posedge clk) begin
    if (done && !write_done) begin
        write_done <= 1;
        $writememh("h_RGB_out.hex", output_mem);
    end
end// write buffer


reg [X_OUT_BITS-1:0] X_out;
reg [Y_OUT_BITS-1:0] Y_out;
reg write_enable;

parameter S_IDLE = 1'b0;
parameter RUN    = 1'b1;

reg state, next_state;
//CONTROL PATH
always @(*) begin //next_state logic
    case(state)
        S_IDLE: next_state = start ? RUN : S_IDLE;
        RUN: begin
            if((S4S5_addr_out==(W_OUT*H_OUT-1))&&(valid_pipe[3]))
                next_state = S_IDLE;
            else
                next_state = RUN;
        end
        default: next_state=S_IDLE;
    endcase
end

always @(posedge clk)//flip_flop logic
    state <= next_state;

always @(posedge clk)//state_logic
begin
    case(state)
        S_IDLE:
        begin
            X_out <= 0;
            Y_out <= 0;
            write_enable <= 0;
            done<=0;
            valid_pipe <= 4'b0000;
        end

        RUN:
        begin
            write_enable <= 1;

            if((S4S5_addr_out==(W_OUT*H_OUT-1))&&(valid_pipe[3]))
                done<=1;

            if(~((X_out==W_OUT-1)&(Y_out==H_OUT-1)))
            begin
                if(X_out == W_OUT-1)
                begin
                    X_out <= 0;
                    Y_out <= Y_out + 1;
                end
                else
                    X_out <= X_out + 1;
            end
            else
            begin
                X_out<=0;
                Y_out<=0;
            end
        end
    endcase
end

wire pipe_en;
assign pipe_en = (state == RUN);


//STAGE 1
reg [DATA_WIDTH-1:0] image_mem [0:MEM_INPUT_SIZE-1];

reg [ADDR_OUT_BITS-1:0] S1S2_addr_out;
reg [(X_OUT_BITS+FRAC_BITS):0] S1S2_X_in;
reg [(Y_OUT_BITS+FRAC_BITS):0] S1S2_Y_in;

wire [(X_OUT_BITS+FRAC_BITS):0] X_in_calc;
wire [(Y_OUT_BITS+FRAC_BITS):0] Y_in_calc;
wire [ADDR_OUT_BITS-1:0] addr_out_calc;

assign X_in_calc = X_out * scale_x;
assign Y_in_calc = Y_out * scale_y;
assign addr_out_calc = X_out + (W_OUT * Y_out);

always @(posedge clk)
begin
    if(pipe_en)
    begin
        S1S2_X_in <= X_in_calc;
        S1S2_Y_in <= Y_in_calc;
        S1S2_addr_out <= addr_out_calc;
    end
end



wire [X_IN_BITS-1:0] x0;
wire [Y_IN_BITS-1:0] y0;

wire [ADDR_IN_BITS-1:0] ADDR_IN_I00;
wire [ADDR_IN_BITS-1:0] ADDR_IN_I01;
wire [ADDR_IN_BITS-1:0] ADDR_IN_I10;
wire [ADDR_IN_BITS-1:0] ADDR_IN_I11;

wire [FRAC_BITS-1:0] a,b;

reg [DATA_WIDTH-1:0] S2S3_I00,S2S3_I10,S2S3_I01,S2S3_I11;
reg [FRAC_BITS-1:0] S2S3_a,S2S3_b;
reg [ADDR_OUT_BITS-1:0] S2S3_addr_out;

assign a = S1S2_X_in[FRAC_BITS-1:0];
assign b = S1S2_Y_in[FRAC_BITS-1:0];

assign x0 = (S1S2_X_in >> FRAC_BITS);
assign y0 = (S1S2_Y_in >> FRAC_BITS);

wire [X_IN_BITS-1:0] x1 = (x0 == W_IN-1) ? (x0): x0+1;
wire [Y_IN_BITS-1:0] y1 = (y0 == H_IN-1) ? (y0): y0+1;

assign ADDR_IN_I00 = (x0 + (W_IN * y0));
assign ADDR_IN_I10 = x1 + W_IN*y0;
assign ADDR_IN_I01 = x0 + W_IN*y1;
assign ADDR_IN_I11 = x1 + W_IN*y1;

//STAGE 2
always @(posedge clk)
begin
    if(pipe_en)
    begin
        S2S3_a <= a;
        S2S3_b <= b;

        S2S3_I00 <= image_mem[ADDR_IN_I00];
        S2S3_I01 <= image_mem[ADDR_IN_I01];
        S2S3_I10 <= image_mem[ADDR_IN_I10];
        S2S3_I11 <= image_mem[ADDR_IN_I11];

        S2S3_addr_out <= S1S2_addr_out;
    end
end

reg [DATA_WIDTH-1:0] S3S4_T;
reg [DATA_WIDTH-1:0] S3S4_B;

reg [FRAC_BITS-1:0] S3S4_b;
reg [ADDR_OUT_BITS-1:0] S3S4_addr_out;

integer i;
 //STAGE 3
always @(posedge clk)
begin
    if(pipe_en)
    begin
        for(i=0;i<CHANNELS;i=i+1)
        begin
            S3S4_T[i*8 +: 8] <=
            ((((1<<FRAC_BITS)-S2S3_a)*S2S3_I00[i*8 +: 8]) +
            (S2S3_a*S2S3_I10[i*8 +: 8])) >> FRAC_BITS;

            S3S4_B[i*8 +: 8] <=
            ((((1<<FRAC_BITS)-S2S3_a)*S2S3_I01[i*8 +: 8]) +
            (S2S3_a*S2S3_I11[i*8 +: 8])) >> FRAC_BITS;
        end

        S3S4_addr_out <= S2S3_addr_out;
        S3S4_b <= S2S3_b;
    end
end

reg [DATA_WIDTH-1:0] S4S5_Iout;
reg [ADDR_OUT_BITS-1:0] S4S5_addr_out;

//STAGE 3
always @(posedge clk)
begin
    if(pipe_en)
    begin
        for(i=0;i<CHANNELS;i=i+1)
        begin
            S4S5_Iout[i*8 +: 8] <=
            ((((1<<FRAC_BITS)-S3S4_b)*S3S4_T[i*8 +: 8]) +
            (S3S4_b*S3S4_B[i*8 +: 8])) >> FRAC_BITS;
        end

        S4S5_addr_out <= S3S4_addr_out;
    end
end

reg [3:0] valid_pipe;

//STAGE 4
always @(posedge clk)
begin
    if(pipe_en)
        valid_pipe <= {valid_pipe[2:0], state};
end

reg [DATA_WIDTH-1:0] output_mem [0:MEM_OUTPUT_SIZE-1];

//STAGE 5
always @(posedge clk)
begin
    if(pipe_en && valid_pipe[3])
        output_mem[S4S5_addr_out] <= S4S5_Iout;
end

endmodule
