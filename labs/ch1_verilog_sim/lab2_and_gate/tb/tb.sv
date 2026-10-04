
module tb;
    logic a, b;
    logic y;
    int   errors = 0;

    and_gate uut (.a(a), .b(b), .y(y));

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, tb);

        for (int i = 0; i < 4; i++) begin
            {a, b} = i[1:0];
            #10;
            if (y !== (a & b)) begin
                $display("FAIL: a=%b b=%b y=%b expected=%b", a, b, y, a & b);
                errors++;
            end
        end

        if (errors == 0) $display("PASS: all 4 input combinations OK");
        else             $fatal(1, "FAILED: %0d error(s)", errors);
        $finish;
    end
endmodule
