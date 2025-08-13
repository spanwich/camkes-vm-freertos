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
    # Use the pre-built working FreeRTOS binary directly
    set(FREERTOS_BINARY_PATH "/home/konton-otome/phd/freertos_vexpress_a9/Build/freertos_image.bin")
    
    # Copy working FreeRTOS binary to build directory  
    add_custom_command(
        OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/freertos_image.bin"
        COMMAND ${CMAKE_COMMAND} -E copy "${FREERTOS_BINARY_PATH}" "${CMAKE_CURRENT_BINARY_DIR}/freertos_image.bin"
        DEPENDS "${FREERTOS_BINARY_PATH}"
        COMMENT "Copying working FreeRTOS binary to build directory"
        VERBATIM
    )
    
    # Create custom target for FreeRTOS binary
    add_custom_target(freertos_binary DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/freertos_image.bin")
    
    # Add FreeRTOS binary to file server as "linux" (default name expected by VM component)
    AddToFileServer("linux" "${CMAKE_CURRENT_BINARY_DIR}/freertos_image.bin" DEPENDS freertos_binary)

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
