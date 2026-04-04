//============================================================================
//  ASCII to PS/2 Set 2 Scancode Converter
//  Outputs {needs_shift, scancode[7:0]} for printable ASCII characters.
//
//  Copyright (C) 2026 Eric Lewis — GPL-3.0-or-later
//============================================================================
`default_nettype none

module ascii_to_ps2 (
    input  wire [7:0] ascii,
    output reg        needs_shift,
    output reg  [7:0] scancode
);

always @(*) begin
    needs_shift = 0;
    scancode = 8'h00;

    case (ascii)
    // Letters (lowercase → scancode, uppercase → scancode + shift)
    "a", "A": begin scancode = 8'h1C; needs_shift = (ascii == "A"); end
    "b", "B": begin scancode = 8'h32; needs_shift = (ascii == "B"); end
    "c", "C": begin scancode = 8'h21; needs_shift = (ascii == "C"); end
    "d", "D": begin scancode = 8'h23; needs_shift = (ascii == "D"); end
    "e", "E": begin scancode = 8'h24; needs_shift = (ascii == "E"); end
    "f", "F": begin scancode = 8'h2B; needs_shift = (ascii == "F"); end
    "g", "G": begin scancode = 8'h34; needs_shift = (ascii == "G"); end
    "h", "H": begin scancode = 8'h33; needs_shift = (ascii == "H"); end
    "i", "I": begin scancode = 8'h43; needs_shift = (ascii == "I"); end
    "j", "J": begin scancode = 8'h3B; needs_shift = (ascii == "J"); end
    "k", "K": begin scancode = 8'h42; needs_shift = (ascii == "K"); end
    "l", "L": begin scancode = 8'h4B; needs_shift = (ascii == "L"); end
    "m", "M": begin scancode = 8'h3A; needs_shift = (ascii == "M"); end
    "n", "N": begin scancode = 8'h31; needs_shift = (ascii == "N"); end
    "o", "O": begin scancode = 8'h44; needs_shift = (ascii == "O"); end
    "p", "P": begin scancode = 8'h4D; needs_shift = (ascii == "P"); end
    "q", "Q": begin scancode = 8'h15; needs_shift = (ascii == "Q"); end
    "r", "R": begin scancode = 8'h2D; needs_shift = (ascii == "R"); end
    "s", "S": begin scancode = 8'h1B; needs_shift = (ascii == "S"); end
    "t", "T": begin scancode = 8'h2C; needs_shift = (ascii == "T"); end
    "u", "U": begin scancode = 8'h3C; needs_shift = (ascii == "U"); end
    "v", "V": begin scancode = 8'h2A; needs_shift = (ascii == "V"); end
    "w", "W": begin scancode = 8'h1D; needs_shift = (ascii == "W"); end
    "x", "X": begin scancode = 8'h22; needs_shift = (ascii == "X"); end
    "y", "Y": begin scancode = 8'h35; needs_shift = (ascii == "Y"); end
    "z", "Z": begin scancode = 8'h1A; needs_shift = (ascii == "Z"); end

    // Digits and their shifted symbols
    "0", ")": begin scancode = 8'h45; needs_shift = (ascii == ")"); end
    "1", "!": begin scancode = 8'h16; needs_shift = (ascii == "!"); end
    "2", "@": begin scancode = 8'h1E; needs_shift = (ascii == "@"); end
    "3", "#": begin scancode = 8'h26; needs_shift = (ascii == "#"); end
    "4", "$": begin scancode = 8'h25; needs_shift = (ascii == "$"); end
    "5", "%": begin scancode = 8'h2E; needs_shift = (ascii == "%"); end
    "6", "^": begin scancode = 8'h36; needs_shift = (ascii == "^"); end
    "7", "&": begin scancode = 8'h3D; needs_shift = (ascii == "&"); end
    "8", "*": begin scancode = 8'h3E; needs_shift = (ascii == "*"); end
    "9", "(": begin scancode = 8'h46; needs_shift = (ascii == "("); end

    // Punctuation
    " ":      begin scancode = 8'h29; end // Space
    8'h0D:    begin scancode = 8'h5A; end // Enter
    8'h08:    begin scancode = 8'h66; end // Backspace
    "-", "_": begin scancode = 8'h4E; needs_shift = (ascii == "_"); end
    "=", "+": begin scancode = 8'h55; needs_shift = (ascii == "+"); end
    "[", "{": begin scancode = 8'h54; needs_shift = (ascii == "{"); end
    "]", "}": begin scancode = 8'h5B; needs_shift = (ascii == "}"); end
    ";", ":": begin scancode = 8'h4C; needs_shift = (ascii == ":"); end
    "'", "\"": begin scancode = 8'h52; needs_shift = (ascii == "\""); end
    ",", "<": begin scancode = 8'h41; needs_shift = (ascii == "<"); end
    ".", ">": begin scancode = 8'h49; needs_shift = (ascii == ">"); end
    "/", "?": begin scancode = 8'h4A; needs_shift = (ascii == "?"); end
    "\\", "|": begin scancode = 8'h5D; needs_shift = (ascii == "|"); end

    default: begin scancode = 8'h00; end
    endcase
end

endmodule
