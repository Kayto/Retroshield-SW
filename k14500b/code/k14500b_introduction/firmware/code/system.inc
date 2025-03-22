;
; MC14500 assembler using ca65 macros
; Yaroslav Veremenko (c) 2022
; Adjusted for MC14500B 4-bit jump limitation ($00-$0F), no runtime checks
;

.feature ubiquitous_idents
.feature string_escapes
.setcpu "none"

; Instruction set (unchanged)
.define I_NOP0 0
.define I_LD 1
.define I_LDC 2
.define I_AND 3
.define I_ANDC 4
.define I_OR 5
.define I_ORC 6
.define I_XNOR 7
.define I_STO 8
.define I_STOC 9
.define I_IEN 10
.define I_OEN 11
.define I_JMP 12
.define I_RTN 13
.define I_SKZ 14
.define I_NOPF 15

; I/O and memory mapping (unchanged)
RR = $8
IN1 = $9
IN2 = $A
IN3 = $B
IN4 = $C
IN5 = $D
IN6 = $E
IN7 = $F

MEM0 = $0
MEM1 = $1
MEM2 = $2
MEM3 = $3
MEM4 = $4
MEM5 = $5
MEM6 = $6
MEM7 = $7

OUT0 = $8
OUT1 = $9
OUT2 = $A
OUT3 = $B
OUT4 = $C
OUT5 = $D
OUT6 = $E
OUT7 = $F

.macro __lit_instr op, addr
    ; MC14500B uses 4-bit address field ($00-$0F) for jmp.
    ; Addresses beyond $0F are masked to low 4 bits ($00-$0F).
    ; Ensure targets are within $00-$0F manually, or use multi-step jumps/paging for larger addresses.
    .byte <(((op) << 4) | ((<(addr)) & $0F))
.endmacro

.macro __instr op, addr
    __lit_instr op, addr
.endmacro

; Instruction macros (unchanged)
.macro nop0 addr
.ifblank addr
    __instr I_NOP0, 0
.else
    __instr I_NOP0, addr
.endif
.endmacro
.macro ld addr
    __instr I_LD, addr
.endmacro
.macro ldc addr
    __instr I_LDC, addr
.endmacro
.macro and addr
    __instr I_AND, addr
.endmacro
.macro andc addr
    __instr I_ANDC, addr
.endmacro
.macro or addr
    __instr I_OR, addr
.endmacro
.macro orc addr
    __instr I_ORC, addr
.endmacro
.macro xnor addr
    __instr I_XNOR, addr
.endmacro
.macro sto addr
    __instr I_STO, addr
.endmacro
.macro stoc addr
    __instr I_STOC, addr
.endmacro
.macro ien addr
    __instr I_IEN, addr
.endmacro
.macro oen addr
    __instr I_OEN, addr
.endmacro
.macro jmp addr
.ifblank addr
    __instr I_JMP, 0
.else
    __instr I_JMP, addr
.endif
.endmacro
.macro rtn
    __instr I_RTN, 0
.endmacro
.macro skz
    __instr I_SKZ, 0
.endmacro
.macro nopf addr
.ifblank addr
    __instr I_NOPF, 0
.else
    __instr I_NOPF, addr
.endif
.endmacro