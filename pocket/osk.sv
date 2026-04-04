//============================================================================
//  On-Screen Keyboard — Reusable overlay module
//  QWERTY layout, 4 rows, d-pad navigation, button selection
//  Parameterized for any screen resolution.
//
//  Copyright (C) 2026 Eric Lewis — GPL-3.0-or-later
//============================================================================
`default_nettype none

module osk #(
    parameter H_ACTIVE = 320,
    parameter V_ACTIVE = 240,
    parameter KEY_W    = 24,    // key cell width in pixels
    parameter KEY_H    = 16,    // key cell height in pixels
    parameter ROWS     = 4,
    parameter MAX_COLS = 13
) (
    input  wire        clk,
    input  wire        reset_n,

    // Controller input
    input  wire [15:0] keys,       // cont1_key[15:0]
    input  wire        toggle_in,  // external toggle signal (L+R combo)

    // Status
    output reg         osk_active = 0,

    // Character output
    output reg  [7:0]  osk_char,
    output reg         osk_char_valid,
    output reg         osk_backspace,
    output reg         osk_enter,

    // Video overlay
    input  wire [9:0]  h_cnt,
    input  wire [9:0]  v_cnt,
    input  wire [23:0] rgb_in,
    output wire [23:0] rgb_out,

    // Font ROM access (directly read)
    output wire [9:0]  osk_font_addr,
    input  wire [7:0]  osk_font_data
);

// ======== Key Layout ========
// 4 rows of ASCII characters. Stored as a flat array.
// Row 0: 1 2 3 4 5 6 7 8 9 0 - = (12 keys)
// Row 1: Q W E R T Y U I O P [ ] (12 keys)
// Row 2: A S D F G H J K L ; ' RET (12 keys, RET = enter)
// Row 3: Z X C V B N M , . / SPC (11 keys, SPC = space)

// Normal (unshifted) characters
wire [7:0] key_char_normal [0:ROWS*MAX_COLS-1];

// Row 0
assign key_char_normal[0]  = "1"; assign key_char_normal[1]  = "2";
assign key_char_normal[2]  = "3"; assign key_char_normal[3]  = "4";
assign key_char_normal[4]  = "5"; assign key_char_normal[5]  = "6";
assign key_char_normal[6]  = "7"; assign key_char_normal[7]  = "8";
assign key_char_normal[8]  = "9"; assign key_char_normal[9]  = "0";
assign key_char_normal[10] = "-"; assign key_char_normal[11] = "=";
assign key_char_normal[12] = 8'h08; // Backspace
// Row 1
assign key_char_normal[13] = "q"; assign key_char_normal[14] = "w";
assign key_char_normal[15] = "e"; assign key_char_normal[16] = "r";
assign key_char_normal[17] = "t"; assign key_char_normal[18] = "y";
assign key_char_normal[19] = "u"; assign key_char_normal[20] = "i";
assign key_char_normal[21] = "o"; assign key_char_normal[22] = "p";
assign key_char_normal[23] = "["; assign key_char_normal[24] = "]";
assign key_char_normal[25] = 8'h5C; // backslash
// Row 2
assign key_char_normal[26] = "a"; assign key_char_normal[27] = "s";
assign key_char_normal[28] = "d"; assign key_char_normal[29] = "f";
assign key_char_normal[30] = "g"; assign key_char_normal[31] = "h";
assign key_char_normal[32] = "j"; assign key_char_normal[33] = "k";
assign key_char_normal[34] = "l"; assign key_char_normal[35] = ";";
assign key_char_normal[36] = "'"; assign key_char_normal[37] = 8'h0D; // Return
assign key_char_normal[38] = 8'h00; // padding
// Row 3
assign key_char_normal[39] = "z"; assign key_char_normal[40] = "x";
assign key_char_normal[41] = "c"; assign key_char_normal[42] = "v";
assign key_char_normal[43] = "b"; assign key_char_normal[44] = "n";
assign key_char_normal[45] = "m"; assign key_char_normal[46] = ",";
assign key_char_normal[47] = "."; assign key_char_normal[48] = "/";
assign key_char_normal[49] = " "; // Space
assign key_char_normal[50] = 8'h00;
assign key_char_normal[51] = 8'h00;

// Shifted characters
wire [7:0] key_char_shifted [0:ROWS*MAX_COLS-1];
assign key_char_shifted[0]  = "!"; assign key_char_shifted[1]  = "@";
assign key_char_shifted[2]  = "#"; assign key_char_shifted[3]  = "$";
assign key_char_shifted[4]  = "%"; assign key_char_shifted[5]  = "^";
assign key_char_shifted[6]  = "&"; assign key_char_shifted[7]  = "*";
assign key_char_shifted[8]  = "("; assign key_char_shifted[9]  = ")";
assign key_char_shifted[10] = "_"; assign key_char_shifted[11] = "+";
assign key_char_shifted[12] = 8'h08;
assign key_char_shifted[13] = "Q"; assign key_char_shifted[14] = "W";
assign key_char_shifted[15] = "E"; assign key_char_shifted[16] = "R";
assign key_char_shifted[17] = "T"; assign key_char_shifted[18] = "Y";
assign key_char_shifted[19] = "U"; assign key_char_shifted[20] = "I";
assign key_char_shifted[21] = "O"; assign key_char_shifted[22] = "P";
assign key_char_shifted[23] = "{"; assign key_char_shifted[24] = "}";
assign key_char_shifted[25] = "|";
assign key_char_shifted[26] = "A"; assign key_char_shifted[27] = "S";
assign key_char_shifted[28] = "D"; assign key_char_shifted[29] = "F";
assign key_char_shifted[30] = "G"; assign key_char_shifted[31] = "H";
assign key_char_shifted[32] = "J"; assign key_char_shifted[33] = "K";
assign key_char_shifted[34] = "L"; assign key_char_shifted[35] = ":";
assign key_char_shifted[36] = 8'h22; assign key_char_shifted[37] = 8'h0D; // double-quote
assign key_char_shifted[38] = 8'h00;
assign key_char_shifted[39] = "Z"; assign key_char_shifted[40] = "X";
assign key_char_shifted[41] = "C"; assign key_char_shifted[42] = "V";
assign key_char_shifted[43] = "B"; assign key_char_shifted[44] = "N";
assign key_char_shifted[45] = "M"; assign key_char_shifted[46] = "<";
assign key_char_shifted[47] = ">"; assign key_char_shifted[48] = "?";
assign key_char_shifted[49] = " ";
assign key_char_shifted[50] = 8'h00;
assign key_char_shifted[51] = 8'h00;

// Number of keys per row
wire [3:0] row_len [0:3];
assign row_len[0] = 13;
assign row_len[1] = 13;
assign row_len[2] = 13;
assign row_len[3] = 11;

// Display character for each key (for rendering label)
wire [7:0] display_char;
wire [5:0] key_idx = sel_row * MAX_COLS + sel_col;
assign display_char = shifted ? key_char_shifted[key_idx] : key_char_normal[key_idx];

// ======== Selection State ========
reg [1:0] sel_row = 0;
reg [3:0] sel_col = 0;
reg       shifted = 0;
reg [15:0] prev_keys;
wire [15:0] key_press = keys & ~prev_keys;

// Navigation throttle
reg [17:0] nav_timer = 0;
reg        nav_ready;

always @(posedge clk) begin
    nav_timer <= nav_timer + 1'd1;
    nav_ready <= (nav_timer == 0);
end

// Toggle
reg prev_toggle;
always @(posedge clk) begin
    prev_toggle <= toggle_in;
    if (toggle_in & ~prev_toggle)
        osk_active <= ~osk_active;
end

// ======== Input Handling ========
always @(posedge clk) begin
    prev_keys <= keys;
    osk_char_valid <= 0;
    osk_backspace  <= 0;
    osk_enter      <= 0;

    if (!reset_n) begin
        sel_row <= 0;
        sel_col <= 0;
        shifted <= 0;
        osk_active <= 0;
    end
    else if (osk_active) begin
        // Navigation
        if (nav_ready) begin
            if (keys[0] && sel_row > 0) sel_row <= sel_row - 1'd1;           // Up
            if (keys[1] && sel_row < ROWS-1) sel_row <= sel_row + 1'd1;      // Down
            if (keys[2] && sel_col > 0) sel_col <= sel_col - 1'd1;           // Left
            if (keys[3] && sel_col < row_len[sel_row]-1) sel_col <= sel_col + 1'd1; // Right
        end

        // Clamp column to row length
        if (sel_col >= row_len[sel_row])
            sel_col <= row_len[sel_row] - 1'd1;

        // Select (A button)
        if (key_press[4]) begin
            osk_char <= shifted ? key_char_shifted[sel_row * MAX_COLS + sel_col]
                                : key_char_normal[sel_row * MAX_COLS + sel_col];
            if (osk_char == 8'h08)
                osk_backspace <= 1;
            else if (osk_char == 8'h0D)
                osk_enter <= 1;
            else
                osk_char_valid <= 1;
        end

        // Backspace (B button)
        if (key_press[5]) osk_backspace <= 1;

        // Enter (X button)
        if (key_press[6]) osk_enter <= 1;

        // Shift toggle (L+R shoulders: bits 8 and 9)
        if (keys[8] & keys[9] & ~(prev_keys[8] & prev_keys[9]))
            shifted <= ~shifted;
    end
end

// ======== Video Rendering ========
// OSK occupies bottom KEY_H*4 = 64 pixels of screen
localparam OSK_Y_START = V_ACTIVE - KEY_H * ROWS; // 176 for 240 high
localparam OSK_X_START = (H_ACTIVE - KEY_W * MAX_COLS) / 2; // centered

wire in_osk_area = osk_active &&
                   (v_cnt >= OSK_Y_START) && (v_cnt < V_ACTIVE) &&
                   (h_cnt >= OSK_X_START) && (h_cnt < OSK_X_START + KEY_W * MAX_COLS);

// Which key cell are we in?
wire [3:0] render_col = (h_cnt - OSK_X_START) / KEY_W;
wire [1:0] render_row = (v_cnt - OSK_Y_START) / KEY_H;
wire [4:0] px_in_key  = (h_cnt - OSK_X_START) % KEY_W;  // 0..KEY_W-1
wire [3:0] py_in_key  = (v_cnt - OSK_Y_START) % KEY_H;  // 0..KEY_H-1

// Is this the selected key?
wire is_selected = (render_row == sel_row) && (render_col == sel_col);

// Font rendering: center the 8x8 char in the KEY_W x KEY_H cell
wire in_char_area = (px_in_key >= (KEY_W-8)/2) && (px_in_key < (KEY_W+8)/2) &&
                    (py_in_key >= (KEY_H-8)/2) && (py_in_key < (KEY_H+8)/2);
wire [2:0] char_px = px_in_key - (KEY_W-8)/2;
wire [2:0] char_py = py_in_key - (KEY_H-8)/2;

// Get the character for current render cell
wire [5:0] render_key_idx = render_row * MAX_COLS + render_col;
wire [7:0] render_char = shifted ? key_char_shifted[render_key_idx]
                                 : key_char_normal[render_key_idx];
// Map special chars to display glyphs
wire [6:0] glyph = (render_char == 8'h08) ? 7'h11 :  // ← arrow for BS
                   (render_char == 8'h0D) ? 7'h11 :  // ← arrow for RET
                   (render_char == " ")   ? 7'h5F :  // _ for SPC
                   render_char[6:0];

assign osk_font_addr = {glyph, char_py};

wire font_px = osk_font_data[7 - char_px];

// Is the current pixel within a valid key?
wire valid_key = (render_col < row_len[render_row]);

// Color
wire [23:0] key_bg  = is_selected ? 24'h334488 : 24'h111122;
wire [23:0] key_fg  = is_selected ? 24'hFFFFFF : 24'hAABBCC;
wire [23:0] osk_px  = (in_char_area && font_px && valid_key) ? key_fg : key_bg;

// Composite: OSK overlay or passthrough
assign rgb_out = (in_osk_area && valid_key) ? osk_px : rgb_in;

endmodule
