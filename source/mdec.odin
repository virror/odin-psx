package main

import "core:fmt"

@(private="file")
Mdec_mode :: enum {
    none,
    command,
    quant,
    scale,
}

zagzig :[]u32= {
    0,  1,  8, 16,  9,  2,  3, 10,
   17, 24, 32, 25, 18, 11,  4,  5,
   12, 19, 26, 33, 40, 48, 41, 34,
   27, 20, 13,  6,  7, 14, 21, 28,
   35, 42, 49, 56, 57, 50, 43, 36,
   29, 22, 15, 23, 30, 37, 44, 51,
   58, 59, 52, 45, 38, 31, 39, 46,
   53, 60, 61, 54, 47, 55, 62, 63,
}

@(private="file")
mdecsr: u32
@(private="file")
cmd_size: u32
@(private="file")
mdec_mode: Mdec_mode
@(private="file")
quant_mode: u32
@(private="file")
quant_tbl: [128]u8
@(private="file")
scale_tbl: [64]u16
in_buf: [14240]u16
in_ptr: u16
cr_buf: [256]u16
cb_buf: [256]u16
y1_buf: [256]u16
y2_buf: [256]u16
y3_buf: [256]u16
y4_buf: [256]u16
out_buf: [64]u16

mdec_read32 :: proc(address: u32) -> u32 {
    switch(address)
    {
    case 0x1F801820:
        return 0xFFFF
    case 0x1F801824:
        return mdecsr
    }
    return 0
}

mdec_write32 :: proc(address: u32, value: u32) {
    switch(address)
    {
    case 0x1F801820:
        mdec_command(value)
    case 0x1F801824:
        if value & 0x80000000 > 0 {
            mdecsr = 0x80040000
            mdec_mode = .none
        }
        if value & 0x40000000 > 0 {

        }
        if value & 0x20000000 > 0 {
        }
    }
}

@(private="file")
mdec_command :: proc(value: u32) {
    switch mdec_mode {
    case .none:
        cmd := value >> 29
        switch(cmd) {
        case 1:
            mdecsr |= ((value & 0xFFFF) - 1)
            mdec_mode = .command
            cmd_size = value & 0xFFFF
            fmt.println(cmd_size)
        case 2:
            quant_mode = value & 1
            if quant_mode > 0 {
                cmd_size = 128
            } else {
                cmd_size = 64
            }
            mdec_mode = .quant
        case 3:
            cmd_size = 64
            mdec_mode = .scale
        case:
            mdecsr |= (value & 0xFFFF)
        }
        mdecsr |= ((value & 0x2000000) >> 2)
        mdecsr |= ((value & 0x4000000) >> 2)
        mdecsr |= ((value & 0x8000000) >> 2)
        mdecsr |= ((value & 0x10000000) >> 2)
    case .command:
        (cast(^u32)&in_buf[in_ptr])^ = value
        in_ptr += 2
        cmd_size -= 1
        mdecsr &= 0xFFFF0000
        mdecsr |= u32((u16(cmd_size) - 1))
        if cmd_size == 0 {
            decode_macroblock()
            in_ptr = 0
            mdec_mode = .none
            mdecsr &= 0x7FFFFFFF
        }
    case .quant:
        index := (quant_mode + 1) * 64 - cmd_size
        (cast(^u32)&quant_tbl[index])^ = value
        cmd_size -= 4
        mdecsr &= 0xFFFF0000
        mdecsr |= u32((u16(cmd_size / 4) - 1))
        if cmd_size == 0 {
            mdec_mode = .none
        }
    case .scale:
        index := 64 - cmd_size
        (cast(^u32)&scale_tbl[index])^ = value
        cmd_size -= 2
        mdecsr &= 0xFFFF0000
        mdecsr |= u32((u16(cmd_size / 2) - 1))
        if cmd_size == 0 {
            mdec_mode = .none
        }
    }
}

@(private="file")
decode_macroblock :: proc() {
    if ((mdecsr >> 25) & 0x3) < 2 {
        fmt.println("decode bw block")
        //for in_ptr > 0 {
            decode_block()
        //    in_ptr -= 4
        //}
    } else {
        fmt.println("decode color block")
    }
}

@(private="file")
decode_block :: proc() {
    /*idx := 0

    fmt.println("decode sub-block")
    for i:u16 = 0; i < 63; i+=1 {
        out_buf[i] = 0
    }
    n := out_buf[idx]
    k := 0
    idx += 2
    if n == 0xFE00 {
        n := out_buf[idx]
        idx += 2
    }
    q_scale := (n >> 10) & 0x3F
    val := signed10bit(n & 0x3FF) * quant_tbl[k]
    for k < 64 {
        if q_scale == 0 {
            val = signed10bit(n & 0x3FF) * 2
        }
        val = clamp(val, -0x400, 0x3FF)
        if q_scale > 0 {
            out_buf
        }
    }*/
}