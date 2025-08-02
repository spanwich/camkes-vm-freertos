# seL4 Debugger Project Foundation

## Project Overview

**Research Context**: PhD research in software security focusing on seL4 microkernel for secure embedded systems, with background in ICS security targeting legacy embedded systems and insecure design patterns.

**Primary Goal**: Create a debugger framework for seL4 user code to support migration of legacy insecure C code (e.g., MODBUS drivers) to seL4-based secure systems.

**Secondary Goal**: Address the IT/OT convergence security risks by providing secure foundations for critical embedded systems while maintaining development productivity.

## Current System Architecture

```
Host Computer → QEMU → seL4 Microkernel → VMM → FreeRTOS → Legacy Code (MODBUS drivers)
```

**Current Setup**: FreeRTOS running as VM guest over seL4, hosting legacy C code that needs to be migrated without redefining legacy logic.

## Core Technical Problem

**Observable Issue**: Code that prints "Hello world" every 10 seconds outputs only single character 'H' every 10 seconds.

**Root Cause Analysis**:
- Individual `uart_putc('H'), uart_putc('e'), ...` works correctly
- String-based access `uart_puts("Hello")` or loop over string fails
- Problem lies in string memory access through capability system
- Pointer arithmetic and memory dereferencing lost in translation layers

**Implication**: Memory mapping/capability resolution breaks for consecutive memory access, indicating fundamental issues with address translation chain.

## Address Translation Challenge

### Multi-Layer Translation Chain
1. **User Virtual Address** (FreeRTOS application)
2. **FreeRTOS Virtual Address** (guest OS)
3. **VMM Intermediate Address** (seL4 user space)
4. **seL4 Capability Address** (microkernel)
5. **QEMU Physical Address** (hypervisor)

### Translation Requirements for Debugger
- **Capability → Physical Address Resolution**: Real-time translation through seL4's capability derivation tree
- **CSPACE Introspection**: Expose user process capability space layout
- **Memory Layout Reconstruction**: Map scattered seL4 frame capabilities back to coherent debugger view

## Technical Constraints & Challenges

### 1. Formal Verification Preservation
- seL4's functional correctness proof must be maintained
- Any kernel modifications risk breaking verified security properties
- Need to ensure debugging hooks don't violate information flow properties
- Challenge: Prove debugging-enabled kernel behavior equivalent to original seL4

### 2. Production vs Development Parity
- Code must behave identically in debugging vs production environments
- Avoid "Heisenbug" effects where debugging changes execution behavior
- Maintain exact memory layouts and timing characteristics
- Ensure debugging capabilities can be completely disabled for production

### 3. Security Vulnerability Management
- Adding debugging inherently increases attack surface
- Must prevent debugging interfaces from becoming security vulnerabilities
- Need capability-based access control for debugging operations
- Require temporal isolation and compartmentalization of debug components

## Required Kernel Modifications

### Why User-Space Solutions Are Insufficient
- **Capability Derivation Trees**: Kernel-internal data structures not exposed to user space
- **Physical Address Translation**: Only kernel knows capability → physical frame mapping
- **Atomic State Observation**: Consistent debugging requires kernel-level synchronization

### Specific Extension Points
1. **Capability System Extensions**
   - Add debugging syscalls for capability derivation chain queries
   - Expose capability → physical address translation functions
   - Provide atomic CSPACE layout snapshots

2. **Memory Management Hooks**
   - Insert hooks in `seL4_ARM_Page_Map` for user mapping tracking
   - Modify page fault handler for access pattern reporting
   - Add frame capability allocation/deallocation introspection

3. **Scheduler Integration**
   - Hook thread context switching for per-process debugging state
   - Integrate with seL4 IPC mechanism for cross-domain communication tracing

## Implementation Strategy

### Phase 1: Capability Tracking & Logging
- Add kernel logging for capability dereferencing operations
- Track accessible physical pages for FreeRTOS VM
- Log memory access patterns causing faults
- **Target**: Understand why string access fails after first character

### Phase 2: Address Translation Bridge
- Create kernel syscalls for capability → physical address mapping dumps
- Expose translation information to QEMU debugging interface
- Map FreeRTOS virtual addresses to QEMU physical addresses
- **Target**: Enable basic memory inspection through debugging chain

### Phase 3: Full Debugger Integration
- Implement complete debugging bridge to QEMU debugger
- Support breakpoints, memory inspection, execution tracing
- Maintain symbol table mappings through all translation layers
- **Target**: Production-ready debugging environment for legacy code migration

## Security & Verification Approach

### Conditional Compilation Strategy
- Implement debugging as conditional kernel extensions
- Prove debugging-disabled kernel identical to original seL4
- Maintain separate verification track for debugging-enabled variant

### Information Flow Protection
- Use capability system to ensure debugging components can only observe, not modify
- Implement principle of least privilege for debugging operations
- Create audit trails for all debugging activities

## Research Questions & Validation

1. **How to maintain seL4's formal verification properties while adding debugging capabilities?**
2. **Can debugging hooks be designed to preserve functional correctness proofs?**
3. **What is the minimal set of kernel modifications required for effective debugging?**
4. **How to ensure debugging framework doesn't introduce timing channels or information leaks?**

## seL4 Kernel Source Code Structure (Latest GitHub)

Based on examination of the current seL4 repository (https://github.com/seL4/seL4), the key files for debugger implementation are:

### Core Capability Management Files
- **`src/object/cnode.c`**: Core CNode operations, capability manipulation, memory mapping
- **`src/kernel/cspace.c`**: CSpace addressing and capability resolution
- **`include/object/structures.h`**: Capability and CTE (Capability Table Entry) data structures
- **`include/kernel/cspace.h`**: CSpace function definitions and capability addressing

### Memory Management Files  
- **`src/kernel/boot.c`**: Kernel boot process, initial memory setup, untyped memory allocation
- **`src/arch/x86/kernel/boot_sys.c`** (or ARM equivalent): Architecture-specific memory initialization
- **`include/kernel/vspace.h`**: Virtual space management definitions

### Key Data Structures for Debugger
```c
// From src/object/cnode.c and structures.h
typedef struct cte {
    cap_t cap;           // The capability itself
    mdb_node_t cteMDBNode; // Mapping database node for capability derivation
} cte_t;

// Capability Table Entry - stores capabilities and their metadata
// MDB (Mapping Database) tracks capability derivation relationships
```

### Critical Functions to Hook for Debugging
1. **`locateSlot()`** in CNode.lhs: Resolves capability slot addresses
2. **`getCTE()` / `setCTE()`**: Read/write capability table entries
3. **`updateCap()`**: Modifies capabilities (memory mapping changes)
4. **`isFinalCapability()`**: Determines if capability is the last reference to object

### VM/Virtualization Components
- VMM components run in user space, not kernel space
- seL4 provides mechanisms for user-space VMMs through capability system
- Memory virtualization happens through combination of seL4 capabilities + user-space VMM

## Specific Implementation Entry Points

### Phase 1: Capability Tracking Hooks
**Target Files**: `src/object/cnode.c`, `src/kernel/cspace.c`

**Add logging to these functions**:
- `getCTE()` - Log when FreeRTOS VM accesses capability table entries
- `locateSlot()` - Track capability slot resolution for string memory access
- Page fault handlers in `src/arch/*/kernel/` - Understand why consecutive memory access fails

### Phase 2: Memory Translation Bridge  
**Target Files**: `src/kernel/boot.c`, memory management files

**Required kernel extensions**:
- Add syscalls to dump capability → physical address mappings
- Expose CSpace layout to debugging interface
- Create hooks in page mapping functions to track accessible memory regions

### Phase 3: QEMU Integration
**Integration points**:
- Extend existing debug syscalls (`seL4_DebugPutChar`, `seL4_Debug*`)
- Create new syscall category for debugging bridge
- Map seL4 physical addresses to QEMU's debugging interface

## Build-Time Translation Components: The Missing Pieces

You're absolutely right - capDL, seL4 VMM, and CAmkES are critical components that do build-time and load-time conversions. These are likely where your string memory access problem originates.

### The Complete Translation Pipeline

```
C Source Code → CAmkES → CapDL Spec → CapDL Loader → seL4 VMM → FreeRTOS → Your Code
```

Each of these components transforms memory layout and capability mappings:

### 1. **CAmkES (Component Architecture for microkernel-based Embedded Systems)**
- **Role**: Compiles your C components into seL4-compatible format
- **Key Process**: `python capdl library` inspects your compiled ELF files and creates paging structures
- **Memory Impact**: Creates capability mappings for your virtual addresses
- **Debug Hook Point**: CAmkES templates generate CapDL specifications from your ELF symbols

**Critical Files**:
- `camkes/runner/Context.py` - Template context that builds capability database
- CAmkES templates generate glue code and capability allocations
- **ELF Symbol Processing**: CAmkES reads your ELF's symbol table and creates capability mappings

### 2. **CapDL (Capability Distribution Language)**
- **Role**: Static specification of the system's capability distribution and memory layout
- **Key Process**: CapDL Loader reads the spec and creates actual seL4 objects
- **Memory Impact**: Defines which physical frames back your virtual addresses
- **Debug Hook Point**: CapDL spec contains the authoritative mapping from your original memory layout to seL4 capabilities

**Critical Components**:
- **CapDL Loader**: Root task that creates objects per the specification
- **Python CapDL Library**: Builds capability database from ELF files
- **CapDL Filters**: Modify memory layout (e.g., guard pages around stacks)

### 3. **seL4 VMM (Virtual Machine Monitor)**
- **Role**: Provides hardware virtualization for FreeRTOS guest
- **Key Process**: Maps guest physical addresses to seL4 frame capabilities
- **Memory Impact**: Additional layer of address translation
- **Debug Hook Point**: VMM memory management functions that handle guest memory access

### Why Your String Access Fails: The Translation Break

Your "Hello world" → 'H' problem occurs because:

1. **Original ELF**: String "Hello world" stored in contiguous memory
2. **CAmkES Processing**: Reads ELF symbol table, creates individual page capabilities
3. **CapDL Generation**: String may be split across multiple frame capabilities
4. **CapDL Loader**: Creates separate seL4 frame objects for different parts of string
5. **VMM Translation**: Maps guest physical addresses to fragmented seL4 frames
6. **FreeRTOS Access**: Pointer arithmetic fails when crossing capability boundaries

## Required Debugging Extensions

### Phase 0: Build-Time Analysis (New Priority)
**Target**: Understand how your string gets fragmented during build process

**CAmkES Analysis**:
- Hook into `get_spec()` function that inspects ELF files
- Track how string symbols get mapped to capabilities
- Identify where contiguous memory assumptions break

**CapDL Analysis**:
- Examine generated CapDL spec for your application
- Track frame capability allocations for your data sections
- Identify discontinuities in virtual address mappings

### Phase 1: CapDL Loader Extensions (Updated Priority)
**Target Files**: `capdl-loader-app/src/main.c`

**Required Hooks**:
- Add logging during frame capability creation
- Track virtual address → physical frame mappings
- Log capability derivation for your FreeRTOS VM memory

### Phase 2: VMM Memory Management
**Target Files**: `camkes-vm/components/Init/src/main.c`

**Required Hooks**:
- Add logging in guest memory access handlers
- Track guest physical → seL4 frame translations
- Monitor memory access patterns during string failures

### Phase 3: Kernel Integration (Previous Plans)
Continue with seL4 kernel modifications as planned, but now understanding the full translation chain.

## Specific Investigation Points

### 1. **ELF Symbol Analysis**
- Where is your "Hello world" string located in the original ELF?
- How does CAmkES split it across frame capabilities?
- What's the actual virtual address layout after CapDL processing?

### 2. **CapDL Spec Inspection** 
- Examine the generated `.cdl` file for your application
- Check frame object allocations and virtual address mappings
- Identify gaps or discontinuities in your data section mapping

### 3. **VMM Memory Virtualization**
- How does the VMM map FreeRTOS "physical" addresses to seL4 capabilities?
- Are there gaps in the guest memory mapping that break string access?

## Complete seL4 Ecosystem Components Analysis

You're right to ask about the broader ecosystem! Here's the complete picture of seL4 framework components and their relevance to your debugging project:

### **Core Framework Components (All Relevant)**

#### 1. **CAmkES (Component Architecture for microkernel-based Embedded Systems)**
- **Status**: Mature, currently supported but eventually to be replaced by Microkit
- **Role**: Component-based framework for complex, static systems
- **Your Context**: Currently using this for FreeRTOS VM setup
- **Debugging Relevance**: **Critical** - handles ELF processing and capability generation

#### 2. **Microkit (formerly seL4 Core Platform)**
- **Status**: Newer, simpler framework - future direction
- **Role**: Lightweight SDK for statically-architected systems  
- **Your Context**: Alternative to CAmkES, simpler but less feature-rich
- **Debugging Relevance**: **Alternative Path** - might simplify debugging but less mature

#### 3. **capDL (Capability Distribution Language)**
- **Status**: Core infrastructure used by both CAmkES and Microkit
- **Role**: Static specification of system capability layout
- **Your Context**: Generated from your CAmkES specification
- **Debugging Relevance**: **Critical** - contains authoritative memory mapping

#### 4. **CapDL Loader**
- **Status**: Core system initializer
- **Role**: Root task that creates seL4 objects from capDL specification
- **Your Context**: Loads your FreeRTOS VM according to capDL spec
- **Debugging Relevance**: **Critical** - where capabilities become actual memory

### **Virtualization Components**

#### 5. **CAmkES VMM Library**
- **Status**: Mature, supports AArch32, AArch64, x64
- **Role**: Virtual Machine Monitor for running guest OSes like FreeRTOS
- **Your Context**: What you're currently using
- **Debugging Relevance**: **Critical** - handles guest memory virtualization

#### 6. **Microkit VMM Library** 
- **Status**: Newer, AArch64 only (RISC-V in development)
- **Role**: VMM for Microkit-based systems
- **Your Context**: Alternative if you switch to Microkit
- **Debugging Relevance**: **Future Alternative**

### **Device Framework Components**

#### 7. **sDDF (seL4 Device Driver Framework)**
- **Status**: Experimental, under active development
- **Role**: High-performance user-level device drivers
- **Your Context**: **Not Currently Relevant** - you're using VMM, not native drivers
- **Debugging Relevance**: **Not Applicable** - unless you switch to native seL4 components

### **Current vs Future Ecosystem**

**What You're Using Now (Current Setup)**:
```
Your Code → CAmkES → capDL → CapDL Loader → CAmkES VMM → FreeRTOS
```

**Alternative Path (Future/Simpler)**:
```
Your Code → Microkit → capDL → CapDL Loader → Microkit VMM → FreeRTOS
```

**Native seL4 Path (Advanced)**:
```
Your Code → Microkit → capDL → CapDL Loader → sDDF drivers → Native seL4
```

### **Components Requiring Your Attention**

#### **Tier 1 - Critical for Your Current Project**:
1. **CAmkES** - ELF processing and capability generation
2. **capDL** - Memory layout specification  
3. **CapDL Loader** - Capability → memory object translation
4. **CAmkES VMM** - Guest memory virtualization

#### **Tier 2 - Alternative Paths to Consider**:
5. **Microkit** - Simpler framework, might reduce debugging complexity
6. **Microkit VMM** - Simpler VMM, might have better debugging support

#### **Tier 3 - Not Currently Relevant**:
7. **sDDF** - Only relevant if you abandon VM approach for native seL4

### **Debugging Strategy Implications**

**For Your Current "Hello World" Problem**:
- Focus on **CAmkES → capDL → CapDL Loader → CAmkES VMM** chain
- These four components handle the complete translation from your source to running memory

**Potential Simplification**:
- Consider **Microkit path** for future work - simpler toolchain might be easier to debug
- But stick with CAmkES for now since that's your working setup

### **Missing Components?**
Based on the seL4 ecosystem overview, you've identified all the major framework components. The only other elements are:
- **Language bindings** (C/C++, Rust) - not relevant to memory layout
- **Verification tools** - not relevant to runtime debugging  
- **Platform-specific components** - handled by the above frameworks

## CAmkES-VM Focused Debugging Strategy

**Decision**: Focus on CAmkES-VM codebase, ignore Microkit path for now.

### **Your Current Translation Chain (CAmkES-VM)**
```
C Source Code → CAmkES → capDL Spec → CapDL Loader → CAmkES VMM → FreeRTOS → Your Code
```

### **Critical Components for Debugging (CAmkES-VM Path Only)**

#### 1. **CAmkES (Component Architecture for microkernel-based Embedded Systems)**
- **Role**: Compiles your C components into seL4-compatible format
- **Key Process**: `python capdl library` inspects your compiled ELF files and creates paging structures
- **Memory Impact**: Creates capability mappings for your virtual addresses
- **Debug Hook Point**: CAmkES templates generate CapDL specifications from your ELF symbols

**Critical Files**:
- `camkes/runner/Context.py` - Template context that builds capability database
- CAmkES templates generate glue code and capability allocations
- **ELF Symbol Processing**: CAmkES reads your ELF's symbol table and creates capability mappings

#### 2. **capDL (Capability Distribution Language)**
- **Role**: Static specification of the system's capability distribution and memory layout
- **Key Process**: CapDL Loader reads the spec and creates actual seL4 objects
- **Memory Impact**: Defines which physical frames back your virtual addresses
- **Debug Hook Point**: CapDL spec contains the authoritative mapping from your original memory layout to seL4 capabilities

**Critical Components**:
- **CapDL Loader**: Root task that creates objects per the specification
- **Python CapDL Library**: Builds capability database from ELF files
- **CapDL Filters**: Modify memory layout (e.g., guard pages around stacks)

#### 3. **CAmkES VMM (Virtual Machine Monitor)**
- **Repository**: `camkes-vm` (AArch32, AArch64, x64 support)
- **Role**: Provides hardware virtualization for FreeRTOS guest
- **Key Process**: Maps guest physical addresses to seL4 frame capabilities
- **Memory Impact**: Additional layer of address translation
- **Debug Hook Point**: VMM memory management functions that handle guest memory access

**Critical Files**:
- `camkes-vm/components/Init/src/main.c` - Main VMM component
- VMM memory handlers for guest access
- Guest physical → seL4 frame translation functions

### **Why Your String Access Fails: CAmkES-VM Translation Break**

Your "Hello world" → 'H' problem occurs because:

1. **Original ELF**: String "Hello world" stored in contiguous memory
2. **CAmkES Processing**: Reads ELF symbol table, creates individual page capabilities
3. **CapDL Generation**: String may be split across multiple frame capabilities
4. **CapDL Loader**: Creates separate seL4 frame objects for different parts of string
5. **CAmkES VMM Translation**: Maps guest physical addresses to fragmented seL4 frames
6. **FreeRTOS Access**: Pointer arithmetic fails when crossing capability boundaries

### **CAmkES-VM Specific Investigation Points**

#### **Phase 0: CAmkES Build-Time Analysis**
**Target**: Understand how CAmkES processes your ELF and generates capability mappings

**CAmkES Analysis**:
- Hook into `get_spec()` function that inspects ELF files
- Track how string symbols get mapped to capabilities in CAmkES templates
- Identify where contiguous memory assumptions break during CAmkES processing

**Files to Examine**:
- Your generated `.cdl` file in the build directory
- CAmkES template outputs showing capability allocations
- ELF symbol table vs. generated capability mappings

#### **Phase 1: CapDL Loader Extensions (CAmkES-VM)**
**Target Files**: `capdl-loader-app/src/main.c`

**Required Hooks**:
- Add logging during frame capability creation for your VM components
- Track virtual address → physical frame mappings for FreeRTOS VM
- Log capability derivation specifically for CAmkES-generated VM memory

#### **Phase 2: CAmkES VMM Memory Management**
**Target Files**: `camkes-vm/components/Init/src/main.c`

**Required Hooks**:
- Add logging in guest memory access handlers
- Track guest physical → seL4 frame translations
- Monitor memory access patterns during string failures
- Hook into VMM's memory fault handling

#### **Phase 3: seL4 Kernel Integration (CAmkES-VM Context)**
Continue with seL4 kernel modifications as planned, but now understanding the CAmkES-VM translation chain.

### **CAmkES-VM Specific Debug Strategy**

**Immediate Steps**:
1. **Examine CAmkES-generated capDL spec** for your FreeRTOS VM application
2. **Add debug output to CapDL Loader** to see how VM memory gets allocated
3. **Trace CAmkES VMM's guest memory mapping** for your string addresses
4. **Only then proceed to kernel modifications** with full understanding

**CAmkES-VM Repository Structure**:
- `camkes-vm/components/` - VMM component implementations
- `camkes-vm/apps/` - Example applications (like vm_minimal)
- Build artifacts will show you the generated capDL specs

### **Next Steps for CAmkES-VM Debugging**

1. **Immediate**: Examine your build directory for generated `.cdl` files
2. **Short-term**: Add logging to `camkes-vm` components to track memory mapping
3. **Medium-term**: Hook CapDL Loader for VM-specific capability creation
4. **Long-term**: Implement kernel debugging extensions informed by CAmkES-VM chain

This CAmkES-VM focused approach will give you the precise understanding of where your string memory gets fragmented in the translation chain.

## Verification Considerations for Implementation

Based on seL4 source structure:
- **Verified components**: Files under `src/kernel/object/` are covered by functional correctness proofs
- **Unverified components**: Architecture-specific files (`src/arch/`) have limited verification coverage
- **Strategy**: Implement debugging hooks in architecture-specific areas first to minimize verification impact

## Success Criteria

- Successful debugging of legacy C code (MODBUS drivers) running in FreeRTOS VM over seL4
- Preservation of seL4's security properties in debugging-enabled system
- Demonstration that migrated legacy code behaves identically to bare-metal implementation
- Framework usable for industrial embedded systems security upgrades

---

*This document serves as the foundational knowledge base for the seL4 debugger project, capturing current understanding, technical challenges, and implementation roadmap.*