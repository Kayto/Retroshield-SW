# Primes Program
# Builds to Intel HEX format for loading via SMON

CA65_BINARY=ca65
LD65_BINARY=ld65

CPU_FLAG=--cpu 65C02
CA65_FLAGS=$(CPU_FLAG)

BUILD_DIR=../../build/primes

PROGRAM_CFG=primes.cfg
PROGRAM_BINARY=$(BUILD_DIR)/primes.bin

ASM_SOURCES=primes_ca65.s

all: $(PROGRAM_BINARY)

$(PROGRAM_BINARY): $(ASM_SOURCES) $(PROGRAM_CFG)
	@mkdir -p $(BUILD_DIR)
	$(CA65_BINARY) $(CA65_FLAGS) -o $(BUILD_DIR)/primes_ca65.o -l $(BUILD_DIR)/primes_ca65.lst $<
	$(LD65_BINARY) -C $(PROGRAM_CFG) -o $@ $(BUILD_DIR)/primes_ca65.o

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
