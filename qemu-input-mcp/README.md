# QEMU Input MCP Tool

This MCP (Model Context Protocol) tool allows Claude Code to interactively control QEMU processes.

## Setup

1. Install dependencies:
```bash
cd qemu-input-mcp
npm install
```

2. Add to your Claude Code configuration at `~/.config/claude-code/config.json`:
```json
{
  "mcp": {
    "servers": {
      "qemu-input": {
        "command": "node",
        "args": ["/home/konton-otome/phd/camkes-vm-freertos/qemu-input-mcp/index.js"]
      }
    }
  }
}
```

3. Restart Claude Code to load the new MCP tool.

## Available Tools

- `qemu_start`: Start QEMU with interactive control
- `qemu_input`: Send keyboard input to QEMU
- `qemu_monitor`: Send commands to QEMU monitor
- `qemu_stop`: Stop the running QEMU process

## Usage Example

Claude Code will be able to:
1. Start QEMU with the seL4 VM
2. Send monitor commands for debugging
3. Interact with the guest OS
4. Properly exit QEMU

This enables full interactive debugging sessions with the CAmkES VM FreeRTOS project.