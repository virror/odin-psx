package main

import "core:fmt"

Error :: enum {
    seek    = 0x04,
    shell   = 0x08,
    sub_cmd = 0x10,
    param   = 0x20,
    command = 0x40,
    respond = 0x80,
}

Status :: enum {
    error = 1 << 0,
    motor = 1 << 1,
    seekError = 1 << 2,
    idError = 1 << 3,
    shell = 1 << 4,
    read = 1 << 5,
    seek = 1 << 6,
    play = 1 << 7,
}

Mode :: enum {
    cdda = 1 << 0,
    autoPause = 1 << 1,
    report = 1 << 2,
    xa_filter = 1 << 3,
    ignore = 1 << 4,
    sectorSize = 1 << 5,
    xa_adpcm = 1 << 6,
    speed = 1 << 7,
}

Seek :: struct {
    mm: u8,
    ss: u8,
    sect: u8,
}

@(private="file")
IRQ_DELAY :: 33796

@(private="file")
status: u8
@(private="file")
mode: u8
@(private="file")
cd_index: u8

@(private="file")
irq_flags: u8
@(private="file")
irq_enable: u8
@(private="file")
irq_queued: u8
@(private="file")
param_fifo: [16]u8
@(private="file")
param_ptr: u8
@(private="file")
return_fifo: [16]u8
@(private="file")
return_ptr: u8
@(private="file")
queued_fifo: [16]u8
@(private="file")
queued_ptr: u8
@(private="file")
delayed_fifo: [16]u8
@(private="file")
delayed_ptr: u8
@(private="file")
smen: bool
@(private="file")
bfwr: bool
@(private="file")
bfrd: bool
@(private="file")
volumeL2L: u8
@(private="file")
volumeL2R: u8
@(private="file")
volumeR2L: u8
@(private="file")
volumeR2R: u8
@(private="file")
seek: Seek
@(private="file")
data_fifo: [16]u8
@(private="file")
data_ptr: u16
@(private="file")
shell_open: bool

//TODO: Properly handle the FIFOs

cd_init :: proc() {
    if shell_open {
        status |= u8(Status.shell)
    } else {
        status = 0
    }
}

cd_write8 :: proc(address: u32, value: u8) {
    //fmt.printf("cd write: 0x%x 0x%x\n", address, value)
    switch address {
    case 0x1F801800:    //Index/Status reg
        cd_index = value & 3
        //Rest of bytes are read only
    case 0x1f801801:
        switch cd_index {
        case 0:     //Command Register
            cd_handle_cmd(value)
        case 1:     //Sound Map Data Out
            panic("0x1f801801 1 not implemented")
        case 2:     //Sound Map Coding Info
            panic("0x1f801801 2 not implemented")
        case 3:     // Audio Volume for Right-CD-Out to Right-SPU-Input
            volumeR2R = value
        }
    case 0x1f801802:
        switch cd_index {
        case 0:     //Parameter Fifo
            cd_param_add(value)
        case 1:     //Interrupt Enable Register
            irq_enable = value
        case 2:     //Audio Volume for Left-CD-Out to Left-SPU-Input
            volumeL2L = value
        case 3:     //Audio Volume for Right-CD-Out to Left-SPU-Input
            volumeR2L = value
        }
    case 0x1f801803:
        switch cd_index {
        case 0:     //Request reg
            smen |= bool((value >> 5) & 1)
            bfwr |= bool((value >> 6) & 1)
            bfrd |= bool((value >> 7) & 1)
        case 1:     //Interrupt Flag Register
            //TODO: Reset parameter fifo on 0x40
            tmp := u8(~value & 0x1F)
            irq_flags &= tmp

            if irq_flags == 0 && irq_queued != 0 {
                evt_add(IRQ_DELAY, int2)
                irq_queued = 0
            }
        case 2:     //Audio Volume for Left-CD-Out to Right-SPU-Input
            volumeL2R = value
        case 3:     //Audio Volume Apply Changes
            cd_volume_apply()
        }
    }
}

cd_read8 :: proc(address: u32) -> u8 {
    //fmt.printf("cd read: 0x%x\n", address)
    switch address {
    case 0x1F801800:    //Index/Status reg
        rv := cd_index
        rv |= u8(param_ptr == 0) << 3
        rv |= (u8(param_ptr != 16) << 4)
        rv |= (u8(return_ptr != 0) << 5)
        rv |= (u8(data_ptr != 0) << 6)
        return rv
    case 0x1F801801:    //Response Fifo
        return cd_return_get()
    case 0x1F801802:    //Data Fifo
        data_ptr -= 1
        return data_fifo[data_ptr]
    case 0x1F801803:
        switch cd_index {
        case 0, 2:
            return irq_enable
        case 1, 3:
            return 0xE0 | irq_flags //Always return 1 for upper 3 bits
        case:
            return 0
        }
    case:
        fmt.printf("Unhandled read: 0x%x\n", address)
        panic("")
    }
}

@(private="file")
cd_handle_cmd :: proc(command: u8) {
    switch command {
    case 0x01:  //Get stat
        cd_01()
    case 0x02:  //SetLoc
        cd_02()
    case 0x06:  //ReadN
        cd_06()
    case 0x09:  //Pause
        cd_09()
    case 0x0A:  //Init
        cd_0A()
    case 0x0B:  //Mute
        cd_0B()
    case 0x0C:  //Demute
        cd_0C()
    case 0x0E:  //Set stat
        cd_0E()
    case 0x19:  //Test
        cd_19()
    case 0x1A:  //GetId
        cd_1A()
    case 0x00, 0x17, 0x18, 0x1F..=0x4F, 0x6F..=0xFF:
        cd_error(.command)
    case:
        fmt.printf("Unhandled cd command: 0x%x\n", command)
        panic("")
    }
}

@(private="file")
cd_01 :: proc() {
    fmt.println("Get status")
    if param_ptr > 0 {
        cd_error(.param)
        return
    }
    cd_return_add(status)
    if !shell_open {
        status &= ~u8(Status.shell)
    }
    evt_add(IRQ_DELAY, int3)
}

@(private="file")
cd_02 :: proc() {
    fmt.println("SetLoc")
    if param_ptr != 3 {
        cd_error(.param)
        return
    }
    seek.sect = cd_param_get()
    seek.ss = cd_param_get()
    seek.mm = cd_param_get()

    if !cd_is_hex_numbers(seek.mm) {
        cd_error(.sub_cmd)
        return
    }
    if seek.ss > 0x59 || !cd_is_hex_numbers(seek.ss) {
        cd_error(.sub_cmd)
        return
    }
    if seek.sect > 0x74 || !cd_is_hex_numbers(seek.sect) {
        cd_error(.sub_cmd)
        return
    }
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
}

@(private="file")
cd_06 :: proc() {
    fmt.println("ReadN")
    if param_ptr > 0 {
        cd_error(.param)
        return
    }
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
    status |= 0x20
    cd_delayed_add(status)
    data_ptr = 4
    evt_add(IRQ_DELAY + 451584, int1)
}

@(private="file")
cd_09 :: proc() {
    fmt.println("Pause")
    if param_ptr > 0 {
        cd_error(.param)
        return
    }
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
    status &= 0xDF
    cd_delayed_add(status)
    evt_add(IRQ_DELAY * 120, int2)
}

@(private="file")
cd_0A :: proc() {
    fmt.println("Init")
    if param_ptr > 0 {
        cd_error(.param)
        return
    }
    mode = 0
    status |= 0x02
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
    cd_delayed_add(status)
    evt_add(IRQ_DELAY * 120, int2)
}

@(private="file")
cd_0B :: proc() {
    fmt.println("Mute")
    //TODO: Implement Mute
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
}

@(private="file")
cd_0C :: proc() {
    fmt.println("Demute")
    //TODO: Implement Demute
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
}

@(private="file")
cd_0E :: proc() {
    fmt.println("Set mode")
    if param_ptr != 1 {
        cd_error(.param)
        return
    }
    param := cd_param_get()
    mode = param
    cd_return_add(status)
    evt_add(IRQ_DELAY, int3)
}

@(private="file")
cd_19 :: proc() {
    if param_ptr != 1 {
        cd_error(.param)
        return
    }
    param := cd_param_get()
    switch param {
    case 0x20:
        fmt.println("Get cdrom BIOS date/version")
        cd_return_add(0x95) //Set date
        cd_return_add(0x05)
        cd_return_add(0x16)
        cd_return_add(0xC1)
        evt_add(IRQ_DELAY, int3)
    case 0x06..=0x0F, 0x1B..=0x1F, 0x26..=0x2F,
        0x30..=0x4F, 0x51..=0x5F, 0x61..=0x71, 0x77..=0xFF:
        cd_error(.sub_cmd)
    case:
        fmt.printf("Unhandled cd test command: 0x%x", param)
        panic("")
    }
}

@(private="file")
cd_1A :: proc() {
    fmt.println("Get Id")
    if param_ptr > 0 {
        cd_error(.param)
        return
    }
    if shell_open {             //Shell open
        cd_return_add(0x11)
        cd_return_add(0x80)
        evt_add(IRQ_DELAY, int5)
    } else if DISK_PATH == "" { //No disk
        cd_return_add(status)
        evt_add(IRQ_DELAY, int3)
        cd_delayed_add(0x00)
        cd_delayed_add(0x00)
        cd_delayed_add(0x00)
        cd_delayed_add(0x00)
        cd_delayed_add(0x00)
        cd_delayed_add(0x00)
        cd_delayed_add(0x40)
        cd_delayed_add(0x08)
        evt_add(IRQ_DELAY + 30000, int5)
    } else {                    //Licensed disk
        cd_return_add(status)
        evt_add(IRQ_DELAY, int3)
        cd_delayed_add(0x45)
        cd_delayed_add(0x45)
        cd_delayed_add(0x43)
        cd_delayed_add(0x53)
        cd_delayed_add(0x00)
        cd_delayed_add(0x20)
        cd_delayed_add(0x00)
        cd_delayed_add(0x02)
        evt_add(IRQ_DELAY + 30000, int2)
    }
}

@(private="file")
int1 :: proc() {
    cd_set_irq(1)
}

@(private="file")
int2 :: proc() {
    cd_set_irq(2)
}

@(private="file")
int3 :: proc() {
    cd_set_irq(3)
}

@(private="file")
int5 :: proc() {
    cd_set_irq(5)
}

@(private="file")
cd_volume_apply :: proc() {
    //TODO: Implement apply
}

@(private="file")
cd_is_hex_numbers :: proc(value: u8) -> bool {
    return ((value & 0xF) <= 0x9) && ((value & 0xF0) <= 0x90)
}

cd_shell_toggle :: proc() {
    shell_open = !shell_open
    if shell_open {
        status &= 0x11
        cd_error(.shell)
    }
}

@(private="file")
cd_error :: proc(param: Error) {
    cd_return_add(status | u8(Status.error))
    cd_return_add(u8(param))
    evt_add(IRQ_DELAY, int5)
    param_ptr = 0
}

@(private="file")
cd_param_add :: proc(value: u8) {
    if param_ptr >= 16 { //TODO: Validate this
        return
    }
    param_fifo[param_ptr] = value
    param_ptr += 1
}

@(private="file")
cd_param_get :: proc() -> u8 {
    param_ptr -= 1
    return param_fifo[param_ptr]
}

@(private="file")
cd_return_add :: proc(value: u8) {
    queued_fifo[queued_ptr] = value
    queued_ptr += 1
}

@(private="file")
cd_delayed_add :: proc(value: u8) {
    delayed_fifo[delayed_ptr] = value
    delayed_ptr += 1
}

@(private="file")
cd_return_get :: proc() -> u8 {
    return_ptr -= 1
    return return_fifo[return_ptr]
}

@(private="file")
cd_set_irq :: proc(value: u8) {
    if irq_flags > 0 {
        irq_queued = value
        return
    }

    for queued_ptr > 0 {
        queued_ptr -= 1
        return_fifo[return_ptr] = (queued_fifo[queued_ptr])
        return_ptr += 1
    }

    for delayed_ptr > 0 {
        delayed_ptr -= 1
        queued_fifo[queued_ptr] = (delayed_fifo[delayed_ptr])
        queued_ptr += 1
    }

    irq_flags = value
    if irq_flags & irq_enable > 0 {
        cop0_set_irq(IRQ.CDROM)
    }

    /*if value == 1 {
        evt_add(IRQ_DELAY + 451584, int1)
    }*/
}
