# seL4 Source Code Location and Fetching Process

This document explains where the seL4 source code is located within the CAmkES VM FreeRTOS project and how it gets fetched during the build process.

## TL;DR - seL4 Source Code Status

**✅ YES, seL4 source code IS included in this project**

- **Location**: `/home/iamfo470/PhD/camkes-vm/kernel/`
- **Source**: Fetched from official seL4 repository via Google's `repo` tool
- **Version**: seL4 v13.0.0-dev (commit: `dec87e641abd0c02b43e63258fde6234d98e65ad`)
- **Repository**: https://github.com/seL4/seL4.git

## Project Structure Overview

This project uses **Google's `repo` tool** to manage multiple git repositories as a single project. It's NOT using git submodules, but rather a more sophisticated multi-repository management system.

### Repository Management Structure

```
CAmkES VM FreeRTOS Project (repo-managed)
├── .repo/                          # Repo tool metadata
│   ├── manifest.xml               # Points to default.xml
│   ├── manifests/default.xml      # Defines all repositories
│   └── project-objects/           # Git objects for all projects
├── kernel/                        # seL4 microkernel source (from seL4.git)
├── projects/                      # Various component repositories
│   ├── camkes-tool/              # From camkes-tool.git
│   ├── vm-examples/              # From camkes-vm-examples.git
│   ├── vm/                       # From camkes-vm.git
│   └── [other components]
└── tools/                        # Development tools
    ├── polly/                    # From polly repository
    └── seL4/                     # From seL4_tools.git
```

## seL4 Source Code Details

### 1. Current seL4 State

The seL4 microkernel source code is **fully present** in the `kernel/` directory:

```bash
# Current seL4 version
$ cat /home/iamfo470/PhD/camkes-vm/kernel/VERSION
13.0.0-dev

# Git repository information
$ cd /home/iamfo470/PhD/camkes-vm/kernel && git remote -v
seL4    https://github.com/seL4/seL4.git (fetch)
seL4    https://github.com/seL4/seL4.git (push)
```

### 2. seL4 Directory Structure

The kernel directory contains the complete seL4 microkernel implementation:

```
kernel/
├── README.md                    # seL4 documentation
├── VERSION                      # Current version (13.0.0-dev)
├── LICENSE.md                   # seL4 license
├── CMakeLists.txt              # Build configuration
├── FindseL4.cmake              # CMake integration
├── config.cmake                # Configuration options
├── configs/                    # Platform-specific configs
│   ├── ARM_verified.cmake      # ARM platform config
│   ├── AARCH64_verified.cmake  # ARM64 platform config
│   ├── X64_verified.cmake      # x86-64 platform config
│   └── [other platforms]
├── include/                    # seL4 API headers
│   ├── api/                    # System call API
│   ├── arch/                   # Architecture-specific headers
│   │   ├── arm/                # ARM architecture
│   │   ├── riscv/              # RISC-V architecture
│   │   └── x86/                # x86 architecture
│   └── sel4/                   # Core seL4 types and constants
├── libsel4/                    # seL4 user library
│   ├── include/                # User-space API headers
│   ├── src/                    # Library implementation
│   └── tools/                  # Code generation tools
├── src/                        # seL4 kernel implementation
│   ├── api/                    # System call implementation
│   ├── arch/                   # Architecture-specific code
│   │   ├── arm/                # ARM kernel code
│   │   ├── riscv/              # RISC-V kernel code
│   │   └── x86/                # x86 kernel code
│   ├── kernel/                 # Core kernel functionality
│   ├── object/                 # Kernel object implementations
│   └── plat/                   # Platform-specific code
└── tools/                      # Development and build tools
```

### 3. Key seL4 Components Present

**Core Kernel Source** (`src/`):
- **API Implementation**: System calls, IPC, memory management
- **Architecture Support**: ARM, RISC-V, x86 with full source
- **Platform Support**: QEMU, real hardware platforms
- **Object System**: Capabilities, CNodes, endpoints, etc.

**User Library** (`libsel4/`):
- **System Call Stubs**: User-space API wrappers
- **Type Definitions**: seL4 data types and constants
- **Code Generation**: XML-based API generation tools

**Platform Configurations** (`configs/`):
- **Verified Configurations**: Formally verified platform setups
- **Hardware Support**: ARM Cortex-A, ARM64, x86-64, RISC-V

## Repository Fetching Process

### 1. Initial Project Setup

When this project was first set up, the following process occurred:

```bash
# 1. Initialize repo project
repo init -u [manifest-repository-url] -b master

# 2. Fetch all repositories defined in manifest
repo sync
```

### 2. Manifest Configuration

The `.repo/manifests/default.xml` file defines all repositories:

```xml
<manifest>
  <!-- seL4 microkernel -->
  <project name="seL4.git" 
           path="kernel" 
           revision="dec87e641abd0c02b43e63258fde6234d98e65ad" 
           upstream="master" 
           dest-branch="master"/>
  
  <!-- CAmkES components -->
  <project name="camkes-tool.git" path="projects/camkes-tool" .../>
  <project name="camkes-vm.git" path="projects/vm" .../>
  <project name="camkes-vm-examples.git" path="projects/vm-examples" .../>
  
  <!-- Supporting libraries -->
  <project name="seL4_libs" path="projects/seL4_libs" .../>
  <project name="util_libs.git" path="projects/util_libs" .../>
  
  <!-- Development tools -->
  <project name="seL4_tools.git" path="tools/seL4" .../>
  <project name="polly" path="tools/polly" remote="polly" .../>
</manifest>
```

### 3. Current Repository Status

Each component is tracked as a separate git repository:

```bash
$ repo status
# Shows status of all managed repositories including:
# - kernel/ (seL4.git)
# - projects/camkes-tool/ (camkes-tool.git)
# - projects/vm-examples/ (camkes-vm-examples.git)
# - [and all other components]
```

## Build Integration

### 1. CMake Integration

The seL4 kernel integrates with the build system via CMake:

```cmake
# From kernel/FindseL4.cmake
find_path(seL4_DIR
    NAMES config.cmake
    PATHS ${CMAKE_CURRENT_LIST_DIR}
    CMAKE_FIND_ROOT_PATH_BOTH
)

# seL4 provides CMake configuration
include(${seL4_DIR}/config.cmake)
```

### 2. Build Process Flow

1. **Configuration**: CMake locates seL4 in `kernel/` directory
2. **Platform Setup**: Selects appropriate config from `kernel/configs/`
3. **Compilation**: Builds seL4 kernel with ARM virtualization support
4. **Integration**: Links with CAmkES components and VM framework

### 3. Key Build Files

- **`kernel/CMakeLists.txt`**: Main seL4 build configuration
- **`kernel/config.cmake`**: seL4-specific build options
- **`kernel/configs/ARM_HYP_verified.cmake`**: ARM hypervisor config
- **`kernel/src/config.cmake`**: Kernel source configuration

## Version and Update Tracking

### Current seL4 Version Information

```bash
# seL4 version
$ cat kernel/VERSION
13.0.0-dev

# Git commit information
$ cd kernel && git log --oneline -1
dec87e6 (HEAD -> master) Update libsel4 API documentation

# Repository information
$ cd kernel && git remote show seL4
* remote seL4
  Fetch URL: https://github.com/seL4/seL4.git
  Push  URL: https://github.com/seL4/seL4.git
  HEAD branch: master
```

### Update Process

To update seL4 or other components:

```bash
# Update all repositories to latest versions
repo sync

# Update specific repository (e.g., seL4 kernel)
cd kernel && git pull seL4 master

# Update manifest to track new versions
# (requires editing .repo/manifests/default.xml)
```

## Verification and Features

### 1. Formal Verification Status

The included seL4 version supports formal verification:

- **Functional Correctness**: Mathematical proof of kernel correctness
- **Security Properties**: Isolation and access control verification  
- **Verified Configurations**: Available in `kernel/configs/*_verified.cmake`

### 2. ARM Virtualization Support

The seL4 source includes full ARM virtualization support:

```c
// From kernel/src/arch/arm/object/vcpu.c
// Virtual CPU object implementation for ARM hypervisor mode

// From kernel/include/arch/arm/arch/object/vcpu.h
// VCPU API definitions and structures

// From kernel/configs/ARM_HYP_verified.cmake
// ARM hypervisor verified configuration
```

### 3. Supported Features in This Build

- **ARM Hypervisor Extensions**: Stage 2 memory translation
- **Hardware Virtualization**: VCPU objects and VM management
- **Interrupt Virtualization**: Virtual GIC support
- **Memory Management**: Capability-based memory isolation
- **Multi-core Support**: SMP and inter-processor communication

## Summary

The seL4 microkernel source code is **fully present and integrated** in this project:

1. **Location**: Complete source in `/home/iamfo470/PhD/camkes-vm/kernel/`
2. **Management**: Fetched and managed via Google's `repo` tool
3. **Version**: seL4 v13.0.0-dev with ARM virtualization support
4. **Integration**: Fully integrated with CAmkES build system
5. **Status**: Ready for compilation and use in the VM project

The project structure ensures that all necessary components (seL4 kernel, CAmkES framework, VM libraries, build tools) are present and properly coordinated for building the complete CAmkES VM FreeRTOS system.