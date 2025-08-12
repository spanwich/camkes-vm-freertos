#define UART0_DR (*(volatile unsigned int *)0x9000000)
#define UART0_FR (*(volatile unsigned int *)0x9000018)

// Debug version with comprehensive memory access testing
void uart_putc(char c) {
    UART0_DR = c;
    for (volatile int i = 0; i < 10000; i++) {}
}

void uart_puts_safe(const char *s) {
    // Safe version using individual character printing
    while (*s) {
        uart_putc(*s);
        s++;
    }
}

void uart_puts_debug(const char *s) {
    // Debug version that will reveal capability boundary issues
    uart_puts_safe("DEBUG: String addr=0x");
    // Print address as hex
    unsigned int addr = (unsigned int)s;
    for (int i = 28; i >= 0; i -= 4) {
        char hex = ((addr >> i) & 0xF);
        uart_putc(hex < 10 ? '0' + hex : 'A' + hex - 10);
    }
    uart_puts_safe(" content=[");
    
    // Test byte-by-byte access with bounds checking
    int i = 0;
    while (i < 32 && s[i] != '\0') {  // Max 32 chars for safety
        uart_putc(s[i]);
        if (s[i] == '\0') break;
        i++;
        
        // Insert marker every 4 bytes to see capability boundaries
        if (i % 4 == 0) {
            uart_puts_safe("|");
        }
    }
    uart_puts_safe("]\n");
}

void test_memory_access_patterns(void) {
    // Test 1: Static string in .rodata
    static const char test_string[] = "Hello World Debug Test!";
    uart_puts_safe("=== Test 1: Static String ===\n");
    uart_puts_debug(test_string);
    
    // Test 2: Try the problematic uart_puts
    uart_puts_safe("=== Test 2: Direct uart_puts ===\n");
    uart_puts_safe("Before: ");
    uart_puts_safe(test_string);  // This might fail
    uart_puts_safe(" :After\n");
    
    // Test 3: Character array on stack
    char stack_string[] = {'H', 'e', 'l', 'l', 'o', ' ', 'S', 't', 'a', 'c', 'k', '\0'};
    uart_puts_safe("=== Test 3: Stack Array ===\n");
    uart_puts_debug(stack_string);
    
    // Test 4: Single character access
    uart_puts_safe("=== Test 4: Individual Access ===\n");
    uart_putc(test_string[0]); // H
    uart_putc(test_string[1]); // e
    uart_putc(test_string[2]); // l
    uart_putc(test_string[3]); // l
    uart_putc(test_string[4]); // o
    uart_puts_safe(" <- Individual chars\n");
}

void delay(volatile unsigned int count) {
    while (count--) {
        for (volatile int i = 0; i < 100000; i++) {}  // Shorter delay for testing
    }
}

void main(void) {
    uart_puts_safe("=== seL4 Memory Access Debug Session ===\n");
    uart_puts_safe("Testing capability boundary crossing...\n\n");
    
    // Run comprehensive memory access tests
    test_memory_access_patterns();
    
    uart_puts_safe("\n=== Starting periodic tests ===\n");
    
    int iteration = 0;
    while (1) {
        iteration++;
        uart_puts_safe("Iteration ");
        // Print iteration number
        if (iteration < 10) uart_putc('0' + iteration);
        else uart_putc('X'); // X for 10+
        uart_puts_safe(": ");
        
        // Test the problematic case
        static const char hello[] = "Hello from seL4!";
        uart_puts_debug(hello);
        
        delay(1000); // 1 second delay for rapid testing
    }
}