package main

import "core:fmt"
import "core:os"

@(private="file")
Header :: struct {
    pc: u32,
    gp: u32,
    start: u32,
    size: u32,
    unused1: u32,
    unused2: u32,
    unused3: u32,
    unused4: u32,
    sp_fp: u32,
    offset: u32,
}

exe_sideload :: proc() {
    if pc == 0x80030000 {
        header: [0x28]u8
        file, err := os.open(SIDELOAD_PATH, os.O_RDONLY)
        assert(err == nil, "Failed to open sideloaded file")
        os.seek(file, 16, 0)
        _, err2 := os.read(file, header[:])
        assert(err2 == nil, "Failed to read sideloaded header")
        ha := cast(^Header)raw_data(header[:])
        pc = ha.pc
        next_pc = pc + 4
        cpu_reg_set(gp, ha.gp)
        if(ha.sp_fp != 0) {
            cpu_reg_set(sp, ha.sp_fp + ha.offset)
            cpu_reg_set(fp, ha.sp_fp + ha.offset)
        }
        ha.start &= 0x7fffffff
        os.seek(file, 0x800, 0)
        _, err3 := os.read(file, main_mem[ha.start:ha.start + ha.size])
        assert(err3 == nil, "Failed to read sideloaded data")
        os.close(file)
        update_window_title(SIDELOAD_PATH)
    }
}