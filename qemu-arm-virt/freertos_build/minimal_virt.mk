CC=arm-none-eabi-gcc
LD=arm-none-eabi-gcc
CFLAGS=-mcpu=cortex-a15 -marm -nostdlib -ffreestanding -O2 -Wall
LDFLAGS=-Tminimal_virt.ld -nostdlib -static
TARGET=minimal_uart_virt.elf

all: $(TARGET)

minimal_startup_virt.o: minimal_startup_virt.S
	$(CC) $(CFLAGS) -c -o $@ $<

minimal_main_virt.o: minimal_main_virt.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(TARGET): minimal_startup_virt.o minimal_main_virt.o minimal_virt.ld
	$(LD) $(CFLAGS) -o $@ minimal_startup_virt.o minimal_main_virt.o $(LDFLAGS)

clean:
	rm -f *.o *.elf
