/* http://srecord.sourceforge.net/ */
const unsigned char rom_bin[] =
{
0x21, 0x00, 0xC0, 0xF9, 0xCD, 0x35, 0x00, 0x3E, 0x38, 0x4F, 0xCD, 0x56,
0x00, 0x3E, 0x30, 0x4F, 0xCD, 0x56, 0x00, 0x3E, 0x38, 0x4F, 0xCD, 0x56,
0x00, 0x3E, 0x35, 0x4F, 0xCD, 0x56, 0x00, 0x3E, 0x0D, 0x4F, 0xCD, 0x56,
0x00, 0x3E, 0x0A, 0x4F, 0xCD, 0x56, 0x00, 0xCD, 0x4C, 0x00, 0x4F, 0xCD,
0x56, 0x00, 0xC3, 0x2B, 0x00, 0x3E, 0x00, 0xD3, 0x09, 0xD3, 0x09, 0xD3,
0x09, 0x3E, 0x40, 0xD3, 0x09, 0x3E, 0x4E, 0xD3, 0x09, 0x3E, 0x37, 0xD3,
0x09, 0xDB, 0x08, 0xC9, 0xDB, 0x09, 0xE6, 0x02, 0xCA, 0x4C, 0x00, 0xDB,
0x08, 0xC9, 0xDB, 0x09, 0xE6, 0x01, 0xCA, 0x56, 0x00, 0x79, 0xD3, 0x08,
0xC9,
};
const unsigned long rom_bin_termination = 0x00000000;
const unsigned long rom_bin_start       = 0x00000000;
const unsigned long rom_bin_finish      = 0x00000061;
const unsigned long rom_bin_length      = 0x00000061;

#define ROM_BIN_TERMINATION 0x00000000
#define ROM_BIN_START       0x00000000
#define ROM_BIN_FINISH      0x00000061
#define ROM_BIN_LENGTH      0x00000061
