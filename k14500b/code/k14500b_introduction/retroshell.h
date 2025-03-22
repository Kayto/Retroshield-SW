#include <Arduino.h>

bool          globalHex    = false;              // Number entry is hex or dec by default.
unsigned int  memoryIndex  = 0;                  // Used by assembler to track next memory address

////////////////////////////////////////////////////////////////////
// Required functions to access ROM/RAM/IO
////////////////////////////////////////////////////////////////////

extern void uP_assert_reset();
extern void uP_release_reset();
extern byte rom_read_byte(word addr);
extern bool rom_write_byte(word addr, byte value);
extern byte port_read(word addr);
extern void port_write(word addr, byte newValue);

bool exit_with_singleStep = false;
bool shell_is4004 = false;
bool shell_is14500B = false;
int  processor_stopped_addr = 0;

#define SHELL_MEMORY_START   ROM_START
#define SHELL_MEMORY_END     ROM_END

byte shell_memory_original[SHELL_MEMORY_END - SHELL_MEMORY_START + 1];    // Original ROM memory

void memory_save_original()
{
  if (sizeof(shell_memory_original) != (SHELL_MEMORY_END - SHELL_MEMORY_START + 1))
  {
    Serial.println("ERR: memory_copy_original - size mismatch.");
    // while(1);
  }
  else
  {
    for(unsigned int i=0; i<sizeof(shell_memory_original); i++)
      shell_memory_original[i] = rom_read_byte(i + SHELL_MEMORY_START);
  }
}

void memory_restore_original()
{
  if (sizeof(shell_memory_original) != (SHELL_MEMORY_END - SHELL_MEMORY_START + 1))
  {
    Serial.println("ERR: memory_copy_restore - size mismatch.");
    // while(1);
  }
  else
  {
    for(unsigned int i=0; i<sizeof(shell_memory_original); i++)
      if (rom_write_byte(i + SHELL_MEMORY_START, shell_memory_original[i]))
        ;
      else
      {
        Serial.println("ERR: Can not restore ROM in Flash. Move it to RAM first.");
        break;
      } 
  }
}

bool memory_check_range(unsigned int addr)
{
  if ((addr >= SHELL_MEMORY_START) && (addr <= SHELL_MEMORY_END))
    return true;
  else
    return false;
}

int memory_index_get()
{
  return memoryIndex;
}

////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////
int memory_index_set(unsigned int addr)
{
  if (memory_check_range(addr))
    memoryIndex = addr;
  else
    Serial.write("ERR: memory_index_set - out of addr range.");

  return memoryIndex;
}

int memory_index_inc()
{
  memoryIndex++;
  if (memoryIndex > SHELL_MEMORY_END)
    memoryIndex = 0;

  return memoryIndex;
}

////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////
uint8_t memory_read(unsigned int addr)
{
  if (memory_check_range(addr))  
    return rom_read_byte(addr);
  else 
  {
    Serial.write("ERR: memory_read - out of addr range.");
    return -1;
  }
}

uint8_t memory_read_index()
{
  return rom_read_byte(memoryIndex);
}

uint8_t memory_read_index_inc()
{
  uint8_t d = memory_read(memoryIndex);
  memory_index_inc();
  return d;
}

////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////
bool memory_write(unsigned int addr, uint8_t data)
{
  if (memory_check_range(addr))  
    return rom_write_byte(addr, data);     // ROM in flash error, already covered by write_rom_byte()
  else
  {
    Serial.write("ERR: memory_write - out of addr range.");
    return false;
  }
}

bool memory_write_index(uint8_t data)
{
  return memory_write(memoryIndex, data);
}

bool memory_write_index_inc(uint8_t data)
{
  if (memory_write(memoryIndex, data))
  {
    memory_index_inc();
    return true;
  }
  else
    return false;
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
void retro_prompt()
{
  Serial.print("> ");
}

String retro_getline(bool print_cr)
{
  String input = "";
  
  while(true)
  {
    if (Serial.available())
    {
      char c = toLowerCase(Serial.read());  // Read one character

      // Serial.print(c, HEX);

      // If the user presses Enter (newline), process the command
      if ((c == '\r') || (c == '\n'))
      {
        if (false || (input.length() >0))           // false = ignore initial returns (\r\n sent back to back).
        {
          if (print_cr == true) Serial.print(c);    // don't print CR/LF if using inline edits.
          input.trim();              
          break;
        }
      }
      else
      if (c == 27)              // ESCPAE
      {
        Serial.println();
        input = "";
        break;
      }
      else
      if (c == 8)               // BACKSPACE
      {
        if (input.length() > 0)
        {
          Serial.print(c);
          Serial.print(" ");          // Go back and erase last char
          Serial.print(c);
          input = input.substring(0, input.length()-1);
        }
      }
      else
      {
        Serial.print(c);         // Echo the character back to the Serial Monitor
        input += c;              // Append the character to the input string
      }
    }
  } 
  return input;
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
void retro_print1hex(int v)
{
  char tmp[10];

  sprintf(tmp, "%01X", v);
  Serial.write(tmp);
}

void retro_print2hex(int v)
{
  char tmp[10];

  sprintf(tmp, "%02X", v);
  Serial.write(tmp);
}

void retro_print4hex(int v)
{
  char tmp[10];

  sprintf(tmp, "%04X", v);
  Serial.write(tmp);
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
int retro_c2hex(String s)
{
  unsigned int index = 0;
  int value = 0;
  bool ishex = false;
  bool done = false;

  // if empty, error.
  if (s.length() == 0)
    return -1;
  
  // skip space at the beginning
  while(s.charAt(index) == ' ')
    index++;

  // Start w/ default
  ishex = globalHex;

  // parse chars one by one until space.
  while(!done)
  {
    char c = s.charAt(index);

    if (c == '$')           // if $ is used in the middle, weird results...
      ishex = true;   
    else
    if (c == '#')           // if # is used in the middle, weird results...
      ishex = false;   
    else
    if ((c >= '0') && (c <= '9'))
      value = value * (10+6*ishex) + (c - '0');
    else
    if (ishex && (c >= 'a') && (c <= 'f'))
      value = value * (10+6*ishex) + (10 + c - 'a');
    else
    if (ishex && (c >= 'a') && (c <= 'f'))
      value = value * (10+6*ishex) + (10 + c - 'A');
    else
    if (c == ' ')
      break;
    else
    {
      // Serial.println("ERR - invalid chars. Use 0..9 and a..b");
      return -1;
      // value = value;
    }

    index++;
    if (index >= s.length())
      break;
  }
  return value;  
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------

void shell_port_print()
{
  byte i;

  Serial.println("|_____Memory______|_R___Inputs______|____Outputs______|");
  Serial.println("| 0 1 2 3 4 5 6 7 | 8 9 A B C D E F | 8 9 A B C D E F |");

  Serial.print("| ");
  for (i=0; i<=0x7; i++)
  {
    retro_print1hex(port_read(i));
    Serial.print(" ");
  }
  Serial.print("| ");

  for (i=8; i<=0xF; i++)
  {
    retro_print1hex(port_read(i));
    Serial.print(" ");
  }
  Serial.print("| ");  

  // This is hacky, but it works.
  retro_print1hex(digitalReadFast(uP_OUTP_D0)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D1)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D2)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D3)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D4)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D5)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D6)); Serial.print(" "); 
  retro_print1hex(digitalReadFast(uP_OUTP_D7)); Serial.print(" ");
  Serial.println("|");

}

void shell_port_set(int port_in, int bit_in)
{
  int port;
  int bit;

  if ((port_in >= 0) && (port_in <= 0xF) && (bit_in >= 0) && (bit_in <= 1))
  {
    port = port_in;
    bit  = bit_in;
  }
  else
  {
    // Get port & bit
    Serial.print("Port ");
    String addrStr = retro_getline(true);     // true = print CR/LF

    // Check if user entered port & bit (i.e. 9 1):
    int spaceIndex = addrStr.indexOf(' ');
    String portStr = spaceIndex == -1 ? addrStr : addrStr.substring(0, spaceIndex);
    String bitStr  = spaceIndex == -1 ? ""      : addrStr.substring(spaceIndex + 1);

    port = retro_c2hex(portStr);
    bit  = retro_c2hex(bitStr);

    // If bit value is wrong from port line, then ask for it.
    if (bit == -1)
    {
      Serial.print("1/0? ");
      bitStr = retro_getline(true);     // true = print CR/LF
      bit    = retro_c2hex(bitStr);
    }
  }

  if ((port >= 0) && (port <= 0xF) && (bit >= 0) && (bit <= 1))
  { 
    port_write(port, bit);
    Serial.print("Port ");
    Serial.print(port, HEX);
    Serial.print(" = ");
    Serial.println(bit, HEX);

    shell_port_print();    
  }
  else
    Serial.println("ERR: Invalid port address or bit.");  
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// Intel 4004 Instruction Set
const struct {
  const char *mnemonic;
  uint8_t opcode;
} intel4004InstructionSet[] = {
  {"NOP", 0x00},  
  {"JCN", 0x10},
  {"FIM", 0x20}, 
  {"SRC", 0x21},
  {"FIN", 0x30},
  {"JIN", 0x31},
  {"JUN", 0x40},  
  {"JMS", 0x50},   
  {"INC", 0x60}, 
  {"ISZ", 0x70},
  {"ADD", 0x80},  
  {"SUB", 0x90},   
  {"LD",  0xA0}, 
  {"XCH", 0xB0},
  {"BBL", 0xC0},  
  {"LDM", 0xD0},   
  {"WRM", 0xE0}, 
  {"WMP", 0xE1}, 
  {"WRR", 0xE2}, 
  {"WPM", 0xE3}, 
  {"WR0", 0xE4}, 
  {"WR1", 0xE5}, 
  {"WR2", 0xE6}, 
  {"WR3", 0xE7}, 
  {"SBM", 0xE8}, 
  {"RDM", 0xE9}, 
  {"RDR", 0xEA}, 
  {"ADM", 0xEB}, 
  {"RD0", 0xEC}, 
  {"RD1", 0xED}, 
  {"RD2", 0xEE}, 
  {"RD3", 0xEF}, 
  {"CLB", 0xF0},
  {"CLC", 0xF1},
  {"IAC", 0xF2},
  {"CMC", 0xF3},
  {"CMA", 0xF4},
  {"RAL", 0xF5},
  {"RAR", 0xF6},
  {"TCC", 0xF7},
  {"DAC", 0xF8},
  {"TCS", 0xF9},
  {"STC", 0xFA},
  {"DAA", 0xFB},
  {"KBP", 0xFC},
  {"DCL", 0xFD},
  // na {"", 0xFE},
  // na {"", 0xFF},
};

// Find opcode for a given mnemonic (Intel 4004)
int findIntel4004Opcode(const String &mnemonic)
{
  for (size_t i = 0; i < sizeof(intel4004InstructionSet) / sizeof(intel4004InstructionSet[0]); i++)
  {
    if (mnemonic.equalsIgnoreCase(intel4004InstructionSet[i].mnemonic))
    {
      return intel4004InstructionSet[i].opcode;
    }
  }
  return -1; // Invalid mnemonic
}

// Find opcode for a given byte (Intel 4004)
String findIntel4004Opcode_toString(int byte8)
{
  for (size_t i = 0; i < sizeof(intel4004InstructionSet) / sizeof(intel4004InstructionSet[0]); i++)
  {
    if (byte8 == intel4004InstructionSet[i].opcode)
    {
      String text(intel4004InstructionSet[i].mnemonic);
      text.toLowerCase();
      return text;
    }
  }
  return "ERR_Opcode"; // Invalid mnemonic
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
const struct {
  const char *mnemonic;
  uint8_t opcode;
} intel4004JCNConditionalSet[] = {
  // Use Zero / Non-zero instead of 0/1
  // {"NOP",     0x0},    // no op
  {"TZ",      0x1},   
  {"C1",      0x2},   
  {"TZC1",    0x3},   
  {"AZ",      0x4},   
  {"TZAZ",    0x5},   
  {"C1AZ",    0x6},   
  {"TZC1AZ",  0x7},   
  {"TN",      0x9},   
  {"C0",      0xa},   
  {"TNC0",    0xb},   
  {"AN",      0xc},   
  {"TNAN",    0xd},   
  {"C0AN",    0xe},   
  {"TNC0AN",  0xf},   

  // Use Zero / Non-zero
  {"NOP0",    0x0},    // no op
  {"T0",      0x1},   
  {"T0C1",    0x3},   
  {"A0",      0x4},   
  {"T0A0",    0x5},   
  {"C1A0",    0x6},   
  {"T0C1A0",  0x7},   
  {"NOP8",    0x8},    // no op  
  {"T1",      0x9},   
  {"T1C0",    0xb},   
  {"A1",      0xc},   
  {"T1A1",    0xd},   
  {"C0A1",    0xe},   
  {"T1C0A1",  0xf},   
};

// Find conditional for a given JCN (Intel 4004)
int findIntel4004JCNConditional(const String &mnemonic)
{
  for (size_t i = 0; i < sizeof(intel4004JCNConditionalSet) / sizeof(intel4004JCNConditionalSet[0]); i++) {
    if (mnemonic.equalsIgnoreCase(intel4004JCNConditionalSet[i].mnemonic)) {
      return intel4004JCNConditionalSet[i].opcode;
    }
  }
  return -1; // Invalid mnemonic
}

// Find conditional text for a given JCN 4-bit (Intel 4004)
String findIntel4004JCNConditional_toString(int byte4)
{
  for (size_t i = 0; i < sizeof(intel4004JCNConditionalSet) / sizeof(intel4004JCNConditionalSet[0]); i++) {
    if (byte4 == intel4004JCNConditionalSet[i].opcode) {
      return intel4004JCNConditionalSet[i].mnemonic;
    }
  }
  return "ERR_Conditional"; // Invalid mnemonic
}

// --------------------------------------------------------------------------------
// Disassemble of register pairs is done in the order shown below.
// if you prefer assembler format (0<, 1<, etc.), then please
// rearrange the order (move Evens/Odd's to the end of the array).
// I prefer to see the two registers names because I get ocnfused with
// 0<, 1<, etc.  easier to process when I see r01 and r23, etc.
//
// Assembly - order doesn't matter because it will match whatever you type.
// --------------------------------------------------------------------------------
const struct {
  const char *mnemonic;
  uint8_t opcode;
} intel4004RegisterSet[] = {
  // Evens
  {"r01", 0b0000},
  {"r23", 0b0010},
  {"r45", 0b0100},
  {"r67", 0b0110},
  {"r89", 0b1000},
  {"rAB", 0b1010},
  {"rCD", 0b1100},
  {"rEF", 0b1110},
  // Odds
  {"r01", 0b0001},
  {"r23", 0b0011},
  {"r45", 0b0101},
  {"r67", 0b0111},
  {"r89", 0b1001},
  {"rAB", 0b1011},
  {"rCD", 0b1101},
  {"rEF", 0b1111},
  // Assembler format
  {"0<", 0b0000},
  {"1<", 0b0001},
  {"2<", 0b0010},
  {"3<", 0b0011},
  {"4<", 0b0100},
  {"5<", 0b0101},
  {"6<", 0b0110},
  {"7<", 0b0111},
  {"8<", 0b1000},
  {"9<", 0b1001},
  {"A<", 0b1010},
  {"B<", 0b1011},
  {"C<", 0b1100},
  {"D<", 0b1101},
  {"E<", 0b1110},
  {"F<", 0b1111},
};

// Find register for a given mnemonic (Intel 4004)
int findIntel4004Register(const String &mnemonic)
{
  for (size_t i = 0; i < sizeof(intel4004RegisterSet) / sizeof(intel4004RegisterSet[0]); i++) {
    if (mnemonic.equalsIgnoreCase(intel4004RegisterSet[i].mnemonic)) {
      return intel4004RegisterSet[i].opcode;
    }
  }
  return -1; // Invalid mnemonic
}

// Find register for a given mnemonic (Intel 4004)
String findIntel4004Register_toString(int byte4)
{
  for (size_t i = 0; i < sizeof(intel4004RegisterSet) / sizeof(intel4004RegisterSet[0]); i++) {
    if (byte4 == intel4004RegisterSet[i].opcode) {
      return intel4004RegisterSet[i].mnemonic;
    }
  }
  return "ERR_Register"; // Invalid mnemonic
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// Assemble Intel 4004 code
void handleAssemble4004(int start) {
  Serial.println("\nEnter Intel 4004 assembly code (e.g., FIM 0< $28). Type 'END' to finish.");

  if (memory_check_range(start))
    memory_index_set(start);
  
  while (true) {
    retro_print4hex(memory_index_get()); Serial.print(": ");

    String line = retro_getline(false);
    Serial.print(" ");    // Add space for hex numbers.

    if ( line.startsWith(".") || line.startsWith("END") || line.startsWith("end") || (line.length() == 0))
    {
      Serial.println("Assembly complete.");
      return;
    }

    // Parse the entry (OPCODE [OPERAND1] [OPERAND2])
    int spaceIndex1 = line.indexOf(' ');
    String mnemonic = spaceIndex1 == -1 ? line : line.substring(0, spaceIndex1);
    String dataStr  = spaceIndex1 == -1 ? "0"  : line.substring(spaceIndex1 + 1);
    int spaceIndex2 = dataStr.indexOf(' ');
    String data1Str = spaceIndex2 == -1 ? dataStr : dataStr.substring(0, spaceIndex2);
    String data2Str = spaceIndex2 == -1 ? "0"     : dataStr.substring(spaceIndex2 + 1);

    int opcode   = findIntel4004Opcode(mnemonic);
    int operand1 = 0;   // actual value set below  
    int operand2 = 0;   // actual value set below
    int dest     = 0;   // used for calculation relative address in JCN

    switch(opcode)
    {
      case /* {"NOP",*/ 0x00:   
                              memory_write_index_inc(opcode);
                              Serial.print(" -> 0x");
                              retro_print2hex(opcode);
                              Serial.println();
                              break;
      case /* {"JCN",*/ 0x10:
                              operand1 = findIntel4004JCNConditional(data1Str);
                              dest = retro_c2hex(data2Str);                   

                              // JCN jumps within the current page except ...
                              // "..if JCN occupies the last 2 positions of a page or overlaps
                              // page boundary, program control is transferred to the 8bit
                              // address on the next page in sequence."   
                              operand2 = -1;                            
                              if ( ((memoryIndex & 0x0FF)  < 0xFE) && ((dest & 0xF00) == (memoryIndex & 0xF00)) )
                              {
                                  operand2 = memoryIndex & 0x0FF;
                              }
                              else 
                              if ( ((memoryIndex & 0x0FF) >= 0xFE) && ((dest & 0xF00) == ((memoryIndex & 0xF00) + 0x100)) )
                              {
                                  operand2 = (memoryIndex & 0x0FF) + 0x100;
                              }

                              if ((operand1 != -1) && (operand2 != -1))
                              {
                                memory_write_index_inc(opcode | operand1);
                                memory_write_index_inc(operand2);
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | operand1);
                                Serial.print(" ");
                                retro_print2hex(operand2);
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or address out of range.");
                              break;
      case /* {"FIM",*/ 0x20:
                              operand1 = findIntel4004Register(data1Str);
                              operand2 = retro_c2hex(data2Str);                              
                              if ((operand1 != -1) && (operand2 < 0x100))
                              {
                                memory_write_index_inc(opcode | (operand1 & 0xFE)); // Even register pair
                                memory_write_index_inc(operand2);
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | (operand1 & 0xFE));
                                Serial.print(" ");
                                retro_print2hex(operand2);
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"SRC",*/ 0x21:
                              operand1 = findIntel4004Register(data1Str);
                              if (operand1 != -1)    // Odd register pair
                              {
                                memory_write_index_inc(opcode | (operand1 | 0x01)); // Odd register pair
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | (operand1 | 0x01));
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"FIN",*/ 0x30:
                              operand1 = findIntel4004Register(data1Str);
                              if (operand1 != -1)
                              {
                                memory_write_index_inc(opcode | (operand1 & 0xFE)); // Even register pair
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | (operand1 & 0xFE));
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"JIN",*/ 0x31:
                              operand1 = findIntel4004Register(data1Str);
                              if (operand1 != -1)
                              {
                                memory_write_index_inc(opcode | (operand1 | 0x01)); // Even register pair
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | (operand1 | 0x01));
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"JUN",*/ 0x40:
      case /* {"JMS",*/ 0x50: 
                              operand1 = retro_c2hex(data1Str);                              
                              if (operand1 != -1)
                              {
                                memory_write_index_inc(opcode | ((operand1 & 0xF00) >> 8));
                                memory_write_index_inc(operand1 & 0x0FF);
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | ((operand1 & 0xF00) >> 8));
                                Serial.print(" ");
                                retro_print2hex(operand1 & 0x0FF);
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"INC",*/ 0x60:
                              operand1 = retro_c2hex(data1Str);
                              if ((operand1 >= 0) && (operand1 <= 0xf))
                              {
                                memory_write_index_inc(opcode | operand1);
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | operand1);
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"ISZ",*/ 0x70:
                              operand1 = retro_c2hex(data1Str);
                              operand2 = retro_c2hex(data2Str);                           
                              // FIX THE ADDRESS RANGE CORRECTLY. (simiar to JCN)   
                              if ((operand1 >= 0) && (operand1 <= 0xf) && (operand2 >= 0) && (operand2 < 0x100))
                              {
                                memory_write_index_inc(opcode | operand1);
                                memory_write_index_inc(operand2);
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | operand1);
                                Serial.print(" ");
                                retro_print2hex(operand2);
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;
      case /* {"ADD",*/ 0x80:
      case /* {"SUB",*/ 0x90:  
      case /* {"LD",*/  0xA0:
      case /* {"XCH",*/ 0xB0:
      case /* {"BBL",*/ 0xC0: 
      case /* {"LDM",*/ 0xD0:  
                              operand1 = retro_c2hex(data1Str);
                              if ((operand1 >= 0) && (operand1 <= 0xf))
                              {
                                memory_write_index_inc(opcode | operand1);
                                Serial.print(" -> 0x");
                                retro_print2hex(opcode | operand1);
                                Serial.println();                                
                              }
                              else
                                Serial.println("* Error: Invalid instruction or operand out of range.");
                              break;

      case /* {"WRM",*/ 0xE0:
      case /* {"WMP",*/ 0xE1:
      case /* {"WRR",*/ 0xE2:
      case /* {"WPM",*/ 0xE3:
      case /* {"WR0",*/ 0xE4:
      case /* {"WR1",*/ 0xE5:
      case /* {"WR2",*/ 0xE6:
      case /* {"WR3",*/ 0xE7:
      case /* {"SBM",*/ 0xE8:
      case /* {"RDM",*/ 0xE9:
      case /* {"RDR",*/ 0xEA:
      case /* {"ADM",*/ 0xEB:
      case /* {"RD0",*/ 0xEC:
      case /* {"RD1",*/ 0xED:
      case /* {"RD2",*/ 0xEE:
      case /* {"RD3",*/ 0xEF:
      case /* {"CLB",*/ 0xF0:
      case /* {"CLC",*/ 0xF1:
      case /* {"IAC",*/ 0xF2:
      case /* {"CMC",*/ 0xF3:
      case /* {"CMA",*/ 0xF4:
      case /* {"RAL",*/ 0xF5:
      case /* {"RAR",*/ 0xF6:
      case /* {"TCC",*/ 0xF7:
      case /* {"DAC",*/ 0xF8:
      case /* {"TCS",*/ 0xF9:
      case /* {"STC",*/ 0xFA:
      case /* {"DAA",*/ 0xFB:
      case /* {"KBP",*/ 0xFC:
      case /* {"DCL",*/ 0xFD:
                              memory_write_index_inc(opcode);
                              Serial.print(" -> 0x");
                              retro_print2hex(opcode);
                              Serial.println();
                              break;      
      default:
        Serial.println("* Error: Invalid instruction or operand out of range.");
        break;
    }
  }
}

// --------------------------------------------------------------------------------
// 
// FIX: JCN address range.
// --------------------------------------------------------------------------------
// Dump Intel 4004 memory (disassembled)
void disassemble4004(int start, int length)
{
  // Serial.println("Dumping Intel 4004 memory (disassembled):");

  if (memory_check_range(start))
    memory_index_set(start);

  if (length <1) length = 10;       // Disassemble 10 opcodes by default

  for (int i = 0; i < length; i++)
  {
    // if (i % 16 == 0) Serial.println(); // New line every 16 bytes
    uint8_t byte8 = memory_read_index();

    String  opcodeStr = "";
    uint8_t opcode    = byte8 & 0xF0;   // Top 4 bits are the opcode
    uint8_t operand1  = byte8 & 0x0F;   // Bottom 4 bits are the operand
    uint8_t operand2  = 0;              // actual value based on opcde (used below)
    uint8_t ADR3      = 0x000;          // Used calculating JCN destination address.

    // Fix instructions that use lower nibble
    // Include bit0 for {"FIM", 0x20}, {"SRC", 0x21}, {"FIN", 0x30}, {"JIN", 0x31},
    if ((opcode == 0x20) || (opcode == 0x30))
      opcode = byte8 & 0xF1;
    else
    if ((opcode == 0xE0) || (opcode == 0xF0))
      opcode = byte8 & 0xFF;

    // print address:
    retro_print4hex(memory_index_get()); Serial.print(": ");
    switch(opcode)
    {
      case /* {"NOP",*/ 0x00:   
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              Serial.print("   ");

                              Serial.print(opcodeStr);
                              Serial.println();
                              break;
      case /* {"JCN",*/ 0x10:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;

                              // JCN jumps within the current page except ...
                              // "..if JCN occupies the last 2 positions of a page or overlaps
                              // page boundary, program control is transferred to the 8bit
                              // address on the next page in sequence." 
                              ADR3 = memory_index_get() & 0xF00;
                              if ((memory_index_get() & 0x0FF) >= 0xFE)
                                ADR3 = ADR3 + 0x100;                // ignore 

                              memory_index_inc();
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              operand2 = memory_read_index();                  


                              Serial.print(opcodeStr); Serial.print(" ");
                              Serial.print(findIntel4004JCNConditional_toString(operand1)); Serial.print(" $");
                              retro_print2hex(ADR3 | operand2);
                              Serial.println();
                              break;
      case /* {"FIM",*/ 0x20:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              memory_index_inc();
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              operand2 = memory_read_index();                  

                              Serial.print(opcodeStr); Serial.print(" ");
                              Serial.print(findIntel4004Register_toString(operand1)); Serial.print(" $");
                              retro_print2hex(operand2);
                              Serial.println();
                              break;
      case /* {"SRC",*/ 0x21:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              Serial.print("   ");

                              Serial.print(opcodeStr); Serial.print(" ");
                              Serial.print(findIntel4004Register_toString(operand1));
                              Serial.println();
                              break;
      case /* {"FIN",*/ 0x30:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;             
                              Serial.print("   ");

                              Serial.print(opcodeStr); Serial.print(" ");
                              Serial.print(findIntel4004Register_toString(operand1));
                              Serial.println();
                              break;
      case /* {"JIN",*/ 0x31:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              Serial.print("   ");

                              Serial.print(opcodeStr); Serial.print(" ");
                              Serial.print(findIntel4004Register_toString(operand1));
                              Serial.println();
                              break;
      case /* {"JUN",*/ 0x40:
      case /* {"JMS",*/ 0x50: 
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              memory_index_inc();
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              operand2 = memory_read_index();                  

                              Serial.print(opcodeStr); Serial.print(" $");
                              retro_print4hex((operand1 << 8) | operand2);
                              Serial.println();
                              break;
      case /* {"INC",*/ 0x60:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              Serial.print("   ");

                              Serial.print(opcodeStr); Serial.print(" $");
                              retro_print2hex(operand1);
                              Serial.println();
                              break;
      case /* {"ISZ",*/ 0x70:
                              // TODO: fix teh address range correctly similar to JCN
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              memory_index_inc();
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              operand2 = memory_read_index();                  

                              Serial.print(opcodeStr); Serial.print(" ");
                              Serial.print(findIntel4004Register_toString(operand1)); Serial.print(" $");
                              retro_print2hex(operand2);
                              Serial.println();
                              break;
      case /* {"ADD",*/ 0x80:
      case /* {"SUB",*/ 0x90:  
      case /* {"LD",*/  0xA0:
      case /* {"XCH",*/ 0xB0:
      case /* {"BBL",*/ 0xC0: 
      case /* {"LDM",*/ 0xD0:  
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              operand1  = memory_read_index() & 0x0F;
                              Serial.print("   ");

                              Serial.print(opcodeStr); 
                              if (opcode == 0xA0)
                                Serial.print("  $");  // LD: add 1more space 
                              else
                                Serial.print(" $");   // 3-letter mnemoic
                              retro_print2hex(operand1);
                              Serial.println();
                              break;
      case /* {"WRM",*/ 0xE0:
      case /* {"WMP",*/ 0xE1:
      case /* {"WRR",*/ 0xE2:
      case /* {"WPM",*/ 0xE3:
      case /* {"WR0",*/ 0xE4:
      case /* {"WR1",*/ 0xE5:
      case /* {"WR2",*/ 0xE6:
      case /* {"WR3",*/ 0xE7:
      case /* {"SBM",*/ 0xE8:
      case /* {"RDM",*/ 0xE9:
      case /* {"RDR",*/ 0xEA:
      case /* {"ADM",*/ 0xEB:
      case /* {"RD0",*/ 0xEC:
      case /* {"RD1",*/ 0xED:
      case /* {"RD2",*/ 0xEE:
      case /* {"RD3",*/ 0xEF:
      case /* {"CLB",*/ 0xF0:
      case /* {"CLC",*/ 0xF1:
      case /* {"IAC",*/ 0xF2:
      case /* {"CMC",*/ 0xF3:
      case /* {"CMA",*/ 0xF4:
      case /* {"RAL",*/ 0xF5:
      case /* {"RAR",*/ 0xF6:
      case /* {"TCC",*/ 0xF7:
      case /* {"DAC",*/ 0xF8:
      case /* {"TCS",*/ 0xF9:
      case /* {"STC",*/ 0xFA:
      case /* {"DAA",*/ 0xFB:
      case /* {"KBP",*/ 0xFC:
      case /* {"DCL",*/ 0xFD:
                              retro_print2hex(memory_read_index()); Serial.print(" ");
                              opcodeStr = findIntel4004Opcode_toString(opcode);
                              Serial.print("   ");

                              Serial.print(opcodeStr);
                              Serial.println();
                              break; 
      default:
        Serial.println("* Error: Invalid instruction.");
        break;
    }

    memory_index_inc();

    if (Serial.available())
      if (Serial.read() == 27)
        break;
  }
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// MC14500B Instruction Set
const struct {
  const char *mnemonic;
  uint8_t opcode;
} mc14500InstructionSet[] = {
  {"NOP0",  0x0},  
  {"LD",    0x1},   
  {"LDC",   0x2}, 
  {"AND",   0x3},
  {"ANDC",  0x4},  
  {"OR",    0x5},  
  {"ORC",   0x6}, 
  {"XNOR",  0x7},
  {"STO",   0x8},  
  {"STOC",  0x9},  
  {"IEN",   0xA}, 
  {"OEN",   0xB},
  {"JMP",   0xC},  
  {"RTN",   0xD},  
  {"SKZ",   0xE}, 
  {"NOPF",  0xF}
};

// Find opcode for a given mnemonic (MC14500B)
int findMc14500Opcode(const String &mnemonic) {
  for (size_t i = 0; i < sizeof(mc14500InstructionSet) / sizeof(mc14500InstructionSet[0]); i++) {
    if (mnemonic.equalsIgnoreCase(mc14500InstructionSet[i].mnemonic)) {
      return mc14500InstructionSet[i].opcode;
    }
  }
  return -1; // Invalid mnemonic
}

// Find opcode for a given mnemonic (MC14500B)
String findMC14500Opcode_toString(int byte4)
{
  for (size_t i = 0; i < sizeof(mc14500InstructionSet) / sizeof(mc14500InstructionSet[0]); i++) {
    if (byte4 == mc14500InstructionSet[i].opcode)
    {
      String text(mc14500InstructionSet[i].mnemonic);
      text.toLowerCase();
      return text;
    }
  }
  return "ERR_Opcode"; // Invalid mnemonic
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// Assemble MC14500B code
void handleAssemble14500(int start) {
  Serial.println("Enter MC14500B assembly code (e.g., LD 5). Type 'END' or '.' to finish.");

  if (memory_check_range(start))
    memory_index_set(start);
  
  while (true) {
    retro_print4hex(memory_index_get());
    Serial.print(": ");

    String line = retro_getline(false);
    Serial.print(" ");    // Add space for hex numbers.

    if ( line.startsWith(".") || line.startsWith("END") || line.startsWith("end") || (line.length() == 0))
    {
      Serial.println("Assembly complete.");
      return;
    }

    // Parse the entry (OPCODE [OPERAND])
    int spaceIndex1 = line.indexOf(' ');
    String mnemonic = spaceIndex1 == -1 ? line : line.substring(0, spaceIndex1);
    String dataStr  = spaceIndex1 == -1 ? "0"  : line.substring(spaceIndex1 + 1);

    int opcode      = findMc14500Opcode(mnemonic);
    int operand     = 0;   // actual value will be set below  
    int instruction = 0;   // High-nibble = 4-bit opcode, low-nibble = operand (4-bit)

    switch(opcode) {
      // For instructions that do not use an operand.
      case 0x0:  // NOP0
      case 0xD:  // RTN
      case 0xE:  // SKZ
      case 0xF:  // NOPF
        operand     = 0;
        instruction = (opcode << 4) | operand;
        memory_write_index(instruction);
        Serial.print(" -> 0x");
        retro_print2hex(memory_read_index());
        memory_index_inc();
        Serial.println();
        break;
        
      // For IEN (0xA) and OEN (0xB), we hardcode the operand to 8.
      case 0xA:  // IEN
      case 0xB:  // OEN
        operand     = 0x8;
        instruction = (opcode << 4) | operand;
        memory_write_index(instruction);
        Serial.print(" -> 0x");
        retro_print2hex(memory_read_index());
        memory_index_inc();
        Serial.println();
        break;
      
      // For instructions that require an operand.
      case 0x1:  // LD
      case 0x2:  // LDC
      case 0x3:  // AND
      case 0x4:  // ANDC
      case 0x5:  // OR
      case 0x6:  // ORC
      case 0x7:  // XNOR
      case 0x8:  // STO
      case 0x9:  // STOC
      case 0xC:  // JMP
        operand     = retro_c2hex(dataStr);
        if ((operand >= 0) && (operand <= 0x0F)) {
          instruction = (opcode << 4) | operand;
          memory_write_index(instruction);
          Serial.print(" -> 0x");
          retro_print2hex(memory_read_index());
          memory_index_inc();
          Serial.println();
        }
        else
          Serial.println("ERR: Invalid instruction or operand out of range.");
        break;
      
      default:
        Serial.println("* Error: Invalid instruction or operand out of range.");
        break;
    }
  }
}


// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// Dump MC14500B memory (disassembled)
void disassemble14500B(int start, int length)
{
  // Serial.println("Dumping MC14500B memory (disassembled):");

  if (memory_check_range(start))
    memory_index_set(start);

  if (length <1) length = 10;       // Disassemble 10 opcodes by default

  for (int i = 0; i < length; i++)
  {
    // if (i % 16 == 0) Serial.println(); // New line every 16 bytes
    uint8_t byte8 = memory_read_index();

    String  opcodeStr = "";
    uint8_t opcode    = (byte8 & 0xF0) >> 4;  // Top 4 bits are the opcode
    uint8_t operand  = byte8 & 0x0F;         // Bottom4 bits are the operand

    // print address:
    retro_print4hex(memory_index_get()); Serial.print(": ");
    switch(opcode)
    {
      case /* {"NOP0",*/   0x0:
      case /* {"IEN",*/    0xA:
      case /* {"OEN",*/    0xB:
      case /* {"RTN",*/    0xD:
      case /* {"SKZ",*/    0xE:
      case /* {"NOPF",*/   0xF:
                                  retro_print2hex(memory_read_index()); Serial.print(" ");
                                  opcodeStr = findMC14500Opcode_toString(opcode);
                                  Serial.print("   ");

                                  Serial.print(opcodeStr);
                                  Serial.println();
                                  break;
      case /* {"LD",*/     0x1:
      case /* {"LDC",*/    0x2:
      case /* {"AND",*/    0x3:
      case /* {"ANDC",*/   0x4:
      case /* {"OR", */    0x5:
      case /* {"ORC",*/    0x6:
      case /* {"XNOR",*/   0x7:
      case /* {"STO",*/    0x8:
      case /* {"STOC",*/   0x9:
      case /* {"JMP",*/    0xC:
                                  retro_print2hex(memory_read_index()); Serial.print(" ");
                                  opcodeStr = findMC14500Opcode_toString(opcode);
                                  operand   = memory_read_index() & 0x0F;
                                  Serial.print("   ");

                                  Serial.print(opcodeStr);
                                  if ((opcode == 0x1) || (opcode == 0x5))
                                  {
                                    Serial.print("   ");  // 2-letter opcode
                                  }
                                  else
                                  if ((opcode == 0x4) || (opcode == 0x7) || (opcode == 0x9))
                                    Serial.print(" ");    // 4-letter opcde
                                  else
                                    Serial.print("  ");   // 3-letter opcode

                                  retro_print1hex(operand);
                                  Serial.println();
                                  break;
      default:
                                  Serial.println("* Error: Invalid instruction or operand out of range.");
                                  break;
    }

    memory_index_inc();

    if (Serial.available())
      if (Serial.read() == 27)
        break;
  }
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
void assemble(int addr, bool inc_index)
{
  int org_index = memory_index_get();

  if (memory_check_range(addr))
  {
    if (shell_is4004)   handleAssemble4004(addr);
    else
    if (shell_is14500B) handleAssemble14500(addr);
    else
    {
      Serial.println("ERR: Unknown architecture.");
    }  
  }

  // Restore index if it should not incremented
  if (!inc_index)
    memory_index_set(org_index);
}

void disassemble(int addr, int length, bool inc_index)
{
  int org_index = memory_index_get();

  if (memory_check_range(addr))
  {
    if (shell_is4004)   disassemble4004(addr, length);
    else
    if (shell_is14500B) disassemble14500B(addr, length);
    else
    {
      Serial.println("ERR: Unknown architecture.");
    }  
  }

  // Restore index if it should not incremented
  if (!inc_index)
    memory_index_set(org_index);
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// Edit memory at a specific address with a hex value
void handleEditMemory(int start) {
  Serial.println("Enter byte then RETURN to edit next location. Enter END to exit.");
  
  if (memory_check_range(start))
    memory_index_set(start);

  while (true) {
    retro_print4hex(memory_index_get());  Serial.print(": ");  
    retro_print2hex(memory_read_index()); Serial.print(" => ");

    String line = retro_getline(false);
    Serial.print("  /");    // Add space for hex numbers.

    if ( line.startsWith(".") || line.startsWith("END") || line.startsWith("end") || (line.length() == 0))
    {
      Serial.println("Edit complete.");
      return;
    }

    int hexValue = retro_c2hex(line); 

    if ((hexValue < 0) || (hexValue > 0xFF))
    {
      Serial.println("ERR - Must be a 8bit value.");
    }
    else {
      memory_write_index((uint8_t)hexValue);
      retro_print2hex(memory_read_index());
      memory_index_inc();
      Serial.println();
    }
  }
}


// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
// Dump memory with 16 bytes and corresponding ASCII representation
void dumpMemoryWithASCII(int start, int length) {
  // Serial.println("Memory dump (16 bytes with ASCII):");

  int newlength;

  if (memory_check_range(start) && (length > 0))
  {
    memory_index_set(start & 0xFFF0);
    newlength = length;
  } else {
    memory_index_set( memory_index_get() & 0xFFF0);
    newlength = 8*16;
  }

  // Iterate through memory in chunks of 16 bytes
  for (int i = 0; i < newlength; i += 16)
  {
    // Print the memory address for the row
    retro_print4hex(memory_index_get());
    Serial.print(": ");
    
    // Print the 16 bytes in hexadecimal format
    String ascii = "";  // To store ASCII characters
    for (int j = 0; j < 16; j++)
    {
      int index =  i + j;
      
      if (index < newlength) {
        uint8_t byte8 = memory_read_index_inc();
        retro_print2hex(byte8);
        Serial.print(" ");
        
        // Append the ASCII character if printable
        if ((byte8 >= 32) && (byte8 <= 126)) {
          ascii += (char) byte8; // Printable character
        } else {
          ascii += "."; // Non-printable character
        }
      } else {
        // For addresses beyond the end of the memory, print empty bytes
        Serial.print("   ");
        ascii += " "; // Empty space for non-existing byte
      }
    }
    
    // Print ASCII characters on the right side of the dump
    Serial.print(" | ");
    Serial.println(ascii);
  }
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
void printHelp()
{
  Serial.println();
  Serial.println("RetroShield Shell with Assembler");
  Serial.println("================================");
  Serial.println("help                    - Show available commands");
  Serial.println("hex                     - Entry is hexadecimal. Use # for dec entry.");
  Serial.println("dec                     - Entry is decimal.     Use $ for hex entry.");
  Serial.println("m      <addr> [<len>]   - Dump memory contents");
  Serial.println("e      <addr>           - Edit memory contents");
  Serial.println("a      <addr>           - Assemble");
  Serial.println("d      <addr> [<len>]   - Disassemble");
  Serial.println("i                       - Print info (very limited)");
  Serial.println("pp                      - Print ports and memory");
  Serial.println("ps     <port> <bit>     - Set output port or memory bits");
  Serial.println("restore                 - Restore ROM contents to original");
  Serial.println("reset                   - Reset processor");
  // Serial.println("exit                    - Exit shell (without resetting processor)");
  Serial.println("go                      - Exit shell and continue running processor");
  Serial.println("s                       - Single-step, then back to shell ");
  Serial.println();
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------

bool processCommand(String command)
{
  // ######################################################################
  if (command.startsWith("help") || command.startsWith("?"))
  {
    printHelp();
  }
  else
  // ######################################################################
  if (command.startsWith("go") || command.startsWith("exit") || command.startsWith("run"))
  {
    Serial.print("Processor will continue at $"); retro_print4hex(processor_stopped_addr);
    Serial.println(". Proceed? (y/n): ");
    String line = retro_getline(true);
    if (line.startsWith("y") || line.startsWith("Y"))
    {
      Serial.println("Exiting shell.");
      Serial.println();
      return false;
    }
    else
      Serial.println("Exit aborted.");
  }
  else
  // ######################################################################
  if (command.startsWith("reset"))
  {
    uP_assert_reset();
    uP_release_reset();
    Serial.println("Processor reset.");

    // Reset what we know, as much as we know.
    if (shell_is4004)   processor_stopped_addr = 0x00;
    if (shell_is14500B) processor_stopped_addr = 0x00;

    Serial.println("New PC:");
    disassemble(processor_stopped_addr, 1, false);

    return true;
  }
  else  
  // ######################################################################
  if (command.startsWith("restore"))
  {
    Serial.println("Restore memory to original ROM.");
    Serial.print("Are you sure? (y/n): ");
    String line = retro_getline(true);
    if (line.startsWith("y") || line.startsWith("Y"))
    {
      memory_restore_original();
      Serial.println("Memory restored to original ROM.");
    }
    else
      Serial.println("Restore aborted.");
  }
  else
  // ######################################################################
  if (command.startsWith("hex")) 
  {
    globalHex = true;
    Serial.println("Default entry is hexadecimal. Prefix # for dec entry.");
  }
  else
  // ######################################################################
  if (command.startsWith("dec")) 
  {
    globalHex = false;
    Serial.println("Default entry is decimal. Prefix $ for hex entry.");
  }
  else 
  // ######################################################################
  if (command.startsWith("s")) 
  {
    // Prep for single-step.
    exit_with_singleStep = true;

    // Serial.println("running");
    // if (shell_is4004)   disassemble4004(processor_stopped_addr, 1);
    // if (shell_is14500B) disassemble14500B(processor_stopped_addr, 1);
    // Serial.println();
    
    return false;
  }
  else 
  // ######################################################################
  if (command.startsWith("a")) 
  {
    String addrStr = command.charAt(1) == ' ' ? command.substring(2) : command.substring(1);
    int addr = retro_c2hex(addrStr);

    if (memory_check_range(addr))
     assemble(addr, true);
    else
      Serial.println("ERR - missing or invalid address. Try 'a <addr>'.");
  }
  else 
  // ######################################################################
  if (command.startsWith("d")) 
  {
    // Parse the line
    String args = command.charAt(1) == ' ' ? command.substring(2) : command.substring(1);
    int spaceIndex   = args.indexOf(' ');
    String addrStr   = spaceIndex == -1 ? args : args.substring(0, spaceIndex);
    String lengthStr = spaceIndex == -1 ? "0"  : args.substring(spaceIndex + 1);

    int addr    = retro_c2hex(addrStr);
    int length  = retro_c2hex(lengthStr);

    if (memory_check_range(addr))
      disassemble(addr, length, true);   
    else
      Serial.println("ERR - missing or invalid address. Try 'd <addr> [length]'.");      
  }
  else 
  // ######################################################################
  if (command.startsWith("m")) 
  {
    // Parse the line
    String args = command.charAt(1) == ' ' ? command.substring(2) : command.substring(1);
    int spaceIndex   = args.indexOf(' ');
    String addrStr   = spaceIndex == -1 ? args : args.substring(0, spaceIndex);
    String lengthStr = spaceIndex == -1 ? "0"  : args.substring(spaceIndex + 1);

    int addr    = retro_c2hex(addrStr);
    int length  = retro_c2hex(lengthStr);

    dumpMemoryWithASCII(addr, length);
  } 
  else
  // ######################################################################
  if (command.startsWith("e")) 
  {
    String addrStr = command.charAt(1) == ' ' ? command.substring(2) : command.substring(1);
    int addr = retro_c2hex(addrStr);

    if (memory_check_range(addr))
      handleEditMemory(addr);
    else
      Serial.println("ERR - missing or invalid address. Try 'e <addr>'.");    
  }
  else 
  // ######################################################################
  if (command.startsWith("pp")) 
  {
    shell_port_print();
  }
  else   
  // ######################################################################
  if (command.startsWith("ps")) 
  {
    // Parse the line
    String args      = command.charAt(2) == ' ' ? command.substring(3) : command.substring(2);
    int spaceIndex   = args.indexOf(' ');
    String portStr   = spaceIndex == -1 ? args : args.substring(0, spaceIndex);
    String bitStr    = spaceIndex == -1 ? "-1"  : args.substring(spaceIndex + 1);

    int port    = retro_c2hex(portStr);
    int bit     = retro_c2hex(bitStr);

    shell_port_set(port, bit);
  }   
  else
  // ######################################################################
  if (command.startsWith("i")) 
  {
    // Reset what we know, as much as we know.
    if (shell_is4004)   Serial.println("CPU:  4004");
    else
    if (shell_is14500B) Serial.println("CPU:  14500");
    else
      Serial.println("CPU:  undefined");

    Serial.print("PC:   "); retro_print4hex(processor_stopped_addr); Serial.println();
    disassemble(processor_stopped_addr, 1, false);
  } 
  else
  // ######################################################################
  {
    Serial.println("Unknown command. Type 'help' for available commands.");
  }

  return true;  // Shell active
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
void shell_setup(String shellName) {
  // Serial.begin(115200);
  // while (!Serial);

  exit_with_singleStep = false;

  memory_save_original(); 
  memory_index_set(SHELL_MEMORY_START);

  if (shellName == "14500B")
    shell_is14500B = true;
  else
  if (shellName == "4004")
    shell_is4004 = true;
  else
    Serial.print("INFO: Unknown shell name: ");
    // while(1);

  Serial.println(shellName);
}

// --------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------------
bool shell_loop(int uP_ADDR)
{  
  bool shell_active = true;

  String input = "";

  if (!exit_with_singleStep)            // if coming back from single-step, don't print again.
  {
    processCommand("help");
    processCommand("hex");
    Serial.println();
  }
  else
    exit_with_singleStep = false;       // Clear flag.

  
  processor_stopped_addr = uP_ADDR;

  disassemble(processor_stopped_addr, 1, false);
  
  while(shell_active) {
    retro_prompt();
    input = retro_getline(true);

    if (input.length() > 0)
    {
      shell_active = processCommand(input);
    }
  }

  return exit_with_singleStep;
  // true:  if user wants to single-step
  // false: o.w.
}
