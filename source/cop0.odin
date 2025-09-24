package main

import "core:fmt"

//n/a       0
//n/a       1
//n/a       2
bpc ::      3
//n/a       4
bda ::      5
jmpdest ::  6
dcic ::     7
badvaddr :: 8
bdam ::     9
//n/a       10
bpcm ::     11
sr ::       12
cause ::    13
epc ::      14
prid ::     15
//16-31 garbage

IRQ :: enum {
    VBLANK  = 0x0001,
    GPU     = 0x0002,
    CDROM   = 0x0004,
    DMA     = 0x0008,
    TMR0    = 0x0010,
    TMR1    = 0x0020,
    TMR2    = 0x0040,
    IO      = 0x0080,
    SIO     = 0x0100,
    SPU     = 0x0200,
    PEN     = 0x0400,
}

Exception :: enum {
    intr,
    mod,
    tlbl,
    tlbs,
    adel,
    ades,
    ibe,
    dbe,
    syscall,
    bp,
    ri,
    cpu,
    ov,
}

@(private="file")
cop0_lo: [32]u32
@(private="file")
irq_status: u32
@(private="file")
irq_mask: u32

cop0_get :: proc(reg: u32) -> u32 {
    switch reg {
    case bpc, bda..=bdam, bpcm..=epc:
        return cop0_lo[reg]
    case prid:
        return 0x02
    case 0, 1, 2, 4, 10, 32..=63:
        cop0_exception(.ri)
    }
    return 0
}

cop0_set :: proc(reg: u32, value: u32) {
    switch reg {
    case bpc, bda, bdam, bpcm:
        cop0_lo[reg] = value
    case sr:
        cop0_lo[reg] = (value & 0xF27FFF3F)
    case cause:
        cop0_lo[reg] = (value & 0x00000300)
    case dcic:
        cop0_lo[reg] = (value & 0xFF80F03F)
    }
}

cop0_exception :: proc(exc: Exception) {
    cop0_lo[cause] &= 0xFFFFFF80
    cop0_lo[cause] |= (u32(exc) << 2)

    if exc == Exception.adel || exc == Exception.ades {
        cop0_lo[badvaddr] = pc
    }

    if delay {
        cop0_lo[epc] = last_pc - 4
        cop0_lo[cause] |= 0x80000000
    } else {
        cop0_lo[epc] = last_pc
    }

    if (exc == .intr) && ((cop0_lo[epc] & 0xFE000000) == 0x4A000000) {
        cop0_lo[epc] += 4
    }

    mode := cop0_lo[sr] & 0x3F

    cop0_lo[sr] &= 0xFFFFFFC0
    cop0_lo[sr] |= (mode << 2) & 0x3F

    if (cop0_lo[sr] & 0x400000) != 0 {
        pc = 0xbfc00180
    } else {
        pc = 0x80000080
    }
    next_pc = pc + 4
}

cop0_return :: proc() {
    mode := cop0_lo[sr] & 0x3F
    cop0_lo[sr] &= 0xFFFFFFF0
    cop0_lo[sr] |= (mode >> 2)
}

cop0_set_mask :: proc(value: u32) {
    irq_mask = value & 0x7FF
    if (irq_status & irq_mask) > 0 {
        cop0_lo[cause] |= 0x400
    } else {
        cop0_lo[cause] &= 0xFFFFFBFF
    }
}

cop0_get_mask :: proc() -> u32 {
    return irq_mask
}

cop0_set_status :: proc(value: u32) {
    irq_status &= (value & 0x7FF)
    if (irq_status & irq_mask) == 0 {
        cop0_lo[cause] &= 0xFFFFFBFF
    }
}

cop0_get_status :: proc() -> u32 {
    return irq_status
}

cop0_set_irq :: proc(value: IRQ) {
    irq_status |= u32(value)
    if (irq_status & irq_mask) > 0 {
        cop0_lo[cause] |= 0x400
    }
}

cop0_check_irq :: proc() {
    if ((cop0_lo[sr] & cop0_lo[cause] & 0x700) > 0) && ((cop0_lo[sr] & 1) == 1) {
        cop0_exception(.intr)
    }
}
