/* http://srecord.sourceforge.net/ */
const unsigned char eprom[] =
{
0x07, 0x3F, 0x20, 0xCF, 0x44, 0x00, 0x5B, 0x7B, 0x04, 0x77, 0xCC, 0x04,
0x09, 0x04, 0x1B, 0xCC, 0x04, 0x0B, 0x04, 0x80, 0xCC, 0x04, 0x0C, 0x1B,
0x09, 0x01, 0x60, 0x01, 0x6E, 0x04, 0x3F, 0x3F, 0x02, 0xB4, 0x75, 0xFF,
0x3F, 0x00, 0x8A, 0x04, 0x2A, 0x3F, 0x02, 0xB4, 0x3B, 0x2D, 0x20, 0xCC,
0x04, 0x27, 0x0C, 0x04, 0x13, 0xE4, 0x41, 0x1C, 0x00, 0xAB, 0xE4, 0x42,
0x1C, 0x01, 0xE5, 0xE4, 0x43, 0x1C, 0x01, 0xCA, 0xE4, 0x44, 0x1C, 0x03,
0x10, 0xE4, 0x47, 0x1C, 0x01, 0x3A, 0xE4, 0x4C, 0x1C, 0x03, 0xB5, 0xE4,
0x53, 0x1C, 0x00, 0xF4, 0x1F, 0x00, 0x1D, 0x07, 0xFF, 0xCF, 0x04, 0x27,
0xE7, 0x14, 0x18, 0x19, 0x3F, 0x02, 0x86, 0xE4, 0x7F, 0x98, 0x0E, 0xE7,
0xFF, 0x18, 0x71, 0x0F, 0x64, 0x13, 0x3F, 0x02, 0xB4, 0xA7, 0x01, 0x1B,
0x67, 0xE4, 0x0D, 0x98, 0x18, 0x05, 0x01, 0x03, 0x1A, 0x02, 0x85, 0x02,
0xCD, 0x04, 0x2B, 0xCF, 0x04, 0x29, 0x04, 0x0D, 0x3F, 0x02, 0xB4, 0x04,
0x0A, 0x3F, 0x02, 0xB4, 0x17, 0x05, 0x02, 0xE4, 0x0A, 0x18, 0x64, 0xCF,
0x24, 0x13, 0x3F, 0x02, 0xB4, 0x1F, 0x00, 0x60, 0xCD, 0x04, 0x0D, 0xCE,
0x04, 0x0E, 0x17, 0x3F, 0x02, 0xDB, 0x3B, 0x74, 0x3F, 0x02, 0x69, 0x0D,
0x04, 0x0E, 0x3F, 0x02, 0x69, 0x3F, 0x03, 0x5B, 0x0D, 0x84, 0x0D, 0x3F,
0x02, 0x69, 0x3F, 0x03, 0x5B, 0x3F, 0x00, 0x5B, 0x0C, 0x04, 0x2B, 0xE4,
0x02, 0x1E, 0x00, 0x22, 0x18, 0x11, 0xCC, 0x04, 0x11, 0x3F, 0x02, 0xDB,
0xCE, 0x84, 0x0D, 0x0C, 0x04, 0x11, 0xE4, 0x04, 0x9C, 0x00, 0x22, 0x06,
0x01, 0x8E, 0x04, 0x0E, 0x05, 0x00, 0x77, 0x08, 0x8D, 0x04, 0x0D, 0x75,
0x08, 0x1F, 0x00, 0xAE, 0x3F, 0x02, 0xDB, 0xE6, 0x08, 0x1D, 0x00, 0x1D,
0xCE, 0x04, 0x11, 0x0E, 0x64, 0x00, 0xC1, 0x3F, 0x02, 0x69, 0x3F, 0x03,
0x5B, 0x3F, 0x00, 0x5B, 0x0C, 0x04, 0x2B, 0xE4, 0x02, 0x1E, 0x00, 0x22,
0x18, 0x1C, 0xCC, 0x04, 0x0F, 0x3F, 0x02, 0xDB, 0x02, 0x0E, 0x04, 0x11,
0xCE, 0x64, 0x00, 0xE6, 0x08, 0x98, 0x03, 0xCC, 0x04, 0x0A, 0x0C, 0x04,
0x0F, 0xE4, 0x03, 0x1C, 0x00, 0x22, 0x0E, 0x04, 0x11, 0x86, 0x01, 0x1F,
0x00, 0xF7, 0x3F, 0x02, 0xDB, 0x3F, 0x00, 0xA4, 0x0C, 0x04, 0x07, 0x92,
0x0D, 0x04, 0x01, 0x0E, 0x04, 0x02, 0x0F, 0x04, 0x03, 0x77, 0x10, 0x0D,
0x04, 0x04, 0x0E, 0x04, 0x05, 0x0F, 0x04, 0x06, 0x0C, 0x04, 0x00, 0x75,
0xFF, 0x1F, 0x04, 0x09, 0xCC, 0x04, 0x00, 0x13, 0xCC, 0x04, 0x08, 0xCC,
0x04, 0x0A, 0x04, 0x00, 0x1B, 0x0C, 0xCC, 0x04, 0x00, 0x13, 0xCC, 0x04,
0x08, 0xCC, 0x04, 0x0A, 0x04, 0x01, 0xCC, 0x04, 0x11, 0x12, 0xCC, 0x04,
0x07, 0x77, 0x10, 0xCD, 0x04, 0x04, 0xCE, 0x04, 0x05, 0xCF, 0x04, 0x06,
0x75, 0x10, 0xCD, 0x04, 0x01, 0xCE, 0x04, 0x02, 0xCF, 0x04, 0x03, 0x0E,
0x04, 0x11, 0x3B, 0x0F, 0x0D, 0x04, 0x0D, 0x3F, 0x02, 0x69, 0x0D, 0x04,
0x0E, 0x3F, 0x02, 0x69, 0x1F, 0x00, 0x22, 0x20, 0xCE, 0x64, 0x2C, 0x0E,
0x64, 0x32, 0xCC, 0x04, 0x0D, 0x0E, 0x64, 0x34, 0xCC, 0x04, 0x0E, 0x0E,
0x64, 0x2E, 0xCC, 0x84, 0x0D, 0x0E, 0x64, 0x30, 0x07, 0x01, 0xCF, 0xE4,
0x0D, 0x17, 0x3B, 0x0B, 0x0E, 0x64, 0x2C, 0x1C, 0x00, 0x1D, 0x3B, 0x57,
0x1F, 0x00, 0x22, 0x3F, 0x02, 0xDB, 0xA6, 0x01, 0x1E, 0x02, 0x50, 0xE6,
0x01, 0x1D, 0x02, 0x50, 0x17, 0x3B, 0x70, 0x0E, 0x64, 0x2C, 0xBC, 0x01,
0xAB, 0xCE, 0x04, 0x11, 0x3F, 0x02, 0xDB, 0x3F, 0x00, 0xA4, 0x0F, 0x04,
0x11, 0x02, 0xCF, 0x64, 0x34, 0x01, 0xCF, 0x64, 0x32, 0x0C, 0x84, 0x0D,
0xCF, 0x64, 0x2E, 0x05, 0x9B, 0xCD, 0x84, 0x0D, 0x06, 0x01, 0x0E, 0xE4,
0x0D, 0xCF, 0x64, 0x30, 0x0F, 0x62, 0x22, 0xCE, 0xE4, 0x0D, 0x04, 0xFF,
0xCF, 0x64, 0x2C, 0x1F, 0x00, 0x22, 0x99, 0x9B, 0x3F, 0x02, 0x86, 0x3B,
0x1D, 0xD3, 0xD3, 0xD3, 0xD3, 0xCF, 0x04, 0x12, 0x3F, 0x02, 0x86, 0x3B,
0x11, 0x6F, 0x04, 0x12, 0x03, 0xC1, 0x3B, 0x01, 0x17, 0x01, 0x2C, 0x04,
0x2A, 0xD0, 0xCC, 0x04, 0x2A, 0x17, 0x07, 0x10, 0xEF, 0x42, 0x59, 0x14,
0xE7, 0x01, 0x9A, 0x78, 0x0C, 0x04, 0x07, 0x64, 0x40, 0x12, 0x1F, 0x00,
0x1D, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41,
0x42, 0x43, 0x44, 0x45, 0x46, 0xCD, 0x04, 0x12, 0x3B, 0x4F, 0x51, 0x51,
0x51, 0x51, 0x45, 0x0F, 0x0D, 0x62, 0x59, 0x3F, 0x02, 0xB4, 0x0D, 0x04,
0x12, 0x45, 0x0F, 0x0D, 0x62, 0x59, 0x3F, 0x02, 0xB4, 0x17, 0x77, 0x10,
0x04, 0x80, 0xB0, 0x05, 0x00, 0x06, 0x08, 0x12, 0x1A, 0x74, 0x20, 0xB0,
0x3B, 0x19, 0x3B, 0x10, 0x12, 0x44, 0x80, 0x51, 0x61, 0xC1, 0xFA, 0x76,
0x3B, 0x06, 0x45, 0x7F, 0x01, 0x75, 0x18, 0x17, 0x20, 0x04, 0x20, 0xF8,
0x7E, 0xC0, 0xC0, 0x04, 0x05, 0xF8, 0x7E, 0x17, 0x77, 0x10, 0x76, 0x40,
0xC2, 0x05, 0x08, 0x3B, 0x6B, 0x3B, 0x69, 0x74, 0x40, 0x3B, 0x65, 0x52,
0x1A, 0x04, 0x74, 0x40, 0x1B, 0x02, 0x76, 0x40, 0xF9, 0x73, 0x3B, 0x58,
0x76, 0x40, 0x75, 0x10, 0x17, 0x0C, 0x04, 0x2B, 0x18, 0x07, 0x17, 0x20,
0xC1, 0xC2, 0xCC, 0x04, 0x2B, 0x0F, 0x04, 0x27, 0xEF, 0x04, 0x29, 0x14,
0x0F, 0x24, 0x13, 0xCF, 0x04, 0x27, 0xE4, 0x20, 0x18, 0x63, 0x3F, 0x02,
0x46, 0x04, 0x0F, 0xD2, 0xD2, 0xD2, 0xD2, 0x42, 0xD1, 0xD1, 0xD1, 0xD1,
0x45, 0xF0, 0x46, 0xF0, 0x61, 0xC1, 0x03, 0x62, 0xC2, 0x04, 0x01, 0xCC,
0x04, 0x2B, 0x1B, 0x51, 0x3B, 0x49, 0x3F, 0x00, 0xA4, 0x3B, 0x44, 0x86,
0x01, 0x77, 0x08, 0x85, 0x00, 0x75, 0x08, 0xCD, 0x04, 0x0F, 0xCE, 0x04,
0x10, 0x3B, 0x38, 0x04, 0xFF, 0xCC, 0x04, 0x29, 0x3F, 0x00, 0x8A, 0x04,
0x3A, 0x3F, 0x02, 0xB4, 0x20, 0xCC, 0x04, 0x2A, 0x0D, 0x04, 0x0F, 0x0E,
0x04, 0x10, 0xAE, 0x04, 0x0E, 0x77, 0x08, 0xAD, 0x04, 0x0D, 0x75, 0x08,
0x1E, 0x00, 0x1D, 0x19, 0x1C, 0x5A, 0x1C, 0x07, 0x04, 0x3F, 0x02, 0x69,
0xFB, 0x7B, 0x3B, 0x07, 0x1F, 0x00, 0x22, 0x07, 0x03, 0x1B, 0x02, 0x07,
0x32, 0x04, 0x20, 0x3F, 0x02, 0xB4, 0xFB, 0x79, 0x17, 0x06, 0xFF, 0xCE,
0x04, 0x28, 0x0D, 0x04, 0x0D, 0x3F, 0x02, 0x69, 0x0D, 0x04, 0x0E, 0x3F,
0x02, 0x69, 0x0D, 0x04, 0x28, 0x3F, 0x02, 0x69, 0x0D, 0x04, 0x2A, 0x3F,
0x02, 0x69, 0x0F, 0x04, 0x29, 0x0F, 0xA4, 0x0D, 0xEF, 0x04, 0x28, 0x18,
0x09, 0xCF, 0x04, 0x29, 0xC1, 0x3F, 0x02, 0x69, 0x1B, 0x6C, 0x0D, 0x04,
0x2A, 0x3F, 0x02, 0x69, 0x0E, 0x04, 0x0E, 0x8E, 0x04, 0x28, 0x05, 0x00,
0x77, 0x08, 0x8D, 0x04, 0x0D, 0x75, 0x08, 0x3F, 0x00, 0xA4, 0x1F, 0x03,
0x25, 0x3F, 0x02, 0x86, 0xE4, 0x3A, 0x98, 0x79, 0x20, 0xCC, 0x04, 0x2A,
0x3F, 0x02, 0x24, 0xCD, 0x04, 0x0D, 0x3F, 0x02, 0x24, 0xCD, 0x04, 0x0E,
0x3F, 0x02, 0x24, 0x59, 0x03, 0x1F, 0x84, 0x0D, 0xCD, 0x04, 0x28, 0x3F,
0x02, 0x24, 0x0C, 0x04, 0x2A, 0x9C, 0x00, 0x1D, 0xC3, 0xCF, 0x04, 0x29,
0x3F, 0x02, 0x24, 0x0F, 0x04, 0x29, 0xEF, 0x04, 0x28, 0x18, 0x06, 0x01,
0xCF, 0xE4, 0x0D, 0xDB, 0x6C, 0x0C, 0x04, 0x2A, 0x9C, 0x00, 0x1D, 0x1F,
0x03, 0xB5, 0x00, 0x00,
};
const unsigned long eprom_termination = 0x00000000;
const unsigned long eprom_start       = 0x00000000;
const unsigned long eprom_finish      = 0x00000400;
const unsigned long eprom_length      = 0x00000400;

#define EPROM_TERMINATION 0x00000000
#define EPROM_START       0x00000000
#define EPROM_FINISH      0x00000400
#define EPROM_LENGTH      0x00000400
