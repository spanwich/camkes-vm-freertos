#
# Copyright 2018, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

set(supported "qemu-arm-virt")
if(NOT "${PLATFORM}" IN_LIST supported)
    message(FATAL_ERROR "PLATFORM: ${PLATFORM} not supported.
         Supported: ${supported}")
endif()
if(${PLATFORM} STREQUAL "qemu-arm-virt")
    # force cpu for ARM 32-bit compatibility with FreeRTOS
    set(QEMU_MEMORY "2048")
    set(KernelArmCPU cortex-a15 CACHE STRING "" FORCE)
    set(KernelSel4Arch arm_hyp CACHE STRING "" FORCE)
endif()
