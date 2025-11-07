`include "common.vh"

module MyDesign(
  // System signals
  input wire reset_n,  
  input wire clk,

  // Control signals
  input wire dut_valid, 
  output wire dut_ready,

  // Input SRAM interface
  output wire dut__tb__sram_input_write_enable,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_input_write_address,
  output wire [`SRAM_DATA_RANGE] dut__tb__sram_input_write_data,
  output reg [`SRAM_ADDR_RANGE] dut__tb__sram_input_read_address, 
  input wire [`SRAM_DATA_RANGE] tb__dut__sram_input_read_data,     

  // Weight SRAM interface
  output wire dut__tb__sram_weight_write_enable,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_weight_write_address,
  output wire [`SRAM_DATA_RANGE] dut__tb__sram_weight_write_data,
  output reg [`SRAM_ADDR_RANGE] dut__tb__sram_weight_read_address, 
  input wire [`SRAM_DATA_RANGE] tb__dut__sram_weight_read_data,     

  // Result SRAM interface
  output logic dut__tb__sram_result_write_enable,
  output logic [`SRAM_ADDR_RANGE] dut__tb__sram_result_write_address,
  output logic [`SRAM_DATA_RANGE] dut__tb__sram_result_write_data,
  output logic [`SRAM_ADDR_RANGE] dut__tb__sram_result_read_address, 
  input logic [`SRAM_DATA_RANGE] tb__dut__sram_result_read_data,

  // Scratchpad SRAM interface
  output logic  dut__tb__sram_scratchpad_write_enable ,
  output logic  [`SRAM_ADDR_RANGE    ]  dut__tb__sram_scratchpad_write_address ,
  output logic  [`SRAM_DATA_RANGE    ]  dut__tb__sram_scratchpad_write_data    ,
  output logic  [`SRAM_ADDR_RANGE    ]  dut__tb__sram_scratchpad_read_address  , 
  input  logic  [`SRAM_DATA_RANGE    ]  tb__dut__sram_scratchpad_read_data     
);

typedef enum logic [3:0] {
  IDLE = 4'd0,
  READ_DIMENSIONS = 4'd1,
  QUERY_MULTIPLY = 4'd2,
  WRITE_Q_RESULT = 4'd3,
  KEY_MULTIPLY = 4'd4,
  WRITE_K_RESULT = 4'd5,
  VALUE_MULTIPLY = 4'd6,
  WRITE_V_RESULT = 4'd7,
  QKV_COMPLETE = 4'd8,
  SCORE_MATRIX = 4'd9,
  WRITE_SCORE_RESULT = 4'd10,
  SCORE_MATRIX_COMPLETE = 4'd11,
  ATTENTION_MATRIX = 4'd12,
  WRITE_ATTENTION_MATRIX = 4'd13,
  ATTENTION_MATRIX_COMPLETE = 4'd14
} state_t;

state_t current_state, next_state;
reg [`SRAM_DATA_RANGE] multiply_accum;
reg [`SRAM_ADDR_RANGE] A_row_counter, B_column_counter, element_counter;
reg [`SRAM_ADDR_RANGE] A_rows, A_cols, B_rows, B_cols;
reg dut_ready_r;

// Output ready flag
assign dut_ready = dut_ready_r;

// Fixed Address Base Definitions
localparam A_BASE_ADDR = 12'h01;  
localparam B_BASE_ADDR = 12'h01;

// Write Enables for A and B SRAMs always zero
assign dut__tb__sram_input_write_enable = 1'b0;
assign dut__tb__sram_weight_write_enable = 1'b0;

// State transitions
always @(posedge clk or negedge reset_n) begin
  if (!reset_n) 
    current_state <= IDLE;
  else 
    current_state <= next_state;
end

always @(*) begin
  case (current_state)
    IDLE: next_state = dut_valid ? READ_DIMENSIONS : IDLE;
    READ_DIMENSIONS: next_state = QUERY_MULTIPLY;
    QUERY_MULTIPLY: next_state = (element_counter > A_cols) ? WRITE_Q_RESULT : QUERY_MULTIPLY;
    WRITE_Q_RESULT: next_state = KEY_MULTIPLY;
    KEY_MULTIPLY: next_state = (element_counter > A_cols) ? WRITE_K_RESULT : KEY_MULTIPLY;
    WRITE_K_RESULT: next_state = VALUE_MULTIPLY;
    VALUE_MULTIPLY: next_state = (element_counter > A_cols) ? WRITE_V_RESULT : VALUE_MULTIPLY;
    WRITE_V_RESULT: next_state = QKV_COMPLETE;
    QKV_COMPLETE: next_state = (A_row_counter == A_rows - 1 && B_column_counter == B_cols - 1) ? SCORE_MATRIX: QUERY_MULTIPLY;
    SCORE_MATRIX: next_state = (element_counter > B_cols) ? WRITE_SCORE_RESULT : SCORE_MATRIX;
    WRITE_SCORE_RESULT: next_state = SCORE_MATRIX_COMPLETE;
    SCORE_MATRIX_COMPLETE : next_state = (A_row_counter == A_rows - 1 && B_column_counter == A_rows - 1) ? ATTENTION_MATRIX : SCORE_MATRIX;
    ATTENTION_MATRIX: next_state = (element_counter > A_rows) ? WRITE_ATTENTION_MATRIX : ATTENTION_MATRIX;
    WRITE_ATTENTION_MATRIX: next_state = ATTENTION_MATRIX_COMPLETE;
    ATTENTION_MATRIX_COMPLETE: next_state = (A_row_counter == A_rows - 1 && B_column_counter == B_cols - 1) ? IDLE : ATTENTION_MATRIX;
    default: next_state = IDLE;
  endcase
end

/*********************************************************************************************************************
Input matrix : Arows, Acols  & Weight matrix : Brows, Bcols
-----------------------------------------------------------
result rows = Arows , result cols = Bcols
scratchpad rows = Bcols, scratchpad cols = Arows
score rows = Arows , score cols = Arows 
v rows = Arows, v cols = Bcols

**********************************************************************************************************************/
// FSM Operation Logic
always @(posedge clk or negedge reset_n) begin
  if (!reset_n) begin
    dut__tb__sram_input_read_address <= 0;
    dut__tb__sram_weight_read_address <= 0;
    dut__tb__sram_result_write_enable <= 0;
    dut__tb__sram_scratchpad_write_enable <= 0;
    A_row_counter <= 0;
    B_column_counter <= 0;
    element_counter <= 0;
    multiply_accum <= 0;
    dut_ready_r <= 1'b1;  // Set `dut_ready` high on reset to indicate readiness in IDLE
  end else begin
    case (current_state)
      IDLE: begin
        if (dut_valid) begin
          dut_ready_r <= 1'b0;  // Clear `dut_ready` when starting computation
        end else begin
          dut_ready_r <= 1'b1;  // Keep `dut_ready` high in IDLE until `dut_valid` is asserted
        end
      end

      READ_DIMENSIONS: begin
        A_rows <= tb__dut__sram_input_read_data[31:16];
        A_cols <= tb__dut__sram_input_read_data[15:0];
        B_rows <= tb__dut__sram_weight_read_data[31:16];
        B_cols <= tb__dut__sram_weight_read_data[15:0];
        element_counter <= 0; // Reset element counter
      end

      QUERY_MULTIPLY: begin  
        // Set both input and weight addresses
        dut__tb__sram_input_read_address <= A_BASE_ADDR + A_row_counter * A_cols + element_counter;
        dut__tb__sram_weight_read_address <= B_BASE_ADDR + B_column_counter * B_rows + element_counter;
        multiply_accum <= (element_counter == 1) ? 0 : tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data + multiply_accum;
        element_counter <= element_counter + 1;
       end

      WRITE_Q_RESULT: begin
        dut__tb__sram_result_write_enable <= 1;
        dut__tb__sram_result_write_address <=  A_row_counter * B_cols + B_column_counter;
        dut__tb__sram_result_write_data <= multiply_accum;

        multiply_accum <= 0;
        element_counter <= 0;
      end

      KEY_MULTIPLY: begin  
        dut__tb__sram_result_write_enable <= 0;
        dut__tb__sram_input_read_address <= A_BASE_ADDR + A_row_counter * A_cols + element_counter;
        dut__tb__sram_weight_read_address <= B_BASE_ADDR + (B_rows*B_cols) + B_column_counter * B_rows + element_counter;
        multiply_accum <= (element_counter == 1) ? 0 : tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data + multiply_accum;
        element_counter <= element_counter + 1;
       end

      WRITE_K_RESULT: begin
        dut__tb__sram_result_write_enable <= 1;
        dut__tb__sram_scratchpad_write_enable <= 1;
        dut__tb__sram_result_write_address  <= A_rows*B_cols + A_row_counter * B_cols + B_column_counter;
        dut__tb__sram_scratchpad_write_address <= A_row_counter * B_cols + B_column_counter; 
        dut__tb__sram_result_write_data <= multiply_accum;
        dut__tb__sram_scratchpad_write_data <= multiply_accum;
        // Reset multiply_accum and element_counter after writing result
        multiply_accum <= 0;
        element_counter <= 0;
      end

      VALUE_MULTIPLY: begin 
        dut__tb__sram_result_write_enable <= 0; 
        dut__tb__sram_scratchpad_write_enable <= 0;
        // Set both input and weight addresses
        dut__tb__sram_input_read_address <= A_BASE_ADDR + A_row_counter * A_cols + element_counter;
        dut__tb__sram_weight_read_address <= B_BASE_ADDR + 2*B_rows*B_cols + B_column_counter * B_rows + element_counter;
        multiply_accum <= (element_counter == 1) ? 0 : tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data + multiply_accum;
        element_counter <= element_counter + 1;
       end

        WRITE_V_RESULT: begin
        dut__tb__sram_result_write_enable <= 1;
        dut__tb__sram_scratchpad_write_enable <= 1;
        dut__tb__sram_result_write_address <= 2*A_rows*B_cols + A_row_counter * B_cols + B_column_counter;
        //dut__tb__sram_scratchpad_write_address <= A_rows*B_cols + A_row_counter * B_cols + B_column_counter;
        dut__tb__sram_scratchpad_write_address <= A_rows*B_cols + A_row_counter + B_column_counter * A_rows; //write in non-sequential way 
        dut__tb__sram_result_write_data <= multiply_accum;  
        dut__tb__sram_scratchpad_write_data <= multiply_accum;
        // Reset multiply_accum and element_counter after writing result
        multiply_accum <= 0;
        element_counter <= 0;
      end

      QKV_COMPLETE: begin
        dut__tb__sram_result_write_enable <= 0;
        dut__tb__sram_scratchpad_write_enable <= 0;
        if (B_column_counter < B_cols - 1) begin
          B_column_counter <= B_column_counter + 1;
        end else if (A_row_counter < A_rows - 1) begin
          A_row_counter <= A_row_counter + 1;
          B_column_counter <= 0;
        end else begin
          dut__tb__sram_input_read_address <= 0;
          dut__tb__sram_weight_read_address <= 0;
          A_row_counter <= 0;
          B_column_counter <= 0;
          element_counter <= 0;
          //dut_ready_r <= 1'b1;  // Set `dut_ready` high in IDLE after computation completes
        end
        // 
      end

      SCORE_MATRIX: begin
        // Set both input and weight addresses
        dut__tb__sram_result_read_address <=  A_row_counter * B_cols + element_counter;
        dut__tb__sram_scratchpad_read_address <=  B_column_counter * B_cols+ element_counter;
        multiply_accum <= (element_counter == 1) ? 0 : tb__dut__sram_scratchpad_read_data * tb__dut__sram_result_read_data + multiply_accum;
        element_counter <= element_counter + 1;
      end

      WRITE_SCORE_RESULT: begin
        dut__tb__sram_result_write_enable <= 1;
        dut__tb__sram_result_write_address <= 3*A_rows*B_cols + A_row_counter * A_rows + B_column_counter;
        dut__tb__sram_result_write_data <= multiply_accum;

        multiply_accum <= 0;
        element_counter <= 0;
      end

      SCORE_MATRIX_COMPLETE: begin
        dut__tb__sram_result_write_enable <= 0;
        if (B_column_counter < A_rows - 1) begin
          B_column_counter <= B_column_counter + 1;
        end else if (A_row_counter < A_rows - 1) begin
          A_row_counter <= A_row_counter + 1;
          B_column_counter <= 0;
        end else begin
          dut__tb__sram_result_read_address <= 0;
          dut__tb__sram_scratchpad_read_address <= 0;
          element_counter <= 0;
          A_row_counter <= 0;
          B_column_counter <= 0;
        end 
      end

      ATTENTION_MATRIX: begin 
        // Set both input and weight addresses
        dut__tb__sram_result_read_address <= 3*A_rows*B_cols + A_row_counter * A_rows + element_counter;
        dut__tb__sram_scratchpad_read_address <= B_cols*A_rows + B_column_counter * A_rows + element_counter;
        multiply_accum <= (element_counter == 1) ? 0 : tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data + multiply_accum;
        element_counter <= element_counter + 1;
       end

      WRITE_ATTENTION_MATRIX: begin
        dut__tb__sram_result_write_enable <= 1;
        dut__tb__sram_result_write_address <= 3*A_rows*B_cols + A_rows*A_rows + A_row_counter * B_cols + B_column_counter;
        dut__tb__sram_result_write_data <= multiply_accum;
        // Reset multiply_accum and element_counter after writing result
        multiply_accum <= 0;
        element_counter <= 0;
      end

      ATTENTION_MATRIX_COMPLETE: begin
        dut__tb__sram_result_write_enable <= 0;
        if (B_column_counter < B_cols - 1) begin
          B_column_counter <= B_column_counter + 1;
        end else if (A_row_counter < A_rows - 1) begin
          A_row_counter <= A_row_counter + 1;
          B_column_counter <= 0;
        end else begin
          dut__tb__sram_result_read_address <= 0;
          dut__tb__sram_scratchpad_read_address <= 0;
          element_counter <= 0;
          A_row_counter <= 0;
          B_column_counter <= 0;
          dut_ready_r <= 1'b1;  // Set `dut_ready` high in IDLE after computation completes
        end
      end
    endcase
  end
end
endmodule
