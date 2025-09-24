package main

import "core:fmt"

Tmr_ctrl :: bit_field u16 {
    sync_mode: u8       | 3,
    reset_target: bool  | 1,
    irq_target: bool    | 1,
    irq_FFFF: bool      | 1,
    irq_mode: u8        | 2,
    clock_source: u8    | 2,
    irq: bool           | 1,
    target_reached: bool| 1,
    FFFF_reached: bool  | 1,
    unknown: u8         | 3,
}

@(private="file")
tmr_value: [3]u16
@(private="file")
tmr_conf: [3]Tmr_ctrl
@(private="file")
tmr_target: [3]u16
@(private="file")
tmr2_div: u64

@(private="file")
tmr_conf_read :: proc(ctrl: u8) -> u16 {
    tmr_ctrl:= tmr_conf[ctrl]
    tmr_conf[ctrl].target_reached = false
    tmr_conf[ctrl].FFFF_reached = false
    return u16(tmr_ctrl)
}

@(private="file")
tmr_conf_write :: proc(tmr_ctrl: u8, value: u16) {
    conf:= tmr_conf[tmr_ctrl]

    conf = Tmr_ctrl(value)
    if ((value >> 10) & 1) == 1 {
        conf.irq = true
    }

    tmr_conf[tmr_ctrl] = conf
}

tmr_init :: proc() {
    tmr_conf[0].irq = true
    tmr_conf[1].irq = true
    tmr_conf[2].irq = true
}

tmr_read32 :: proc(address: u32) -> u32 {
    return u32(tmr_read16(address))
}

tmr_write32 :: proc(address: u32, value: u32) {
    tmr_write16(address, u16(value))
}

tmr_read16 :: proc(address: u32) -> u16 {
    switch address {
    case 0x1F801100:
        return tmr_value[0]
    case 0x1F801104:
        return tmr_conf_read(0)
    case 0x1F801108:
        return tmr_target[0]
    case 0x1F801110:
        return tmr_value[1]
    case 0x1F801114:
        return tmr_conf_read(1)
    case 0x1F801118:
        return tmr_target[1]
    case 0x1F801120:
        return tmr_value[2]
    case 0x1F801124:
        return tmr_conf_read(2)
    case 0x1F801128:
        return tmr_target[2]
    }
    return 0
}

tmr_write16 :: proc(address: u32, value: u16) {
    switch address {
    case 0x1F801100:
        tmr_value[0] = value
    case 0x1F801104:
        tmr_conf_write(0, value)
        tmr_value[0] = 0
    case 0x1F801108:
        tmr_target[0] = value
    case 0x1F801110:
        tmr_value[1] = value
    case 0x1F801114:
        tmr_conf_write(1, value)
        tmr_value[1] = 0
    case 0x1F801118:
        tmr_target[1] = value
    case 0x1F801120:
        tmr_value[2] = value
    case 0x1F801124:
        tmr_conf_write(2, value)
        //tmr_value[2] = 0
    case 0x1F801128:
        tmr_target[2] = value
    }
}

tmr_update_all :: proc(tick: u64) {
    if tmr_conf[0].clock_source == 0 || tmr_conf[0].clock_source == 2 {
        tmr_update_tick(tick, 0)
    }
    if tmr_conf[1].clock_source == 0 || tmr_conf[1].clock_source == 2 {
        tmr_update_tick(tick, 1)
    }
    if tmr_conf[2].clock_source == 0 || tmr_conf[2].clock_source == 1 {
        tmr_update_tick(tick, 2)
    } else {
        tmr2_div += (tick % 8)
        tmp_tick := u64(tick / 8)
        if tmr2_div >= 8 {
            tmr2_div -= 8
            tmp_tick += 1
        }
        tmr_update_tick(tmp_tick, 2)
    }
}

@(private="file")
tmr_update_tick :: proc(tick: u64, timer: u8) {
    tmr_update(tick, timer)
}

tmr_update_hblank:: proc() {
    source := tmr_conf[1].clock_source
    if source == 1 || source == 3 {
        tmr_update(1, 1)
    }
}

@(private="file")
tmr_update :: proc(tick: u64, timer: u8) {
    tmr_value[timer] += u16(tick)
    target :u16= 0xFFFF
    if tmr_conf[timer].reset_target {
        target = tmr_target[timer]
    }
    if tmr_value[timer] == target {
        tmr_conf[timer].target_reached = true
        tmr_value[timer] = 0
        switch tmr_conf[timer].irq_mode {
        case 0: // One-shot, no toggle

        case 1: // Repeat, no toggle

        case 2: // One-shot, toggle
            tmr_conf[timer].irq = false
        case 3: // Repeat, toggle
            tmr_conf[timer].irq = !tmr_conf[timer].irq
        }
        //cop0_set_irq(IRQ.TMR0)
    }
}