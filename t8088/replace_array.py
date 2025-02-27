# replace_array.py

import re
import os

def extract_array_from_c_file(c_file_path):
    with open(c_file_path, 'r') as c_file:
        content = c_file.read()
        array_match = re.search(r'const\s+unsigned\s+char\s+rom_bin\[\]\s*=\s*\{[^}]+\};', content, re.DOTALL)
        if array_match:
            print("Array found in .c file.")
            return array_match.group(0)
        else:
            print("Array not found in .c file.")
    return None

def replace_array_in_h_file(h_file_path, new_array):
    with open(h_file_path, 'r') as h_file:
        content = h_file.read()
        array_match = re.search(r'PROGMEM\s+const\s+unsigned\s+char\s+rom_bin\[\]\s*=\s*\{[^}]+\};', content, re.DOTALL)
        if array_match:
            print("Array found in memorymap.h.")
            print("Original array in memorymap.h (first 5 lines):\n", "\n".join(array_match.group(0).splitlines()[:5]))
            new_array = new_array.replace('const unsigned char', 'PROGMEM const unsigned char')
            new_content = content.replace(array_match.group(0), new_array)
            if new_content != content:
                print("Array replaced in memorymap.h.")
            else:
                print("Array not replaced in memorymap.h.")
            print("New content in memorymap.h (first 5 lines):\n", "\n".join(new_content.splitlines()[:5]))
        else:
            print("Array not found in memorymap.h.")
            new_content = content
    
    with open(h_file_path, 'w') as h_file:
        h_file.write(new_content)

def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    c_file_path = None

    for file_name in os.listdir(current_dir):
        if file_name.endswith('.c'):
            c_file_path = os.path.join(current_dir, file_name)
            break

    if not c_file_path:
        print("No .c file found in the current directory.")
        return

    h_file_path = os.path.join(current_dir, 'memorymap.h')
    
    if not os.path.exists(h_file_path):
        print("memorymap.h not found in the current directory.")
        return

    new_array = extract_array_from_c_file(c_file_path)
    if new_array:
        replace_array_in_h_file(h_file_path, new_array)
        print("Array replaced successfully.")
    else:
        print("Array not found in the .c file.")

if __name__ == "__main__":
    main()
