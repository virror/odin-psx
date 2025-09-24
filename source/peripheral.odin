package main

import "core:fmt"

Input_mode :: enum {
    None,
    Controller,
    Mem_card,
}

Mem_cmd :: enum {
    Id,
    Read,
    Write,
}

@(private="file")
joy_stat: u16
@(private="file")
joy_mode: u16
@(private="file")
joy_ctrl: u16
@(private="file")
joy_baud: u16
@(private="file")
sio_stat: u16
@(private="file")
sio_mode: u16
@(private="file")
sio_ctrl: u16
@(private="file")
sio_baud: u16
@(private="file")
state: Input_mode
@(private="file")
mem_cmd: Mem_cmd
@(private="file")
mode: u8
@(private="file")
return_data: u8
@(private="file")
response_bytes: u8

phr_init :: proc() {
    switch CONTROLLER {
    case .digital:
        response_bytes = 4
    case .analog:
        response_bytes = 8
        input_2_lo = 0x80
        input_2_hi = 0x80
        input_3_lo = 0x80
        input_3_hi = 0x80
    case .mouse:
        response_bytes = 6
        input_2_lo = 0x00
        input_2_hi = 0x00
    case .wheel:
        response_bytes = 8
    }
}

phr_read16 :: proc(address: u32) -> u16 {
    switch address {
    case 0x1F801044:
        return joy_stat
    case 0x1F801048:
        return joy_mode
    case 0x1F80104A:
        return joy_ctrl
    case 0x1F80104E:
        return joy_baud
    case 0x1F801054:
        return sio_stat
    case 0x1F801058:
        return sio_mode
    case 0x1F80105A:
        return sio_ctrl
    case 0x1F80105E:
        return sio_baud
    }
    return 0
}

phr_write16 :: proc(address: u32, value: u16) {
    switch address {
    case 0x1F801044:
        //Ignore, read-only
    case 0x1F801048:
        joy_mode = value
    case 0x1F80104A:
        phr_write_joy_ctrl(value)
    case 0x1F80104E:
        joy_baud = value
    case 0x1F801054:
        sio_stat = (value & 0xFBFF)
    case 0x1F801058:
        sio_mode = (value & 0xFF)
    case 0x1F80105A:
        sio_ctrl = (value & 0xFFF)
    case 0x1F80105E:
        sio_baud = value
    }
}

phr_read8 :: proc(address: u32) -> u8 {
    switch address {
    case 0x1F801040:
        return return_data
    case 0x1F801044:
        return u8(joy_stat)
    case 0x1F801048:
        return u8(joy_mode)
    case 0x1F80104A:
        return u8(joy_ctrl)
    case 0x1F80104E:
        return u8(joy_baud)
    case 0x1F801054:
        return u8(sio_stat)
    case 0x1F801058:
        return u8(sio_mode)
    case 0x1F80105A:
        return u8(sio_ctrl)
    case 0x1F80105E:
        return u8(sio_baud)
    case:
        return 0
    }
}

phr_write8 :: proc(address: u32, value: u8) {
    switch address {
    case 0x1F801040:
        switch state {
        case .None:
            if value == 0x01 {
                state = .Controller
                phr_write_joy_data(value)
            } else {
                state = .Mem_card
                phr_write_card_data(value)
            }
        case .Controller:
            phr_write_joy_data(value)
        case .Mem_card:
            phr_write_card_data(value)
        }
    case 0x1F801044:
        //Ignore, read-only
    case 0x1F801048:
        joy_mode = u16(value)
    case 0x1F80104A:
        phr_write_joy_ctrl(u16(value))
    case 0x1F80104E:
        joy_baud = u16(value)
    case 0x1F801054:
        sio_stat = u16(value)
    case 0x1F801058:
        sio_mode = u16(value)
    case 0x1F80105A:
        sio_ctrl = u16(value)
    case 0x1F80105E:
        sio_baud = u16(value)
    }
}

@(private="file")
phr_write_joy_ctrl :: proc(value: u16) {
    joy_ctrl = value
    if (value & 0x10) > 0 {
        joy_stat &= 0xFDF7  //Reset bit 3 and 9
    }
    if (value & 0x40) > 0 {
        joy_stat |= 0x7
        joy_ctrl = 0
    }
}

@(private="file")
phr_write_joy_data :: proc(value: u8) {
    switch mode {
    case 0:
        return_data = 0xFF
    case 1:
        switch CONTROLLER {
        case .digital:
            return_data = 0x41
        case .analog:
            return_data = 0x73
        case .mouse:
            return_data = 0x12
        case .wheel:
            return_data = 0x23
        }
    case 2:
        return_data = 0x5A
    case 3:
        return_data = input_1_lo
    case 4:
        return_data = input_1_hi
    case 5:
        return_data = input_2_lo
    case 6:
        return_data = input_2_hi
    case 7:
        return_data = input_3_lo
    case 8:
        return_data = input_3_hi
    }
    mode += 1
    if mode < response_bytes {
        cop0_set_irq(IRQ.IO)
    } else if mode == (response_bytes + 1) {
        mode = 0
        state = .None
    }
}

phr_write_card_data :: proc(value: u8) {
    switch mode {
    case 0:
        return_data = 0xFF
    case 1:
        switch value {
        case 0x52:
            mem_cmd = .Read
        case 0x53:
            mem_cmd = .Id
        case 0x57:
            mem_cmd = .Write
        }
    }
    mode += 1
}