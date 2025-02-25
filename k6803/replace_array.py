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

def replace_array_in_ino_file(ino_file_path, new_array):
    with open(ino_file_path, 'r') as ino_file:
        content = ino_file.read()
        array_match = re.search(r'PROGMEM\s+const\s+unsigned\s+char\s+rom_bin\[\]\s*=\s*\{[^}]+\};', content, re.DOTALL)
        if array_match:
            print("Array found in .ino file.")
        else:
            print("Array not found in .ino file.")
        new_content = re.sub(r'PROGMEM\s+const\s+unsigned\s+char\s+rom_bin\[\]\s*=\s*\{[^}]+\};', new_array, content, flags=re.DOTALL)
        if new_content != content:
            print("Array replaced in .ino file.")
        else:
            print("Array not replaced in .ino file.")
    
    with open(ino_file_path, 'w') as ino_file:
        ino_file.write(new_content)

def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    c_file_path = None
    ino_file_path = None

    for file_name in os.listdir(current_dir):
        if file_name.endswith('.c'):
            c_file_path = os.path.join(current_dir, file_name)
        elif file_name.endswith('.ino'):
            ino_file_path = os.path.join(current_dir, file_name)

    if not c_file_path:
        print("No .c file found in the current directory.")
        return

    if not ino_file_path:
        print("No .ino file found in the current directory.")
        return

    new_array = extract_array_from_c_file(c_file_path)
    if new_array:
        new_array = new_array.replace('const unsigned char', 'PROGMEM const unsigned char')
        replace_array_in_ino_file(ino_file_path, new_array)
        print("Array replaced successfully.")
    else:
        print("Array not found in the .c file.")

if __name__ == "__main__":
    main()