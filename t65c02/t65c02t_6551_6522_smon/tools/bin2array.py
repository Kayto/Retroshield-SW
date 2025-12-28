#!/usr/bin/env python3
"""Convert binary file to C array format"""
import sys

def generate_c_array(binary_file, c_file, array_name, start_addr):
    """Convert binary to C array format"""
    with open(binary_file, 'rb') as f:
        data = f.read()
    
    # Convert start_addr to int
    start_addr_int = int(start_addr, 0)
    
    with open(c_file, 'w') as f:
        # Write array declaration
        f.write(f'// Array generated from {binary_file}\n')
        f.write(f'// Size: {len(data)} bytes\n')
        f.write(f'// Address: {start_addr_int:#06x}\n')
        f.write(f'const unsigned char {array_name}[{len(data)}] = {{\n')
        
        # Write data in rows of 16 bytes
        for i in range(0, len(data), 16):
            chunk = data[i:i+16]
            hex_values = ', '.join(f'0x{b:02X}' for b in chunk)
            
            # Add comment with address
            addr = start_addr_int + i
            f.write(f'    {hex_values}')
            
            # Add comma if not last line
            if i + 16 < len(data):
                f.write(',')
            
            f.write(f'  // {addr:#06x}\n')
        
        f.write('};\n')
    
    print(f'Generated {c_file}')
    print(f'Array: {array_name}[{len(data)}]')
    print(f'Address: {start_addr}')

if __name__ == '__main__':
    if len(sys.argv) != 5:
        print('Usage: bin2array.py <input.bin> <output.c> <array_name> <start_address>')
        sys.exit(1)
    
    binary_file = sys.argv[1]
    c_file = sys.argv[2]
    array_name = sys.argv[3]
    start_addr = sys.argv[4]
    
    generate_c_array(binary_file, c_file, array_name, start_addr)
