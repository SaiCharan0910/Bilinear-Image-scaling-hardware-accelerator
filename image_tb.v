`timescale 1ns / 1ps

module tb_image_scale;

reg clk;
reg start;
wire done;

// DUT
image_scale dut(
    .clk(clk),
    .start(start),
    .done(done)
);


// CLOCK GENERATION (10ns period)
initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end


// START SIGNAL
initial
begin
    start = 0;

    #10
    start = 1;

    #10
    start = 0;
end


// MONITOR IMPORTANT SIGNALS
// initial
// begin
// $monitor(
// "time=%0t | X_out=%d Y_out=%d | X_in=%d Y_in=%d | a=%d b=%d | I00=%d I10=%d I01=%d I11=%d | T=%d B=%d | Iout=%d | valid_pipeline=%b |write_enable=%b |state=%b|scale_x=%d| X_in_calc=%d ",
// $time,
// dut.X_out,
// dut.Y_out,
// dut.S1S2_X_in,
// dut.S1S2_Y_in,
// dut.S2S3_a,
// dut.S2S3_b,
// dut.S2S3_I00,
// dut.S2S3_I10,
// dut.S2S3_I01,
// dut.S2S3_I11,
// dut.S3S4_T,
// dut.S3S4_B,
// dut.S4S5_Iout,
// dut.valid_pipe,
// dut.write_enable,
// dut.state,
// dut.scale_x,
// dut.X_in_calc
// );
// end


// STOP SIMULATION WHEN DONE
initial
begin
wait(done == 1);

$display("\nImage Scaling Finished at time %0t", $time);
$display("Output memory written to output.hex");

#20
$finish;
end

endmodule