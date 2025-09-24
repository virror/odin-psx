package main

import "core:fmt"

Direction :: enum {
    to_ram,
    from_ram,
}

Step :: enum {
    forward,
    backward,
}

SyncMode :: enum {
    all,
    sync,
    linked,
}

Channel :: struct {
    base_address: u32,
    block_size: u16,
    block_amount: u16,
    direction: Direction,
    address_step: Step,
    chopping: bool,
    sync_mode: SyncMode,
    chop_dma_window: u32,
    chop_cpu_window: u32,
    start: bool,
    trigger: bool,
    unknown: u32,
    unknown2: u32,
}
@(private="file")
channels: [7]Channel

Dicr :: struct {
    unknown: u8,
    force_irq: bool,
    irq_enable: u8,
    irq_master: bool,
    irq_flags: u8,
    irq_signal: bool,
}
@(private="file")
dpcr_reg: u32
@(private="file")
dicr_reg: Dicr

mdecin_madr  :: 0
mdecin_bcr   :: 1
mdecin_ctrl  :: 2
mdecout_madr :: 4
mdecout_bcr  :: 5
mdecout_ctrl :: 6
gpu_madr     :: 8
gpu_bcr      :: 9
gpu_ctrl     :: 10
cdrom_madr   :: 12
cdrom_bcr    :: 13
cdrom_ctrl   :: 14
spu_madr     :: 16
spu_bcr      :: 17
spu_ctrl     :: 18
pio_madr     :: 20
pio_bcr      :: 21
pio_ctrl     :: 22
otc_madr     :: 24
otc_bcr      :: 25
otc_ctrl     :: 26
dpcr         :: 28
dicr         :: 29

dma_init :: proc() {
    dpcr_reg = 0x07654321
}

dma_read32 :: proc(address: u32) -> u32 {
    offset := u8((address - 0x1F801080) / 4)
    switch offset {
    case dpcr:
        return dpcr_reg
    case dicr:
        rv := u32(dicr_reg.unknown)
        rv |= u32(u32(dicr_reg.force_irq) << 15)
        rv |= u32(dicr_reg.irq_enable << 16)
        rv |= u32(u32(dicr_reg.irq_master) << 23)
        rv |= u32(dicr_reg.irq_flags << 24)
        signal := u32(dicr_reg.force_irq || (dicr_reg.irq_master && dicr_reg.irq_flags > 0))
        rv |= signal << 31
        return rv
    case mdecin_ctrl, mdecout_ctrl, gpu_ctrl, cdrom_ctrl, spu_ctrl, pio_ctrl, otc_ctrl:
        return dma_ctrl_read((offset - 2) / 4)
    case mdecin_madr, mdecout_madr, gpu_madr, cdrom_madr, spu_madr, pio_madr, otc_madr:
        return channels[offset / 4].base_address
    case mdecin_bcr, mdecout_bcr, gpu_bcr, cdrom_bcr, spu_bcr, pio_bcr, otc_bcr:
        return dma_bcr_read((offset - 1) / 4)
    case:
        panic("")
    }
}

dma_write32 :: proc(address: u32, value: u32) {
    offset := u8((address - 0x1F801080) / 4)
    switch offset {
    case dpcr:
        dpcr_reg = value
    case dicr:
        dicr_reg.unknown = u8(value & 0x3F)
        dicr_reg.force_irq = ((value >> 15) & 1) != 0
        dicr_reg.irq_enable = u8((value >> 16) & 0x7F)
        dicr_reg.irq_master = ((value >> 23) & 1) != 0
        apa := u8((value >> 24) & 0x7F)
        dicr_reg.irq_flags &= ~apa
    case mdecin_ctrl, mdecout_ctrl, gpu_ctrl, cdrom_ctrl, spu_ctrl, pio_ctrl, otc_ctrl:
        dma_ctrl_write((offset - 2) / 4, value)
    case mdecin_madr, mdecout_madr, gpu_madr, cdrom_madr, spu_madr, pio_madr, otc_madr:
        channels[offset / 4].base_address = value & 0xFFFFFF
    case mdecin_bcr, mdecout_bcr, gpu_bcr, cdrom_bcr, spu_bcr, pio_bcr, otc_bcr:
        dma_bcr_write((offset - 1) / 4, value)
    case:
        panic("")
    }
}

@(private="file")
dma_ctrl_read :: proc(channel_nr: u8) -> u32 {
    //fmt.printf("Read ctrl: %i\n", channel_nr)
    channel := channels[channel_nr]
    rv := u32(channel.direction)
    rv |= u32(channel.address_step) << 1
    rv |= u32(channel.chopping) << 8
    rv |= u32(channel.sync_mode) << 9
    rv |= u32(channel.chop_dma_window) << 16
    rv |= u32(channel.chop_cpu_window) << 20
    rv |= u32(channel.start) << 24
    rv |= u32(channel.trigger) << 28
    rv |= u32(channel.unknown) << 29
    rv |= u32(channel.unknown2) << 30
    return rv
}

@(private="file")
dma_bcr_read :: proc(channel_nr: u8) -> u32 {
    //fmt.printf("Read bcr: %i\n", channel_nr)
    rv := u32(channels[channel_nr].block_size)
    rv |= u32(channels[channel_nr].block_amount) << 16
    return rv
}

@(private="file")
dma_ctrl_write :: proc(channel_nr: u8, value: u32) {
    //fmt.printf("Write ctrl: %i, 0x%x\n", channel_nr, value)
    channel := channels[channel_nr]
    if channel_nr == 6 {
        channel.direction = .to_ram
        channel.address_step = .backward
        channel.chopping = false
        channel.sync_mode = .all
        channel.chop_dma_window = 0
        channel.chop_cpu_window = 0
        channel.unknown = 0
    } else {
        channel.direction = Direction(value & 1)
        channel.address_step = Step((value >> 1) & 1)
        channel.chopping = bool((value >> 8) & 1)
        channel.sync_mode = SyncMode((value >> 9) & 3)
        channel.chop_dma_window = (value >> 16) & 7
        channel.chop_cpu_window = (value >> 20) & 7
        channel.unknown = (value >> 29) & 3
    }
    channel.start = bool((value >> 24) & 1)
    channel.trigger = bool((value >> 28) & 1)
    channel.unknown2 = ((value >> 30) & 1)
    channels[channel_nr] = channel

    if (dpcr_reg >> (4 * u32(channel_nr) + 3)) & 1 > 0 {
        if channel.trigger {
            if channel.start {
                dma_transfer(channel_nr)
            }
        } else {
            dma_transfer(channel_nr)
        }
    }
}

@(private="file")
dma_bcr_write :: proc(channel_nr: u8, value: u32) {
    //fmt.printf("Write bcr: %i, 0x%x\n", channel_nr, value)
    channels[channel_nr].block_size = u16(value)
    channels[channel_nr].block_amount = u16(value >> 16)
}

@(private="file")
dma_transfer :: proc(channel_nr: u8) {
    channel := channels[channel_nr]
    channels[channel_nr].trigger = false

    //Do transfer
    start_addr := i32(channel.base_address) & 0x1FFFFC
    step: i32
    switch channel.address_step {
    case .backward:
        step = -4
    case .forward:
        step = 4
    }

    block_size: u32
    switch channel.sync_mode {
    case .all:
        block_size = u32(channel.block_size)
        switch channel_nr {
        case 6:
            dma_do_otc(block_size, start_addr, step)
        case:
            fmt.printf("Immidiate 'all' transfer not supported for channel: %i\n", channel_nr)
            panic("")
        }
    case .sync:
        block_size = u32(channel.block_size) * u32(channel.block_amount)
        dma_do_synced(block_size, start_addr, step, channel_nr)
    case .linked:
        switch channel_nr {
        case 2:
            dma_do_linked(start_addr, step)
        case:
            fmt.printf("Immidiate 'linked' transfer not supported for channel: %i\n", channel_nr)
            panic("")
        }
    }

    channels[channel_nr].start = false
}

@(private="file")
dma_do_otc :: proc(block_size2: u32, start_addr2: i32, step: i32) {
    start_addr := start_addr2
    block_size := block_size2

    for block_size > 0 {
        value: i32
        switch block_size {
        case 1:
            value = 0xFFFFFF
        case:
            value = (start_addr - 4) & 0x1FFFFC
        }
        bus_write32(u32(start_addr), u32(value))

        start_addr += step
        start_addr &= 0x1FFFFC
        block_size -= 1
    }
}

@(private="file")
dma_do_synced :: proc(block_size2: u32, start_addr2: i32, step: i32, channel_nr: u8) {
    start_addr := start_addr2
    block_size := block_size2

    for block_size > 0 {
        value := bus_read32(u32(start_addr))
        switch channel_nr {
        case 0:
            mdec_write32(0x1F801820, value)
        case 2:
            gpu_gp0(value)
        case:
            fmt.printf("Immidiate 'sync' transfer not supported for channel: %i\n", channel_nr)
            panic("")
        }
        start_addr += step
        block_size -= 1
    }
    //TODO: Update MADR
}

@(private="file")
dma_do_linked :: proc(start_addr: i32, step: i32) {
    next_addr := u32(start_addr)

    for next_addr != 0xFFFFFF {
        addr := next_addr
        header := bus_read32(u32(next_addr & 0x1FFFFC))
        packet_size := header >> 24
        next_addr = header & 0xFFFFFF

        for packet_size > 0 {
            addr += 4
            gpu_gp0(bus_read32(addr))
            packet_size -= 1
        }
    }
    //TODO: Update MADR
}