#
# Copyright 2018, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.8.2)

project(camkes-arm-virt-vm C)

include(${CAMKES_ARM_VM_HELPERS_PATH})

set(cpp_includes "${CAMKES_VM_DIR}/components/VM_Arm")

# Create our CPP Flags based on ARM VM config variables
if("${KernelARMPlatform}" STREQUAL "qemu-arm-virt")
    # Build FreeRTOS from source
    add_custom_command(
        OUTPUT "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build/minimal_uart_virt.elf"
        COMMAND make -C "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build" -f minimal_virt.mk
        DEPENDS "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build/minimal_main_virt.c"
                "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build/minimal_startup_virt.S"
                "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build/minimal_virt.ld"
                "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build/minimal_virt.mk"
        VERBATIM
    )
    
    # Use FreeRTOS ELF directly as the "linux" kernel (preserves entry point metadata)
    AddToFileServer("linux" "${CMAKE_CURRENT_LIST_DIR}/qemu-arm-virt/freertos_build/minimal_uart_virt.elf")

    set(cpp_flags "-DKERNELARMPLATFORM_QEMU-ARM-VIRT")

    include(simulation)
    set(SIMULATION ON CACHE BOOL "Generate simulation script to run qemu with the proper arguments")
    if(SIMULATION)
        GenerateSimulateScript()
    endif()

endif()

AddCamkesCPPFlag(cpp_flags CONFIG_VARS VmEmmc2NoDMA)

DefineCAmkESVMFileServer()

CAmkESAddImportPath(${KernelARMPlatform})

# Declare root server
DeclareCAmkESRootserver(vm_minimal.camkes CPP_FLAGS ${cpp_flags} CPP_INCLUDES ${cpp_includes})
