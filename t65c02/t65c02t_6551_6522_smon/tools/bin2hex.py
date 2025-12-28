#!/usr/bin/env python3
import sys

def generate_intel_hex(binary_file, hex_file, start_addr):
    """Convert binary to Intel HEX format"""
    with open(binary_file, 'rb') as f:
        data = f.read()
    
    def intel_hex_line(address, chunk):
        byte_count = len(chunk)
        addr_hi = (address >> 8) & 0xFF
        addr_lo = address & 0xFF
        record_type = 0x00
        
        # Calculate checksum
        checksum_sum = byte_count + addr_hi + addr_lo + record_type + sum(chunk)
        checksum = ((~checksum_sum) + 1) & 0xFF
        
        line = f':{byte_count:02X}{address:04X}{record_type:02X}'
        line += ''.join(f'{b:02X}' for b in chunk)
        line += f'{checksum:02X}'
        return line
    
    with open(hex_file, 'w') as f:
        # Write data records
        for i in range(0, len(data), 16):
            chunk = data[i:i+16]
            f.write(intel_hex_line(start_addr + i, chunk) + '\n')
        
        # Write EOF record
        f.write(':00000001FF\n')
    
    print(f'Generated {hex_file}')
    print(f'Size: {len(data)} bytes')
    print(f'Address: 0x{start_addr:04X}-0x{start_addr + len(data) - 1:04X}')

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('Usage: bin2hex.py <input.bin> <output.hex> <start_address>')
        sys.exit(1)
    
    binary_file = sys.argv[1]
    hex_file = sys.argv[2]
    start_addr = int(sys.argv[3], 0)
    
    generate_intel_hex(binary_file, hex_file, start_addr)
