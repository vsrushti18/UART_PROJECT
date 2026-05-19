module ref #(parameter XTAL_CLK = 50_000_000, WORD_LEN = 8, BAUD = 115200)(
        input sys_clk, sys_rst_1, xmitH,
        input [WORD_LEN-1:0] xmit_dataH,
        input uart_REC_dataH,
        output reg uart_XMIT_dataH, xmit_doneH, rec_readyH,
        output reg [WORD_LEN-1:0] rec_dataH,
        output reg rec_busy, xmit_active
);

        reg uart_clk;
        reg [31:0] clk_cnt;

        always @(posedge sys_clk or negedge sys_rst_1) begin
                if(!sys_rst_1) begin
                        uart_clk <= 0;
                        clk_cnt <= 0;
                end
                else begin
                        if(clk_cnt == (XTAL_CLK / (BAUD * 16 * 2)) ) begin
                                uart_clk <= ~uart_clk;
                                clk_cnt <= 0;
                        end
                        else begin
                                clk_cnt <= clk_cnt + 1;
                        end
                end
        end

        reg en;
        reg [3:0] en_cnt;

        always @(posedge uart_clk or negedge sys_rst_1) begin
                if(!sys_rst_1) begin
                        en <= 0;
                        en_cnt <= 0;
                end
                else begin
                        if(en_cnt == 15) begin
                                en <= 1;
                                en_cnt <= 0;
                        end
                        else begin
                                en_cnt <= en_cnt + 1;
                        end
                end
        end

	initial begin
		uart_XMIT_dataH = 1'b1;
		xmit_doneH = 1'b1;
		xmit_active = 1'b0;
		rec_dataH = 0;
		rec_readyH = 1'b1;
		rec_busy = 1'b0;
	end

        reg [WORD_LEN-1:0] data1;
        integer i,j;

        /*always @(posedge xmitH or negedge sys_rst_1) begin
		if(!sys_rst_1) begin
			uart_XMIT_dataH <= 1'b1;
			xmit_doneH <= 1'b1;
			xmit_active <= 1'b0;
			data1 <= 0;
		end else begin
                	data1 = xmit_dataH; xmit_active = 1; xmit_doneH = 0;
                	uart_XMIT_dataH = 0;
                	repeat(16) @(posedge uart_clk);
                	for(i = 0; i < WORD_LEN; i=i+1) begin
                        	uart_XMIT_dataH = data1[i];
                        	repeat(16) @(posedge uart_clk);
                	end
                	uart_XMIT_dataH = 1;
                	xmit_active = 0; xmit_doneH = 1;
        	end
	end
	*/
	
	always @(posedge xmitH or negedge sys_rst_1) begin
	    if(!sys_rst_1) begin
		uart_XMIT_dataH <= 1'b1;
		xmit_doneH      <= 1'b1;
		xmit_active     <= 1'b0;
		data1           <= 0;
	    end else begin
		data1 = xmit_dataH; xmit_active = 1; xmit_doneH = 0;
		uart_XMIT_dataH = 0;

		// repeat(16) ki jagah for loop
		for(i = 0; i < 16; i=i+1) begin
		    @(posedge uart_clk or negedge sys_rst_1);
		    if(!sys_rst_1) begin
		        uart_XMIT_dataH = 1; xmit_active = 0; xmit_doneH = 1;
		        i = 16; // loop se bahar
		    end
		end

		for(i = 0; i < WORD_LEN; i=i+1) begin
		    uart_XMIT_dataH = data1[i];
		    // repeat(16) ki jagah
		    
		    for(j = 0; j < 16; j=j+1) begin
		        @(posedge uart_clk or negedge sys_rst_1);
		        if(!sys_rst_1) begin
		            uart_XMIT_dataH = 1; xmit_active = 0; xmit_doneH = 1;
		            j = 16; i = WORD_LEN; // dono loops se bahar
		        end
		    end
		end

		if(sys_rst_1) begin  // reset nahi tha toh normal completion
		    uart_XMIT_dataH = 1;
		    xmit_active = 0; xmit_doneH = 1;
		end
	    end
	end

        reg prev_data,sync_data,data;

        always @(posedge uart_clk or negedge sys_rst_1) begin
                if(!sys_rst_1) begin
                        prev_data <= 1'b1;
                        sync_data <= 1'b1;
                        data <= 1'b1;
                end
                else begin
                        prev_data <= data;
                        sync_data <= uart_REC_dataH;
                        data <= sync_data;
                end
        end

        reg flag;

	always @(posedge uart_clk or negedge sys_rst_1) begin
		if(!sys_rst_1) begin
			rec_dataH <= 0; rec_readyH <= 1; rec_busy <= 0; flag <= 0;
			uart_XMIT_dataH = 1; xmit_active <= 0; xmit_doneH <= 1;
		end
	end

        always @(posedge uart_clk or negedge sys_rst_1) begin
                if(!sys_rst_1) begin
                        rec_dataH <= 0;
                        rec_readyH <= 1'b1;
                        rec_busy <= 1'b0;
			flag <= 1'b0;
                end
                else begin
                        if(prev_data && !data) begin
                                repeat(8) @(posedge uart_clk);
				/*for(i = 0; i < 8; i=i+1) begin
		    			@(posedge uart_clk or negedge sys_rst_1);
		    			if(!sys_rst_1) begin
		        			uart_XMIT_dataH = 1; xmit_active = 0; xmit_doneH = 1;
		        			i = 16; // loop se bahar
		    			end
				end*/
                                if(data == 0) flag = 1;
				else flag = 0;
                                repeat(8) @(posedge uart_clk);
                                if(data==0 && flag == 1) begin
                                        rec_readyH <= 1'b0; rec_busy <= 1'b1;
                                        repeat(8) @(posedge uart_clk);
                                        rec_dataH <= {data,rec_dataH[7:1]};
                                        for(i=1;i<WORD_LEN;i=i+1) begin
                                                repeat(16) @(posedge uart_clk);
                                                rec_dataH <= {data,rec_dataH[7:1]};
                                        end
                                        repeat(16) @(posedge uart_clk);
                                        if(data == 0) begin
                                                rec_dataH <= 0;
                                        end
                                        rec_readyH <= 1'b1;
                                        rec_busy <= 1'b0;
                                end
                        end
                end
        end

endmodule
