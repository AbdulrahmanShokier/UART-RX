module FSM (
    input  wire       asy_reset,
    input  wire       clk_based_on_prescale,
    input  wire       RX_IN,
    input  wire       parity_enable,
    input  wire       parity_error,
    input  wire       start_glitch,
    input  wire       stop_error,
    input  wire [3:0] edge_count,
    input  wire [4:0] bit_count,
    output reg        Deserializer_enable,
    output reg        data_valid,
    output reg        parity_check_enable,
    output reg        data_sampler_enable,
    output reg        start_check_enable,
    output reg        stop_check_enable,
    output reg        edge_bit_enable,

    // Debug outputs
    output reg [2:0] current_state, // Added for debug
    output reg [2:0] next_state     // Added for debug
);

  // FSM states
  localparam IDLE        = 3'b000,
             START_CHECK = 3'b001,
             DATA        = 3'b010,
             PARITY      = 3'b011,
             STOP        = 3'b100;

  // State register
  always @(posedge clk_based_on_prescale or negedge asy_reset) begin
    if (!asy_reset)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end

  // Next state logic
  always @(*) begin
    // Default
    next_state = current_state;

    case (current_state)
      IDLE: begin
        if (RX_IN == 0)
          next_state = START_CHECK;
      end

      START_CHECK: begin
        if (start_glitch)
          next_state = IDLE;
        else
          next_state = DATA;
      end

      DATA: begin
        if (bit_count == 8)
          if (parity_enable)
            next_state = PARITY;
          else
            next_state = STOP;
      end

      PARITY: begin
        if (parity_error)
          next_state = IDLE;
        else
          next_state = STOP;
      end

      STOP: begin
        if (stop_error)
          next_state = IDLE;
        else
          next_state = IDLE; // and raise data_valid
      end
    endcase
  end

  // Outputs logic
  always @(*) begin
    // Default values
    Deserializer_enable   = 0;
    data_valid            = 0;
    parity_check_enable   = 0;
    data_sampler_enable   = 0;
    start_check_enable    = 0;
    stop_check_enable     = 0;
    edge_bit_enable       = 0;

    case (current_state)
      START_CHECK: begin
        start_check_enable = 1;
      end
      DATA: begin
        Deserializer_enable = 1;
        data_sampler_enable = 1;
        edge_bit_enable     = 1;
      end
      PARITY: begin
        parity_check_enable = 1;
      end
      STOP: begin
        stop_check_enable = 1;
        if (!stop_error) 
          data_valid = 1;
      end
    endcase
  end

endmodule
