#define UART0_DR (*(volatile unsigned int *)0x9000000)

void uart_putc(char c) {
    UART0_DR = c; 
    for (volatile int i = 0; i < 10000; i++) {}
}

void uart_puts_safe(const char *s) {
    while (*s) {
        uart_putc(*s);
        s++;
    }
}

void print_hex_addr(unsigned int addr) {
    uart_puts_safe("0x");
    for (int i = 28; i >= 0; i -= 4) {
        char hex = ((addr >> i) & 0xF);
        uart_putc(hex < 10 ? '0' + hex : 'A' + hex - 10);
    }
}

// Test capability boundary crossing with known memory layout
void test_4kb_boundary_crossing(void) {
    uart_puts_safe("=== Testing 4KB Boundary Crossing ===\n");
    
    // Create test strings at known positions
    static const char test_string_short[] = "Hi";  // Should fit in one frame
    static const char test_string_medium[] = "Hello World Test String";  // May cross boundary
    static const char test_string_long[] = "This is a very long string that definitely should cross 4KB frame boundaries in the seL4 capability system and cause memory access failures when FreeRTOS tries to read consecutive bytes across capability boundaries";
    
    uart_puts_safe("Short string addr: ");
    print_hex_addr((unsigned int)test_string_short);
    uart_puts_safe(" = \"");
    uart_puts_safe(test_string_short);
    uart_puts_safe("\"\n");
    
    uart_puts_safe("Medium string addr: ");
    print_hex_addr((unsigned int)test_string_medium);
    uart_puts_safe(" = \"");
    uart_puts_safe(test_string_medium);
    uart_puts_safe("\"\n");
    
    uart_puts_safe("Long string addr: ");
    print_hex_addr((unsigned int)test_string_long);
    uart_puts_safe(" = \"");
    uart_puts_safe(test_string_long);
    uart_puts_safe("\"\n");
    
    // Test byte-by-byte access to see where it fails
    uart_puts_safe("\n=== Byte-by-byte Analysis ===\n");
    uart_puts_safe("Long string bytes: [");
    for (int i = 0; i < 100 && test_string_long[i] != '\0'; i++) {
        if (i % 16 == 0) {
            uart_puts_safe("\nOffset ");
            if (i < 10) uart_putc('0');
            if (i < 100) uart_putc('0' + (i/10));
            uart_putc('0' + (i%10));
            uart_puts_safe(": ");
        }
        uart_putc(test_string_long[i]);
        
        // Add boundary markers every 4KB (assuming string starts at page boundary)
        if ((i + 1) % 4096 == 0) {
            uart_puts_safe("|4KB|");
        }
    }
    uart_puts_safe("]\n");
}

// Test memory access patterns that match CapDL frame layout
void test_capdl_frame_pattern(void) {
    uart_puts_safe("\n=== Testing CapDL Frame Pattern ===\n");
    uart_puts_safe("Based on vm_minimal.cdl analysis:\n");
    uart_puts_safe("- First 8 frames: 4KB each (32768->40960 offset)\n");
    uart_puts_safe("- Later frames: 64KB each\n");
    uart_puts_safe("- String likely in early 4KB frames\n\n");
    
    // Test at frame boundaries
    volatile char *base_ptr = (volatile char *)0x40000000;  // Guest RAM base
    
    uart_puts_safe("Memory probe test:\n");
    for (int offset = 0; offset < 32; offset += 4) {
        uart_puts_safe("Offset ");
        if (offset < 10) uart_putc('0');
        uart_putc('0' + (offset/10));
        uart_putc('0' + (offset%10));
        uart_puts_safe(": ");
        
        // Try to read byte (this might fault at capability boundaries)
        volatile char test_byte = base_ptr[offset];
        uart_putc('0' + (test_byte & 0xF));  // Print as digit
        uart_puts_safe(" ");
        
        if ((offset + 4) % 4096 == 0) {
            uart_puts_safe("| 4KB boundary |");
        }
        uart_puts_safe("\n");
    }
}

void main(void) {
    uart_puts_safe("=== seL4 Capability Boundary Test ===\n");
    uart_puts_safe("Testing memory fragmentation hypothesis\n");
    uart_puts_safe("Based on CapDL spec: vm_minimal.cdl\n\n");
    
    test_4kb_boundary_crossing();
    test_capdl_frame_pattern();
    
    uart_puts_safe("\n=== Test Complete ===\n");
    uart_puts_safe("If string access fails mid-way, confirms\n");
    uart_puts_safe("capability boundary crossing issue.\n");
    
    // Keep running for observation
    int iteration = 0;
    while (1) {
        iteration++;
        uart_puts_safe("\nIteration ");
        uart_putc('0' + (iteration % 10));
        uart_puts_safe(": ");
        
        // Simple test that should work
        uart_puts_safe("OK");
        
        // Delay
        for (volatile int i = 0; i < 5000000; i++) {}
    }
}