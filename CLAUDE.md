# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CAmkES VM project demonstrating FreeRTOS virtualization on the seL4 microkernel. The project showcases secure virtualization using formal verification and capability-based security, with a focus on debugging memory fragmentation issues in virtualized environments.

## Build Commands

### Initial Setup
```bash
# Install dependencies (Ubuntu/Debian)
./install-requirements.sh

# Create build directory
mkdir build && cd build

# Initialize build system
../init-build.sh -DCAMKES_VM_APP=freertos -DPLATFORM=qemu_arm_virt -DSIMULATION=1 -DLibUSB=OFF

# Build the project
ninja
```

### Common Build Variants
```bash
# For different platforms (example variants from camkes_README.md)
../init-build.sh -DPLATFORM=sabre -DCAMKES_APP=simple -DSIMULATE=1
../init-build.sh -DPLATFORM=ia32 -DCAMKES_APP=simple -DSIMULATE=1

# Debug builds
../init-build.sh -DCAMKES_VM_APP=freertos -DPLATFORM=qemu_arm_virt -DSIMULATION=1 -DLibUSB=OFF -DRELEASE=OFF
```

### Running and Testing
```bash
# After building, run in QEMU (from build directory)
./simulate

# For manual QEMU debugging
qemu-system-arm -M virt -cpu cortex-a53 -m 2048M -nographic -kernel images/capdl-loader-image-arm-qemu-arm-virt
```

## Architecture Overview

### Core Components
- **seL4 Microkernel**: Formally verified microkernel providing capability-based security
- **CAmkES Framework**: Component architecture for microkernel-based systems
- **VM Manager**: Handles ARM virtualization using hypervisor extensions
- **FreeRTOS Guest**: Simplified bare-metal implementation running as guest OS

### Key Directories
- `kernel/`: seL4 microkernel source and configuration
- `projects/vm-examples/`: VM application examples and FreeRTOS implementation
- `projects/vm/`: ARM VM support libraries and CMake helpers
- `projects/camkes-tool/`: CAmkES framework and code generation tools
- `tools/`: Build tools including Polly toolchain collection

### Memory Architecture
- **Guest Memory Base**: 0x40000000 (512MB allocated)
- **Device Tree Location**: 0x4F000000
- **UART Device**: PL011 at 0x9000000
- **Capability Space**: Configured with 23-bit CNode size

## Development Workflow

### Making Changes to Guest Code
The FreeRTOS guest implementation is located in:
- `projects/vm-examples/apps/Arm/vm_freertos/qemu-arm-virt/freertos_build/`
- Main application: `minimal_main_virt.c`
- Startup code: `minimal_startup_virt.S`
- Linker script: `minimal_virt.ld`
- Build makefile: `minimal_virt.mk`

### CAmkES Component Definition
VM configuration is defined in:
- Assembly: `projects/vm-examples/apps/Arm/vm_freertos/vm_minimal.camkes`
- Device config: `qemu-arm-virt/devices.camkes`
- Build config: `CMakeLists.txt`

### Cross-compilation Requirements
- ARM cross-compiler: `arm-none-eabi-gcc`
- CMake 3.16.0 or higher
- Ninja build system
- Python 3 with specific packages (see install-requirements.sh)

### Debugging Memory Issues
This project includes research into seL4 memory debugging capabilities:
- ELF analysis tools for memory layout inspection
- QEMU memory debugging commands (`info mem`, `info mtree`, `x/` commands)
- Capability → physical address translation mechanisms
- Page fault tracing for memory access patterns

## Important Notes

### Build System
- Uses CMake with Ninja generator
- Cross-compilation toolchains required for ARM targets
- CAmkES generates component code during build process
- File server integration for guest binary loading

### Platform Support
- Primary target: QEMU ARM virt machine with Cortex-A53
- Hardware support for ARM development boards
- Hypervisor extensions required for virtualization

### Security Considerations
- All memory access mediated by seL4 capabilities
- Hardware-enforced memory isolation
- Minimal trusted computing base (TCB) limited to seL4
- Formal verification provides mathematical correctness guarantees