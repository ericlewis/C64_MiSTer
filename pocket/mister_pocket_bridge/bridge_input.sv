//
// bridge_input.sv
//
// Analogue Pocket Controller → MiSTer Joystick/Keyboard Mapping
//
// Maps Pocket's cont_key/cont_joy/cont_trig signals to MiSTer's
// 16-bit joystick vectors. Supports joystick swap via a config bit.
//
// Copyright (c) 2026 Eric Lewis
// SPDX-License-Identifier: GPL-3.0-or-later
//

module bridge_input (
    input         clk_sys,

    // Pocket APF controller inputs (active on clk_74a, directly usable)
    input  [31:0] cont1_key,
    input  [31:0] cont1_joy,
    input  [15:0] cont1_trig,
    input  [31:0] cont2_key,
    input  [31:0] cont2_joy,
    input  [15:0] cont2_trig,
    input  [31:0] cont3_key,
    input  [31:0] cont3_joy,
    input  [15:0] cont3_trig,
    input  [31:0] cont4_key,
    input  [31:0] cont4_joy,
    input  [15:0] cont4_trig,

    // Configuration
    input         joy_swap,        // Swap joystick 0 and 1

    // MiSTer-style joystick outputs
    output [15:0] joystick_0,
    output [15:0] joystick_1,
    output [15:0] joystick_2,
    output [15:0] joystick_3,

    // Keyboard output (directly from dock)
    output [10:0] ps2_key          // directly stub for now
);

//
// Pocket cont_joy bit layout:
//   [0]  D-pad Up
//   [1]  D-pad Down
//   [2]  D-pad Left
//   [3]  D-pad Right
//   [4]  Face Button A (active high)
//   [5]  Face Button B
//   [6]  Face Button X
//   [7]  Face Button Y
//   [8]  Left Trigger
//   [9]  Right Trigger
//   [10] Left Shoulder
//   [11] Right Shoulder
//   [12] Select
//   [13] Start
//
// MiSTer joystick bit layout (as used by most cores):
//   [3:0]  Right, Left, Down, Up
//   [4]    Fire 1 / Button A
//   [5]    Fire 2 / Button B
//   [6]    Fire 3 / Button Y
//   [7]    Paddle button / Button X
//   [8]    Mod1 (typically Select)
//   [9]    Mod2 (typically Start)
//   [15:10] unused here
//

wire [15:0] raw_joy [4];

// Map each controller
genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : joy_map
        wire [31:0] cont_joy_i = (i == 0) ? cont1_joy :
                                  (i == 1) ? cont2_joy :
                                  (i == 2) ? cont3_joy : cont4_joy;
        wire [31:0] cont_key_i = (i == 0) ? cont1_key :
                                  (i == 1) ? cont2_key :
                                  (i == 2) ? cont3_key : cont4_key;

        assign raw_joy[i] = {
            6'd0,                      // [15:10] unused
            cont_key_i[13],            // [9]  Start → Mod2
            cont_key_i[12],            // [8]  Select → Mod1
            cont_joy_i[6],             // [7]  X → Paddle Btn
            cont_joy_i[7],             // [6]  Y → Fire 3
            cont_joy_i[5],             // [5]  B → Fire 2
            cont_joy_i[4],             // [4]  A → Fire 1
            cont_joy_i[3],             // [3]  D-pad Right
            cont_joy_i[2],             // [2]  D-pad Left
            cont_joy_i[1],             // [1]  D-pad Down
            cont_joy_i[0]              // [0]  D-pad Up
        };
    end
endgenerate

// Apply joystick swap
assign joystick_0 = joy_swap ? raw_joy[1] : raw_joy[0];
assign joystick_1 = joy_swap ? raw_joy[0] : raw_joy[1];
assign joystick_2 = raw_joy[2];
assign joystick_3 = raw_joy[3];

// Keyboard: stub — dock keyboard support TBD
assign ps2_key = 11'd0;

endmodule
