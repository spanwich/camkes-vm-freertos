#define UART0_DR (*(volatile unsigned int *)0x9000000)
#define UART0_FR (*(volatile unsigned int *)0x9000018)

void uart_putc(char c) {
    // Simple approach - just write and wait
    UART0_DR = c;
    for (volatile int i = 0; i < 10000; i++) {}
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s);
        s++;
    }
}

void delay(volatile unsigned int count) {
    while (count--) {
        // Simple delay loop - approximately 5 seconds at typical CPU speeds
        for (volatile int i = 0; i < 1000000; i++) {}
    }
}

void print_freertos_starting(void) {
    uart_putc('F'); uart_putc('r'); uart_putc('e'); uart_putc('e');
    uart_putc('R'); uart_putc('T'); uart_putc('O'); uart_putc('S');
    uart_putc(' '); uart_putc('s'); uart_putc('t'); uart_putc('a');
    uart_putc('r'); uart_putc('t'); uart_putc('i'); uart_putc('n');
    uart_putc('g'); uart_putc('.'); uart_putc('.'); uart_putc('.');
    uart_putc('\n');
}

void print_hello_message(void) {
    uart_putc('H'); uart_putc('e'); uart_putc('l'); uart_putc('l');
    uart_putc('o'); uart_putc(' '); uart_putc('f'); uart_putc('r');
    uart_putc('o'); uart_putc('m'); uart_putc(' '); uart_putc('A');
    uart_putc('R'); uart_putc('M'); uart_putc('-'); uart_putc('V');
    uart_putc('I'); uart_putc('R'); uart_putc('T'); uart_putc('!');
    uart_putc('\n');
}

void main(void) {
    print_freertos_starting();
    
    while (1) {
        print_hello_message();
        delay(5000); // 5 second delay as requested
    }
}
