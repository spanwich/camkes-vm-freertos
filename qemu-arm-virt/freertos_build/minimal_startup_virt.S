.section .text
.global _start
_start:
    ldr sp, =0x48000000   // 128MB top of RAM for qemu-arm-virt
    bl main
    b .
