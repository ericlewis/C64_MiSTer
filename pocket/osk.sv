//============================================================================
//  On-Screen Keyboard — Reusable overlay module
//  5-row QWERTY layout with special keys, d-pad navigation
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
    parameter ROWS     = 5,
    parameter MAX_COLS = 14
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

    // Font ROM access
    output wire [9:0]  osk_font_addr,
    input  wire [7:0]  osk_font_data
);

// ======== Key Layout — 5 rows ========
// Row 0: ESC ` 1 2 3 4 5 6 7 8 9 0 - =       (14 keys)
// Row 1: TAB q w e r t y u i o p [ ] BS       (14 keys)
// Row 2:     a s d f g h j k l ; ' \ RET      (13 keys)
// Row 3:     z x c v b n m , . / ! @          (12 keys)
// Row 4:     SPACE   ~  #  $  %  ^  &  *  ( ) (11 keys)

wire [7:0] key_char_normal [0:ROWS*MAX_COLS-1];
wire [7:0] key_char_shifted [0:ROWS*MAX_COLS-1];

// Row 0: number row + special
assign key_char_normal[ 0] = 8'h1B; // ESC
assign key_char_normal[ 1] = "`";
assign key_char_normal[ 2] = "1"; assign key_char_normal[ 3] = "2";
assign key_char_normal[ 4] = "3"; assign key_char_normal[ 5] = "4";
assign key_char_normal[ 6] = "5"; assign key_char_normal[ 7] = "6";
assign key_char_normal[ 8] = "7"; assign key_char_normal[ 9] = "8";
assign key_char_normal[10] = "9"; assign key_char_normal[11] = "0";
assign key_char_normal[12] = "-"; assign key_char_normal[13] = "=";

// Row 1: top letter row + BS
assign key_char_normal[14] = 8'h09; // TAB
assign key_char_normal[15] = "q"; assign key_char_normal[16] = "w";
assign key_char_normal[17] = "e"; assign key_char_normal[18] = "r";
assign key_char_normal[19] = "t"; assign key_char_normal[20] = "y";
assign key_char_normal[21] = "u"; assign key_char_normal[22] = "i";
assign key_char_normal[23] = "o"; assign key_char_normal[24] = "p";
assign key_char_normal[25] = "["; assign key_char_normal[26] = "]";
assign key_char_normal[27] = 8'h08; // Backspace

// Row 2: home row + RET
assign key_char_normal[28] = "a"; assign key_char_normal[29] = "s";
assign key_char_normal[30] = "d"; assign key_char_normal[31] = "f";
assign key_char_normal[32] = "g"; assign key_char_normal[33] = "h";
assign key_char_normal[34] = "j"; assign key_char_normal[35] = "k";
assign key_char_normal[36] = "l"; assign key_char_normal[37] = ";";
assign key_char_normal[38] = "'"; assign key_char_normal[39] = 8'h5C; // backslash
assign key_char_normal[40] = 8'h0D; // Return
assign key_char_normal[41] = 8'h00; // padding

// Row 3: bottom letter row + symbols
assign key_char_normal[42] = "z"; assign key_char_normal[43] = "x";
assign key_char_normal[44] = "c"; assign key_char_normal[45] = "v";
assign key_char_normal[46] = "b"; assign key_char_normal[47] = "n";
assign key_char_normal[48] = "m"; assign key_char_normal[49] = ",";
assign key_char_normal[50] = "."; assign key_char_normal[51] = "/";
assign key_char_normal[52] = "!"; assign key_char_normal[53] = "@";
assign key_char_normal[54] = 8'h00; assign key_char_normal[55] = 8'h00;

// Row 4: space bar + extra symbols
assign key_char_normal[56] = " ";  // SPACE
assign key_char_normal[57] = " ";  // SPACE (wide key)
assign key_char_normal[58] = " ";  // SPACE (wide key)
assign key_char_normal[59] = "~";
assign key_char_normal[60] = "#";
assign key_char_normal[61] = "$";
assign key_char_normal[62] = "%";
assign key_char_normal[63] = "^";
assign key_char_normal[64] = "&";
assign key_char_normal[65] = "*";
assign key_char_normal[66] = "(";
assign key_char_normal[67] = ")";
assign key_char_normal[68] = 8'h00; assign key_char_normal[69] = 8'h00;

// Shifted = uppercase + shifted symbols
// Row 0 shifted
assign key_char_shifted[ 0] = 8'h1B; // ESC
assign key_char_shifted[ 1] = "~";
assign key_char_shifted[ 2] = "!"; assign key_char_shifted[ 3] = "@";
assign key_char_shifted[ 4] = "#"; assign key_char_shifted[ 5] = "$";
assign key_char_shifted[ 6] = "%"; assign key_char_shifted[ 7] = "^";
assign key_char_shifted[ 8] = "&"; assign key_char_shifted[ 9] = "*";
assign key_char_shifted[10] = "("; assign key_char_shifted[11] = ")";
assign key_char_shifted[12] = "_"; assign key_char_shifted[13] = "+";
// Row 1 shifted
assign key_char_shifted[14] = 8'h09;
assign key_char_shifted[15] = "Q"; assign key_char_shifted[16] = "W";
assign key_char_shifted[17] = "E"; assign key_char_shifted[18] = "R";
assign key_char_shifted[19] = "T"; assign key_char_shifted[20] = "Y";
assign key_char_shifted[21] = "U"; assign key_char_shifted[22] = "I";
assign key_char_shifted[23] = "O"; assign key_char_shifted[24] = "P";
assign key_char_shifted[25] = "{"; assign key_char_shifted[26] = "}";
assign key_char_shifted[27] = 8'h08;
// Row 2 shifted
assign key_char_shifted[28] = "A"; assign key_char_shifted[29] = "S";
assign key_char_shifted[30] = "D"; assign key_char_shifted[31] = "F";
assign key_char_shifted[32] = "G"; assign key_char_shifted[33] = "H";
assign key_char_shifted[34] = "J"; assign key_char_shifted[35] = "K";
assign key_char_shifted[36] = "L"; assign key_char_shifted[37] = ":";
assign key_char_shifted[38] = 8'h22; assign key_char_shifted[39] = "|"; // double-quote, pipe
assign key_char_shifted[40] = 8'h0D;
assign key_char_shifted[41] = 8'h00;
// Row 3 shifted
assign key_char_shifted[42] = "Z"; assign key_char_shifted[43] = "X";
assign key_char_shifted[44] = "C"; assign key_char_shifted[45] = "V";
assign key_char_shifted[46] = "B"; assign key_char_shifted[47] = "N";
assign key_char_shifted[48] = "M"; assign key_char_shifted[49] = "<";
assign key_char_shifted[50] = ">"; assign key_char_shifted[51] = "?";
assign key_char_shifted[52] = "!"; assign key_char_shifted[53] = "@";
assign key_char_shifted[54] = 8'h00; assign key_char_shifted[55] = 8'h00;
// Row 4 shifted (same as normal)
assign key_char_shifted[56] = " ";
assign key_char_shifted[57] = " ";
assign key_char_shifted[58] = " ";
assign key_char_shifted[59] = "~";
assign key_char_shifted[60] = "#";
assign key_char_shifted[61] = "$";
assign key_char_shifted[62] = "%";
assign key_char_shifted[63] = "^";
assign key_char_shifted[64] = "&";
assign key_char_shifted[65] = "*";
assign key_char_shifted[66] = "(";
assign key_char_shifted[67] = ")";
assign key_char_shifted[68] = 8'h00; assign key_char_shifted[69] = 8'h00;

// Number of valid keys per row
wire [3:0] row_len [0:ROWS-1];
assign row_len[0] = 14;
assign row_len[1] = 14;
assign row_len[2] = 13;
assign row_len[3] = 12;
assign row_len[4] = 12;

// ======== Selection State ========
reg [2:0] sel_row = 0;
reg [3:0] sel_col = 0;
reg       shifted = 0;
reg [15:0] prev_keys;
wire [15:0] key_press = keys & ~prev_keys;

// Navigation: instant on first press, then repeat at ~8 Hz while held
reg [20:0] nav_timer = 0;
wire [3:0] dpad = keys[3:0];
wire [3:0] dpad_press = dpad & ~prev_keys[3:0];
wire       dpad_held = |dpad;
wire       nav_move = |dpad_press || (dpad_held && nav_timer == 0);

always @(posedge clk) begin
    if (dpad_held)
        nav_timer <= nav_timer + 1'd1;
    else
        nav_timer <= 0;
end

// Character lookup for current selection (combinational)
wire [7:0] sel_char_lookup = shifted ? key_char_shifted[sel_row * MAX_COLS + sel_col]
                                     : key_char_normal[sel_row * MAX_COLS + sel_col];

// ======== Input Handling ========
reg prev_toggle;
always @(posedge clk) begin
    prev_toggle <= toggle_in;
    prev_keys <= keys;
    osk_char_valid <= 0;
    osk_backspace  <= 0;
    osk_enter      <= 0;

    // Toggle OSK on/off
    if (toggle_in & ~prev_toggle)
        osk_active <= ~osk_active;

    if (!reset_n) begin
        sel_row <= 0;
        sel_col <= 0;
        shifted <= 0;
        osk_active <= 0;
    end
    else if (osk_active) begin
        // Navigation: instant on press, repeat while held
        if (nav_move) begin
            if (dpad[0] && sel_row > 0) sel_row <= sel_row - 1'd1;           // Up
            if (dpad[1] && sel_row < ROWS-1) sel_row <= sel_row + 1'd1;      // Down
            if (dpad[2] && sel_col > 0) sel_col <= sel_col - 1'd1;           // Left
            if (dpad[3] && sel_col < row_len[sel_row]-1) sel_col <= sel_col + 1'd1; // Right
        end

        // Clamp column to row length
        if (sel_col >= row_len[sel_row])
            sel_col <= row_len[sel_row] - 1'd1;

        // Select (A button)
        if (key_press[4]) begin
            osk_char <= sel_char_lookup;
            if (sel_char_lookup == 8'h08)
                osk_backspace <= 1;
            else if (sel_char_lookup == 8'h0D)
                osk_enter <= 1;
            else
                osk_char_valid <= 1;
        end

        // Backspace (B button)
        if (key_press[5]) osk_backspace <= 1;

        // Enter (X button)
        if (key_press[6]) osk_enter <= 1;

        // Space (Start button)
        if (key_press[15]) begin
            osk_char <= " ";
            osk_char_valid <= 1;
        end

        // Shift toggle (L+R shoulders: bits 8 and 9)
        if (keys[8] & keys[9] & ~(prev_keys[8] & prev_keys[9]))
            shifted <= ~shifted;
    end
end

// ======== Video Rendering ========
localparam OSK_Y_START = V_ACTIVE - KEY_H * ROWS;
localparam OSK_X_START = (H_ACTIVE - KEY_W * MAX_COLS) / 2;

wire in_osk_area = osk_active &&
                   (v_cnt >= OSK_Y_START) && (v_cnt < V_ACTIVE) &&
                   (h_cnt >= OSK_X_START) && (h_cnt < OSK_X_START + KEY_W * MAX_COLS);

wire [3:0] render_col = (h_cnt - OSK_X_START) / KEY_W;
wire [2:0] render_row = (v_cnt - OSK_Y_START) / KEY_H;
wire [4:0] px_in_key  = (h_cnt - OSK_X_START) % KEY_W;
wire [3:0] py_in_key  = (v_cnt - OSK_Y_START) % KEY_H;

wire is_selected = (render_row == sel_row) && (render_col == sel_col);

wire in_char_area = (px_in_key >= (KEY_W-8)/2) && (px_in_key < (KEY_W+8)/2) &&
                    (py_in_key >= (KEY_H-8)/2) && (py_in_key < (KEY_H+8)/2);
wire [2:0] char_px = px_in_key - (KEY_W-8)/2;
wire [2:0] char_py = py_in_key - (KEY_H-8)/2;

wire [6:0] render_key_idx = render_row * MAX_COLS + render_col;
wire [7:0] render_char = shifted ? key_char_shifted[render_key_idx]
                                 : key_char_normal[render_key_idx];
// Map special chars to display glyphs
wire [6:0] glyph = (render_char == 8'h08) ? 7'h3C :  // < for BS
                   (render_char == 8'h0D) ? 7'h3E :  // > for RET
                   (render_char == 8'h1B) ? 7'h2A :  // * for ESC
                   (render_char == 8'h09) ? 7'h3E :  // > for TAB
                   (render_char == " ")   ? 7'h2D :  // - for SPC
                   render_char[6:0];

assign osk_font_addr = {glyph, char_py};

wire font_px = osk_font_data[7 - char_px];

wire valid_key = (render_col < row_len[render_row]) && (render_char != 8'h00);

wire [23:0] key_bg  = is_selected ? 24'h334488 : 24'h111122;
wire [23:0] key_fg  = is_selected ? 24'hFFFFFF : 24'hAABBCC;
wire [23:0] osk_px  = (in_char_area && font_px && valid_key) ? key_fg : key_bg;

assign rgb_out = (in_osk_area && valid_key) ? osk_px : rgb_in;

endmodule

`default_nettype wire
