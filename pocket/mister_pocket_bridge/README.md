# mister_pocket_bridge

A reusable adapter library for porting MiSTer FPGA cores to the Analogue Pocket.

## Overview

This library provides drop-in bridge modules that translate MiSTer-compatible interfaces (hps_io, video, audio, SDRAM, joystick) into Analogue Pocket APF signals. Instead of rewriting your core's integration layer from scratch, you can use these bridges and keep your existing MiSTer signal wiring mostly intact.

## Modules

| Module | Purpose |
|--------|---------|
| `mister_pocket_bridge.sv` | Top-level convenience wrapper — instantiates all bridges |
| `bridge_video.sv` | MiSTer VGA_R/G/B + sync → APF video scaler interface |
| `bridge_audio.sv` | MiSTer AUDIO_L/R 16-bit → APF I2S (48kHz) |
| `bridge_input.sv` | APF controller buttons/dpad → MiSTer joystick vectors |
| `bridge_data_loader.sv` | APF data slots → MiSTer ioctl_download/wr/addr/dout |
| `bridge_interact.sv` | APF bridge registers (interact.json) → MiSTer status[] |
| `bridge_memory.sv` | MiSTer SDRAM_* pin names → Pocket dram_* pin names |

## Quick Start

1. Copy this directory into your Pocket core project
2. Copy the APF template from [open-fpga/core-template](https://github.com/open-fpga/core-template) into `apf/`
3. In your `core_top.v`, instantiate `mister_pocket_bridge` and connect both sides
4. Generate a PLL for 74.25 MHz → your core's required clocks
5. Instantiate your core's main module with MiSTer-style signal names
6. Create JSON config files for your core

## What You Still Need Per-Core

- **PLL**: Generated via Quartus MegaWizard for 74.25 MHz input → your target frequencies
- **core_top.v**: Core-specific adapter that wires the bridge to your emu module
- **Data slot mapping**: Configure which data slot IDs map to which ioctl_index values
- **Status bit mapping**: Configure which bridge register addresses map to which status bits
- **SD block I/O**: If your core uses sd_lba (disk images), you need a `disk_loader` module
- **JSON configs**: core.json, input.json, data.json, video.json, audio.json, interact.json

## Architecture

```
┌─────────────────────────────────────────────┐
│              apf_top.v (APF template)       │
│  clk_74a/b, bridge bus, controllers, etc.   │
└─────────────────────┬───────────────────────┘
                      │
         ┌────────────▼──────────────┐
         │      core_top.v           │
         │   (your core adapter)     │
         │                           │
         │  ┌─────────────────────┐  │
         │  │ mister_pocket_bridge│  │
         │  │  ┌─ bridge_video   │  │
         │  │  ├─ bridge_audio   │  │
         │  │  ├─ bridge_input   │  │
         │  │  ├─ bridge_interact│  │
         │  │  └─ bridge_memory  │  │
         │  └─────────────────────┘  │
         │                           │
         │  ┌─────────────────────┐  │
         │  │  Your MiSTer Core   │  │
         │  │  (emu module)       │  │
         │  └─────────────────────┘  │
         └───────────────────────────┘
```

## License

GPL-3.0-or-later
