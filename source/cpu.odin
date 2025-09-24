package main

import "core:fmt"
import "base:intrinsics"

RegType :: distinct u32

@(private="file")
reg: [32]u32
@(private="file")
out_reg: [32]u32

Load :: struct {
    reg: RegType,
    value: u32,
}
load: Load

zero :RegType: 0
at :RegType: 1
v0 :RegType: 2
v1 :RegType: 3
a0 :RegType: 4
a1 :RegType: 5
a2 :RegType: 6
a3 :RegType: 7
t0 :RegType: 8
t1 :RegType: 9
t2 :RegType: 10
t3 :RegType: 11
t4 :RegType: 12
t5 :RegType: 13
t6 :RegType: 14
t7 :RegType: 15
s0 :RegType: 16
s1 :RegType: 17
s2 :RegType: 18
s3 :RegType: 19
s4 :RegType: 20
s5 :RegType: 21
s6 :RegType: 22
s7 :RegType: 23
t8 :RegType: 24
t9 :RegType: 25
k0 :RegType: 26
k1 :RegType: 27
gp :RegType: 28
sp :RegType: 29
fp :RegType: 30
ra :RegType: 31

pc: u32
hi: u32
lo: u32

last_pc: u32
next_pc: u32
curr_op: u32
//next_op: u32
@(private="file")
jump: bool
delay: bool

cpu_init :: proc() {
    pc = 0xBFC00000
    next_pc = pc + 4
    //next_op = 0
    load = {zero, 0}
    jump = false
    delay = false
}

cpu_step :: proc() -> u64 {
    if (pc % 4) != 0 {
        cop0_exception(.adel)
    }

    cycles: u64
    switch pc {
    case 0x1FC00000..<0x1FC80000:   //Bios
        cycles = 20
    case:
        cycles = 2
    }

    when ENABLE_TTY {
        print_tty()
    }

    when ENABLE_SIDELOAD {
        exe_sideload()
    }

    last_pc = pc
    delay = jump
    jump = false
    curr_op = bus_read32(pc)
    pc = next_pc
    next_pc += 4

    cop0_check_irq()

    //If we have a pending load instruction, copy its data
    //(otherwise it sets zero which does nothing)
    cpu_reg_set(load.reg, load.value)
    load = {zero, 0}

    cpu_decode(curr_op)

    //Copy out_reg back to reg
    reg = out_reg
    return cycles
}

@(private="file")
cpu_decode :: proc(opcode: u32) {
    code := (opcode >> 26)
    switch code {
    case 0x00:
        cpu_alu(opcode)
    case 0x01:
        cpu_jump(opcode)
    case 0x02:
        cpu_j(opcode)
    case 0x03:
        cpu_jal(opcode)
    case 0x04:
        cpu_beq(opcode)
    case 0x05:
        cpu_bne(opcode)
    case 0x06:
        cpu_blez(opcode)
    case 0x07:
        cpu_bgtz(opcode)
    case 0x08:
        cpu_addi(opcode)
    case 0x09:
        cpu_addiu(opcode)
    case 0x0A:
        cpu_slti(opcode)
    case 0x0B:
        cpu_sltiu(opcode)
    case 0x0C:
        cpu_andi(opcode)
    case 0x0D:
        cpu_ori(opcode)
    case 0x0E:
        cpu_xori(opcode)
    case 0x0F:
        cpu_lui(opcode)
    case 0x10..=0x13:
        cpu_cop(opcode)
    case 0x20:
        cpu_lb(opcode)
    case 0x21:
        cpu_lh(opcode)
    case 0x22:
        cpu_lwl(opcode)
    case 0x23:
        cpu_lw(opcode)
    case 0x24:
        cpu_lbu(opcode)
    case 0x25:
        cpu_lhu(opcode)
    case 0x26:
        cpu_lwr(opcode)
    case 0x28:
        cpu_sb(opcode)
    case 0x29:
        cpu_sh(opcode)
    case 0x2A:
        cpu_swl(opcode)
    case 0x2B:
        cpu_sw(opcode)
    case 0x2E:
        cpu_swr(opcode)
    case 0x30..=0x33:
        cpu_co_lwc(opcode)
    case 0x38..=0x3B:
        cpu_co_swc(opcode)
    case:
        cpu_illegal(opcode)
    }
}

@(private="file")
cpu_alu :: proc(opcode: u32) {
    sub_code := opcode & 0x3F
    switch sub_code {
    case 0x00:
        cpu_sll(opcode)
    case 0x02:
        cpu_srl(opcode)
    case 0x03:
        cpu_sra(opcode)
    case 0x04:
        cpu_sllv(opcode)
    case 0x06:
        cpu_srlv(opcode)
    case 0x07:
        cpu_srav(opcode)
    case 0x08:
        cpu_jr(opcode)
    case 0x09:
        cpu_jalr(opcode)
    case 0x0C:
        cpu_syscall(opcode)
    case 0x0D:
        cpu_break(opcode)
    case 0x10:
        cpu_mfhi(opcode)
    case 0x11:
        cpu_mthi(opcode)
    case 0x12:
        cpu_mflo(opcode)
    case 0x13:
        cpu_mtlo(opcode)
    case 0x18:
        cpu_mult(opcode)
    case 0x19:
        cpu_multu(opcode)
    case 0x1A:
        cpu_div(opcode)
    case 0x1B:
        cpu_divu(opcode)
    case 0x20:
        cpu_add(opcode)
    case 0x21:
        cpu_addu(opcode)
    case 0x22:
        cpu_sub(opcode)
    case 0x23:
        cpu_subu(opcode)
    case 0x24:
        cpu_and(opcode)
    case 0x25:
        cpu_or(opcode)
    case 0x26:
        cpu_xor(opcode)
    case 0x27:
        cpu_nor(opcode)
    case 0x2A:
        cpu_slt(opcode)
    case 0x2B:
        cpu_sltu(opcode)
    case:
        cpu_illegal(opcode)
    }
}

@(private="file")
cpu_jump :: proc(opcode: u32) {
    sub_code := cpu_rt(opcode)
    switch sub_code {
    case 0x00:
        cpu_bltz(opcode)
    case 0x01:
        cpu_bgez(opcode)
    case 0x10:
        cpu_bltzal(opcode)
    case 0x11:
        cpu_bgezal(opcode)
    case:
        sub_code2 := sub_code & 1
        switch sub_code2 {
        case 0x00:
            cpu_bltz(opcode)
        case 0x01:
            cpu_bgez(opcode)
        }
    }
}

@(private="file")
cpu_cop :: proc(opcode: u32) {
    code := cpu_rs(opcode)
    switch code {
    case 0x00:
        cpu_co_mfc(opcode)
    case 0x02:
        cpu_co_cfc(opcode)
    case 0x04:
        cpu_co_mtc(opcode)
    case 0x06:
        cpu_co_ctc(opcode)
    case 0x08:
        cop0_exception(.cpu)
    case:
        sub_code := opcode >> 25
        switch sub_code {
        case 0x21:
            cpu_co_rfe(opcode)
        case 0x25:
            cpu_copn(opcode)
        case:
            cpu_illegal(opcode)
        }
    }
}

//Regs

cpu_reg_set :: proc(n: RegType, value: u32) {
    out_reg[n] = value
    out_reg[0] = 0 //reg 0 must always be zero
}

cpu_reg_get :: proc(n: RegType) -> u32 {
    return reg[n]
}

//Helpers

cpu_imm5 :: proc(opcode: u32) -> u32 {
    return (opcode >> 6) & 0x1F
}

cpu_imm16 :: proc(opcode: u32) -> u32 {
    return opcode & 0xFFFF
}

cpu_imm16_se :: proc(opcode: u32) -> i16 {
    a :i16= i16(opcode & 0xFFFF)
    return i16(a)
}

cpu_imm25 :: proc(opcode: u32) -> u32 {
    return opcode & 0x1FFFFFF
}

cpu_imm26 :: proc(opcode: u32) -> u32 {
    return opcode & 0x3FFFFFF
}

cpu_rs :: proc(opcode: u32) -> RegType {
    return RegType((opcode >> 21) & 0x1F)
}

cpu_rt :: proc(opcode: u32) -> RegType {
    return RegType((opcode >> 16) & 0x1F)
}

cpu_rd :: proc(opcode: u32) -> RegType {
    return RegType((opcode >> 11) & 0x1F)
}

cpu_nn :: proc(opcode: u32) -> u32 {
    return (opcode >> 26) & 0x3
}

cpu_branch :: proc(opcode: u32) -> u32 {
    jump = true
    imm := cpu_imm16_se(opcode)
    return next_pc + u32(imm << 2) - 4
}

//Instructions
@(private="file")
cpu_lb :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := i8(bus_read8(cpu_reg_get(rs) + u32(imm)))
    load = {rt, u32(val)}
}

@(private="file")
cpu_lbu :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := bus_read8(cpu_reg_get(rs) + u32(imm))
    load = {rt, u32(val)}
}

@(private="file")
cpu_lh :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)
    if addr % 2 != 0 {
        cop0_exception(.adel)
        return
    }
    rt := cpu_rt(opcode)
    val := i16(bus_read16(addr))
    load = {rt, u32(val)}
}

@(private="file")
cpu_lhu :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)
    if addr % 2 != 0 {
        cop0_exception(.adel)
        return
    }
    rt := cpu_rt(opcode)
    val := u32(bus_read16(addr))
    load = {rt, val}
}

@(private="file")
cpu_lw :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)

    if addr % 4 != 0 {
        cop0_exception(.adel)
        return
    }

    rt := cpu_rt(opcode)
    val := bus_read32(addr)
    load = {rt, val}
}

@(private="file")
cpu_sb :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)
    bus_write8(addr, (cpu_reg_get(rt)))
}

@(private="file")
cpu_sh :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)
    if addr % 2 != 0 {
        cop0_exception(.ades)
        return
    }
    rt := cpu_rt(opcode)
    bus_write16(addr, (cpu_reg_get(rt)))
}

@(private="file")
cpu_sw :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)

    if addr % 4 != 0 {
        cop0_exception(.ades)
        return
    }

    rt := cpu_rt(opcode)
    bus_write32(addr, cpu_reg_get(rt))
}

@(private="file")
cpu_lwr :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)

    org_val := out_reg[rt]
    aligned_addr := addr & 0xFFFFFFFC
    val := bus_read32(aligned_addr)
    final_val: u32

    switch addr & 0x3 {
    case 0:
        final_val = (org_val & 0x00000000) | val
    case 1:
        final_val = (org_val & 0xFF000000) | (val >> 8)
    case 2:
        final_val = (org_val & 0xFFFF0000) | (val >> 16)
    case 3:
        final_val = (org_val & 0xFFFFFF00) | (val >> 24)
    }
    load = {rt, final_val}
}

@(private="file")
cpu_lwl :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)

    org_val := out_reg[rt]
    aligned_addr := addr & 0xFFFFFFFC
    val := bus_read32(aligned_addr)
    final_val: u32

    switch addr & 0x3 {
    case 0:
        final_val = (org_val & 0x00FFFFFF) | (val << 24)
    case 1:
        final_val = (org_val & 0x0000FFFF) | (val << 16)
    case 2:
        final_val = (org_val & 0x000000FF) | (val << 8)
    case 3:
        final_val = (org_val & 0x00000000) | val
    }
    load = {rt, final_val}
}

@(private="file")
cpu_swr :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)

    org_val := cpu_reg_get(rt)
    aligned_addr := addr & 0xFFFFFFFC
    val := bus_read32(aligned_addr)
    final_val: u32

    switch addr & 0x3 {
    case 0:
        final_val = (val & 0x00000000) | org_val
    case 1:
        final_val = (val & 0x000000FF) | (org_val << 8)
    case 2:
        final_val = (val & 0x0000FFFF) | (org_val << 16)
    case 3:
        final_val = (val & 0x00FFFFFF) | (org_val << 24)
    }
    bus_write32(aligned_addr, final_val)
}

@(private="file")
cpu_swl :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    addr := cpu_reg_get(rs) + u32(imm)

    org_val := cpu_reg_get(rt)
    aligned_addr := addr & 0xFFFFFFFC
    val := bus_read32(aligned_addr)
    final_val: u32

    switch addr & 0x3 {
    case 0:
        final_val = (val & 0xFFFFFF00) | (org_val >> 24)
    case 1:
        final_val = (val & 0xFFFF0000) | (org_val >> 16)
    case 2:
        final_val = (val & 0xFF000000) | (org_val >> 8)
    case 3:
        final_val = (val & 0x00000000) | org_val
    }
    bus_write32(aligned_addr, final_val)
}

@(private="file")
cpu_add :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    s := i32(cpu_reg_get(rs))
    t := i32(cpu_reg_get(rt))
    val, owf := intrinsics.overflow_add(s, t)
    if owf {
        cop0_exception(.ov)
    } else {
        rd := cpu_rd(opcode)
        cpu_reg_set(rd, u32(val))
    }
}

@(private="file")
cpu_addu :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) + cpu_reg_get(rt)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_sub :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    s := i32(cpu_reg_get(rs))
    t := i32(cpu_reg_get(rt))
    val, owf := intrinsics.overflow_sub(s, t)
    if owf {
        cop0_exception(.ov)
    } else {
        rd := cpu_rd(opcode)
        cpu_reg_set(rd, u32(val))
    }
}

@(private="file")
cpu_subu :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) - cpu_reg_get(rt)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_addi :: proc(opcode: u32) { //TODO: Verify overflow code
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    s := cpu_reg_get(rs)
    val := s + u32(imm)
    if ((~(s ~ u32(imm)) & (s ~ val)) & 0x80000000) > 0 {
        cop0_exception(.ov)
    } else {
        cpu_reg_set(rt, val)
    }
}

@(private="file")
cpu_addiu :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) + u32(imm)
    cpu_reg_set(rt, val)
}

@(private="file")
cpu_slt :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)

    val := i32(cpu_reg_get(rs)) < i32(cpu_reg_get(rt))
    cpu_reg_set(rd, u32(val))
}

@(private="file")
cpu_sltu :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) < cpu_reg_get(rt)
    cpu_reg_set(rd, u32(val))
}

@(private="file")
cpu_slti :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := i32(cpu_reg_get(rs)) < i32(imm)
    cpu_reg_set(rt, u32(val))
}

@(private="file")
cpu_sltiu :: proc(opcode: u32) {
    imm := cpu_imm16_se(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) < u32(imm)
    cpu_reg_set(rt, u32(val))
}

@(private="file")
cpu_and :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) & cpu_reg_get(rt)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_or :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) | cpu_reg_get(rt)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_xor :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) ~ cpu_reg_get(rt)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_nor :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := ~(cpu_reg_get(rs) | cpu_reg_get(rt))
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_andi :: proc(opcode: u32) {
    imm := cpu_imm16(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) & imm
    cpu_reg_set(rt, val)
}

@(private="file")
cpu_ori :: proc(opcode: u32) {
    imm := cpu_imm16(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) | imm
    cpu_reg_set(rt, val)
}

@(private="file")
cpu_xori :: proc(opcode: u32) {
    imm := cpu_imm16(opcode)
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rs) ~ imm
    cpu_reg_set(rt, val)
}

@(private="file")
cpu_sllv :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rt) << (cpu_reg_get(rs) & 0x1F)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_srlv :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    val := cpu_reg_get(rt) >> (cpu_reg_get(rs) & 0x1F)
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_srav :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    tmp := i32(cpu_reg_get(rt))
    val := tmp >> (cpu_reg_get(rs) & 0x1F)
    cpu_reg_set(rd, u32(val))
}

@(private="file")
cpu_sll :: proc(opcode: u32) {
    imm := cpu_imm5(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    val := cpu_reg_get(rt) << imm
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_srl :: proc(opcode: u32) {
    imm := cpu_imm5(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    val := cpu_reg_get(rt) >> imm
    cpu_reg_set(rd, val)
}

@(private="file")
cpu_sra :: proc(opcode: u32) {
    imm := cpu_imm5(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    tmp := i32(cpu_reg_get(rt))
    val := tmp >> imm
    cpu_reg_set(rd, u32(val))
}

@(private="file")
cpu_lui :: proc(opcode: u32) {
    imm := cpu_imm16(opcode)
    rt := cpu_rt(opcode)
    val := imm << 16
    cpu_reg_set(rt, val)
}

@(private="file")
cpu_mult :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)

    n := i64(i32(cpu_reg_get(rt)))
    d := i64(i32(cpu_reg_get(rs)))
    v := n * d
    hi = u32(v >> 32)
    lo = u32(v)
}

@(private="file")
cpu_multu :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)

    n := u64(cpu_reg_get(rt))
    d := u64(cpu_reg_get(rs))
    v := n * d
    hi = u32(v >> 32)
    lo = u32(v)
}

@(private="file")
cpu_div :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)

    n := i32(cpu_reg_get(rs))
    d := i32(cpu_reg_get(rt))

    if d == 0 {
        hi = u32(n)
        if n >= 0 {
            lo = 0xFFFFFFFF
        } else {
            lo = 1
        }
    } else if u32(n) == 0x80000000 && d == -1{
        hi = 0
        lo = 0x80000000
    } else {
        lo = u32(n / d)
        hi = u32(n % d)
    }
}

@(private="file")
cpu_divu :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)

    n := cpu_reg_get(rs)
    d := cpu_reg_get(rt)

    if d == 0 {
        hi = n
        lo = 0xFFFFFFFF
    } else {
        lo = n / d
        hi = n % d
    }
}

@(private="file")
cpu_mfhi :: proc(opcode: u32) {
    rd := cpu_rd(opcode)
    cpu_reg_set(rd, hi)
}

@(private="file")
cpu_mflo :: proc(opcode: u32) {
    rd := cpu_rd(opcode)
    cpu_reg_set(rd, lo)
}

@(private="file")
cpu_mthi :: proc(opcode: u32) {
    rs := cpu_rs(opcode)
    hi = cpu_reg_get(rs)
}

@(private="file")
cpu_mtlo :: proc(opcode: u32) {
    rs := cpu_rs(opcode)
    lo = cpu_reg_get(rs)
}

@(private="file")
cpu_syscall :: proc(opcode: u32) {
    cop0_exception(.syscall)
}

@(private="file")
cpu_break :: proc(opcode: u32) {
    cop0_exception(.bp)
}

@(private="file")
cpu_j :: proc(opcode: u32) {
    jump = true
    imm := cpu_imm26(opcode)
    next_pc = (next_pc & 0xF0000000) | (imm << 2)
}

@(private="file")
cpu_jal :: proc(opcode: u32) {
    cpu_reg_set(ra, next_pc)
    cpu_j(opcode)
}

@(private="file")
cpu_jr :: proc(opcode: u32) {
    jump = true
    rs := cpu_rs(opcode)
    next_pc = cpu_reg_get(rs)
}

@(private="file")
cpu_jalr :: proc(opcode: u32) {
    jump = true
    rd := cpu_rd(opcode)
    rs := cpu_rs(opcode)
    cpu_reg_set(rd, next_pc)
    next_pc = cpu_reg_get(rs)
}

@(private="file")
cpu_beq :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    if cpu_reg_get(rt) == cpu_reg_get(rs) {
        next_pc = cpu_branch(opcode)
    }
}

@(private="file")
cpu_bne :: proc(opcode: u32) {
    rt := cpu_rt(opcode)
    rs := cpu_rs(opcode)
    if cpu_reg_get(rt) != cpu_reg_get(rs) {
        next_pc = cpu_branch(opcode)
    }
}

@(private="file")
cpu_bltz :: proc(opcode: u32) {
    rs := cpu_rs(opcode)
    v:= i32(cpu_reg_get(rs))
    if v < 0 {
        next_pc = cpu_branch(opcode)
    }
}

@(private="file")
cpu_bgez :: proc(opcode: u32) {
    rs := cpu_rs(opcode)
    v:= i32(cpu_reg_get(rs))
    if v >= 0 {
        next_pc = cpu_branch(opcode)
    }
}

@(private="file")
cpu_bgtz :: proc(opcode: u32) {
    rs := cpu_rs(opcode)
    v:= i32(cpu_reg_get(rs))
    if v > 0 {
        next_pc = cpu_branch(opcode)
    }
}

@(private="file")
cpu_blez :: proc(opcode: u32) {
    rs := cpu_rs(opcode)
    v:= i32(cpu_reg_get(rs))
    if v <= 0 {
        next_pc = cpu_branch(opcode)
    }
}

@(private="file")
cpu_bltzal :: proc(opcode: u32) {
    cpu_reg_set(ra, next_pc)
    cpu_bltz(opcode)
}

@(private="file")
cpu_bgezal :: proc(opcode: u32) {
    cpu_reg_set(ra, next_pc)
    cpu_bgez(opcode)
}

@(private="file")
cpu_co_mfc :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    switch nn {
    case 0:
        load = {rt, cop0_get(u32(rd))}
    case 2:
        load = {rt, gte_get(u32(rd))}
    case:
        cop0_exception(.cpu)
    }
}

@(private="file")
cpu_co_cfc :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    switch nn {
    case 0:
        panic("No controls regs for cop0")
    case 2:
        load = {rt, gte_get(u32(rd) + 32)}
    case:
        cop0_exception(.cpu)
    }
}

@(private="file")
cpu_co_mtc :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    switch nn {
    case 0:
        cop0_set(u32(rd), cpu_reg_get(rt))
    case 2:
        gte_set(u32(rd), cpu_reg_get(rt))
    case:
        cop0_exception(.cpu)
    }
}

@(private="file")
cpu_co_ctc :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    rt := cpu_rt(opcode)
    rd := cpu_rd(opcode)
    switch nn {
    case 0:
        panic("No controls regs for cop0")
    case 2:
        gte_set(u32(rd) + 32, cpu_reg_get(rt))
    case:
        cop0_exception(.cpu)
    }
}

@(private="file")
cpu_co_lwc :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    switch nn {
    case 2:
        rt := cpu_rt(opcode)
        rs := cpu_rs(opcode)
        imm := cpu_imm16_se(opcode)
        gte_set(u32(rt), bus_read32(cpu_reg_get(rs) + u32(imm)))
    }
}

@(private="file")
cpu_co_swc :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    switch nn {
    case 2:
        imm := cpu_imm16_se(opcode)
        rt := cpu_rt(opcode)
        rs := cpu_rs(opcode)
        bus_write32(cpu_reg_get(rs) + u32(imm), gte_get(u32(rt)))
    }
}

@(private="file")
cpu_copn :: proc(opcode: u32) {
    nn := cpu_nn(opcode)
    switch nn {
    case 2:
        gte_command(cpu_imm25(opcode))
    case:
        cop0_exception(.cpu)
    }
}

@(private="file")
cpu_co_rfe :: proc(opcode: u32) {
    cop0_return()
}

@(private="file")
cpu_illegal :: proc(opcode: u32) {
    cop0_exception(.ri)
}
