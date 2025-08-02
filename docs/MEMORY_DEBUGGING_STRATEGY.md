# seL4 Memory Transition Debugging Strategy

Based on the comprehensive analysis in `sel4_debugger_project v5.md`, this document outlines the specific implementation strategy for creating a debugger that instruments every memory transition point in the CAmkES-VM translation chain.

## Overview: The Memory Fragmentation Problem

**Root Cause**: String "Hello world" gets fragmented during the build-time translation process:
1. **Original ELF**: String stored in contiguous memory  
2. **CAmkES Processing**: Creates individual page capabilities
3. **CapDL Generation**: String split across multiple frame capabilities
4. **CapDL Loader**: Creates separate seL4 frame objects
5. **CAmkES VMM**: Maps guest addresses to fragmented seL4 frames
6. **FreeRTOS Access**: Pointer arithmetic fails at capability boundaries

## Complete Translation Chain Instrumentation

### Layer 1: Source Code Analysis (Completed)
**Status**: ✅ **DONE** - We have the debug test code
**Location**: `minimal_main_debug.c` 
**Purpose**: Test different string access patterns to confirm capability boundary issues

### Layer 2: CAmkES Build Process Analysis
**Status**: 🔄 **IN PROGRESS** - Static analysis of generated artifacts
**Target Files**:
- `/home/iamfo470/PhD/camkes-vm/build/vm_minimal.cdl` - Generated CapDL specification
- Build directory ELF symbol analysis
- CAmkES template outputs

**Action Items**:
1. **ELF Symbol Analysis**: Where is the string located in original ELF?
2. **CapDL Frame Mapping**: How does CAmkES split string across frame capabilities?
3. **Virtual Address Layout**: What's the actual address layout after CapDL processing?

### Layer 3: CapDL Loader Instrumentation
**Status**: ⏳ **PLANNED** 
**Target Files**: 
- `capdl-loader-app/src/main.c`
- CapDL Loader capability creation functions

**Required Hooks**:
```c
// Add logging during frame capability creation
void debug_log_frame_creation(cap_t frame_cap, seL4_Word vaddr, seL4_Word paddr) {
    printf("CAPDL_DEBUG: Frame cap created - VA:0x%lx PA:0x%lx Size:%d\n", 
           vaddr, paddr, cap_frame_cap_get_capFSize(frame_cap));
}

// Track virtual address → physical frame mappings for VM
void debug_log_vm_mapping(seL4_Word guest_vaddr, seL4_Word sel4_frame) {
    printf("CAPDL_DEBUG: VM mapping - Guest:0x%lx → seL4 Frame:0x%lx\n", 
           guest_vaddr, sel4_frame);
}
```

### Layer 4: CAmkES VMM Memory Management
**Status**: ⏳ **PLANNED**
**Target Files**: 
- `camkes-vm/components/Init/src/main.c`
- VMM guest memory access handlers

**Required Hooks**:
```c
// Log guest memory access patterns
void debug_log_guest_memory_access(seL4_Word guest_paddr, size_t access_size) {
    printf("VMM_DEBUG: Guest access PA:0x%lx Size:%zu\n", guest_paddr, access_size);
}

// Track guest physical → seL4 frame translations  
void debug_log_translation(seL4_Word guest_paddr, seL4_CPtr frame_cap) {
    printf("VMM_DEBUG: Translation GP:0x%lx → Frame:0x%lx\n", guest_paddr, frame_cap);
}

// Monitor memory fault handling
void debug_log_memory_fault(seL4_Word fault_addr, seL4_Word instruction_ptr) {
    printf("VMM_DEBUG: Memory fault at VA:0x%lx IP:0x%lx\n", fault_addr, instruction_ptr);
}
```

### Layer 5: seL4 Kernel Extensions
**Status**: ⏳ **FUTURE PHASE**
**Target Files**: 
- `src/object/cnode.c` - Capability table operations
- `src/kernel/cspace.c` - Capability space addressing  
- `src/arch/arm/*/kernel/` - Page fault handlers

**Required Kernel Syscalls**:
```c
// New debugging syscalls
seL4_Word seL4_Debug_GetCapabilityMapping(seL4_CPtr cap);
seL4_Error seL4_Debug_DumpCSpace(seL4_CPtr cspace_root);
seL4_Error seL4_Debug_TraceMemoryAccess(seL4_Word vaddr, seL4_Word size);
```

## Implementation Phases

### Phase 0: Static Analysis (Current)
**Objective**: Understand exact memory fragmentation in build artifacts

**Steps**:
1. ✅ Analyze generated `vm_minimal.cdl` for frame allocations
2. 🔄 Examine ELF symbol table for string location  
3. ⏳ Map CapDL frames to original memory layout
4. ⏳ Identify capability boundary crossings

**Expected Output**: Complete map showing where string fragmentation occurs

### Phase 1: CapDL Loader Debug Extension  
**Objective**: Instrument capability creation to see runtime fragmentation

**Steps**:
1. Add debug prints to CapDL Loader frame creation
2. Log VM memory region setup
3. Track capability derivation for VM components
4. Correlate with static analysis findings

**Expected Output**: Runtime log showing exactly how string gets split across capabilities

### Phase 2: CAmkES VMM Debug Extension
**Objective**: Instrument guest memory virtualization layer  

**Steps**:
1. Add logging to VMM memory fault handlers
2. Track guest physical → seL4 frame mappings
3. Monitor consecutive memory access patterns
4. Log when guest memory access fails

**Expected Output**: Precise identification of where string access fails in VM layer

### Phase 3: Kernel Debug Extensions
**Objective**: Full kernel-level debugging capability

**Steps**:
1. Add capability introspection syscalls
2. Implement memory access tracing
3. Create QEMU debugging bridge
4. Maintain formal verification properties

**Expected Output**: Complete debugging framework for legacy code migration

## Instrumentation Strategy

### Debug Output Format
```
[LAYER] Component: Action - Details
[CAPDL] Loader: Frame created - VA:0x40000054 PA:0x50000000 Size:4096  
[VMM] GuestAccess: String read - GA:0x40000054 → Frame:0x50000000
[VMM] Fault: Access failed - VA:0x40000055 (boundary crossing)
[KERNEL] CSpace: Capability miss - Slot:0x1234 not found
```

### Conditional Compilation
```c
#ifdef SEL4_DEBUG_MEMORY_TRANSITIONS
#define DEBUG_LOG_MEMORY(fmt, ...) printf("[MEM_DEBUG] " fmt "\n", ##__VA_ARGS__)
#else  
#define DEBUG_LOG_MEMORY(fmt, ...) do {} while(0)
#endif
```

## Verification Preservation Strategy

### Conditional Debugging Approach
1. **Debug Build**: Include all instrumentation
2. **Production Build**: Identical to original seL4 (prove equivalence)
3. **Verification**: Separate proofs for debug vs production

### Non-Intrusive Logging
- **Read-only observation**: Debug hooks only observe, never modify
- **Timing preservation**: Use buffered async logging to avoid timing changes
- **Capability isolation**: Debug components use separate capability space

## Security Considerations

### Attack Surface Minimization
- **Capability-based access**: Debug syscalls protected by capabilities
- **Temporal isolation**: Debug components only active during debug sessions
- **Information flow**: Ensure debug information doesn't leak between components

### Audit Trail
- **Debug session logging**: Record all debug operations
- **Access control**: Who can enable debugging on what components
- **Rollback capability**: Disable debugging completely for production

## Testing Strategy

### Validation Steps
1. **Static Analysis Validation**: Confirm fragmentation hypothesis with build artifacts
2. **Runtime Correlation**: Match static analysis with runtime behavior  
3. **Progressive Instrumentation**: Add one layer at a time to isolate issues
4. **Production Parity**: Verify debug-disabled system identical to original

### Test Cases
1. **String Access Patterns**: Various string lengths and locations
2. **Memory Layout Variations**: Different ELF section arrangements
3. **Capability Boundary Testing**: Intentional boundary crossing scenarios
4. **Performance Impact**: Measure debugging overhead

## Expected Outcomes

### Immediate (Phase 0-1)
- **Root Cause Identification**: Exact location where string fragmentation occurs
- **Translation Map**: Complete understanding of address translation chain
- **Capability Layout**: Visual representation of memory capability organization

### Medium Term (Phase 2-3)  
- **Debug Framework**: Working debugger for CAmkES-VM applications
- **Legacy Code Support**: Enable migration of MODBUS drivers and similar code
- **Verification Preservation**: Maintain seL4's formal correctness properties

### Long Term (Research Impact)
- **Industrial Adoption**: Framework suitable for secure embedded systems
- **Academic Contribution**: Novel approach to debugging capability-based systems
- **Security Enhancement**: Secure migration path for legacy critical infrastructure

## File Structure for Implementation

```
docs/
├── MEMORY_DEBUGGING_STRATEGY.md (this file)
├── SEL4_SOURCE_TRACKING.md  
├── PROJECT_STRUCTURE.md
└── sel4_debugger_project v5.md

debugging/
├── capdl-loader-debug/
│   ├── debug_hooks.c
│   └── capability_logging.h
├── camkes-vmm-debug/  
│   ├── guest_memory_debug.c
│   └── vmm_instrumentation.h
├── kernel-debug/
│   ├── debug_syscalls.c
│   └── memory_tracing.h
└── test-code/
    ├── minimal_main_debug.c (created)
    └── string_test_variations.c

build/
├── vm_minimal.cdl (analyzed)
├── debug_build/
└── instrumented_artifacts/
```

This comprehensive strategy provides a systematic approach to understanding and debugging the memory fragmentation issue while building toward a complete debugging framework for seL4-based systems.