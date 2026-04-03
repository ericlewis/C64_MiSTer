# generate_pll.tcl
#
# Generates the PLL IP for the Pocket C64 core via Quartus scripting.
# Run with: quartus_sh -t generate_pll.tcl
#
# This creates a proper altera_pll megafunction targeting 5CEBA4F23C8
# with 74.25 MHz input and the required C64 output frequencies.

package require ::quartus::ip

# Create the PLL IP
set ip [create_ip_instance altera_pll pocket_pll]

# Configure parameters
set_ip_parameter -ip $ip -parameter device_family "Cyclone V"
set_ip_parameter -ip $ip -parameter gui_reference_clock_frequency "74.25"
set_ip_parameter -ip $ip -parameter gui_pll_mode "Fractional-N PLL"
set_ip_parameter -ip $ip -parameter gui_operation_mode "direct"
set_ip_parameter -ip $ip -parameter gui_number_of_clocks 4
set_ip_parameter -ip $ip -parameter gui_en_reconf false
set_ip_parameter -ip $ip -parameter gui_use_locked true

# Output 0: ~63 MHz (SDRAM)
set_ip_parameter -ip $ip -parameter gui_output_clock_frequency0 "63.055911"
set_ip_parameter -ip $ip -parameter gui_phase_shift_deg0 "0.0"
set_ip_parameter -ip $ip -parameter gui_duty_cycle0 50

# Output 1: ~31.5 MHz (C64 system, PAL)
set_ip_parameter -ip $ip -parameter gui_output_clock_frequency1 "31.527956"
set_ip_parameter -ip $ip -parameter gui_phase_shift_deg1 "0.0"
set_ip_parameter -ip $ip -parameter gui_duty_cycle1 50

# Output 2: ~47.3 MHz (OPL3)
set_ip_parameter -ip $ip -parameter gui_output_clock_frequency2 "47.291931"
set_ip_parameter -ip $ip -parameter gui_phase_shift_deg2 "0.0"
set_ip_parameter -ip $ip -parameter gui_duty_cycle2 50

# Output 3: ~31.5 MHz 90° (video DDR)
set_ip_parameter -ip $ip -parameter gui_output_clock_frequency3 "31.527956"
set_ip_parameter -ip $ip -parameter gui_phase_shift_deg3 "90.0"
set_ip_parameter -ip $ip -parameter gui_duty_cycle3 50

# Generate the IP files
generate_ip $ip

puts "PLL IP generated successfully"
