package main

import "core:fmt"
import "core:os"

main_mem: [0x200000]u8
spad_mem: [0x400]u8
bios_mem: [0x80000]u8

@(private="file")
bus_mask_tbl: []u32 = {0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0x7fffffff, 0x1fffffff, 0xffffffff, 0xffffffff}

bus_init :: proc() {
    file, err := os.open("scph1001.bin", os.O_RDONLY)
    assert(err == nil, "Failed to open bios")
    _, err2 := os.read(file, bios_mem[0x00000:0x7FFFF])
    assert(err2 == nil, "Failed to read bios data")
    os.close(file)
}

@(private="file")
bus_mask :: proc(address: u32) -> u32 {
    return address & bus_mask_tbl[address >> 29]
}

// TODO: Handle cache?
bus_read32 :: proc(address: u32) -> u32 {
    address := address
    if address >= 0xFFFE0000 { //reading from cache ctrl
        return 0
    }
    address = bus_mask(address)
    switch address {
    case 0..<0x00200000:            //Main mem
        return (cast(^u32)&main_mem[address])^
    case 0x1F000000..<0x1F800000:   //Exp 1
        return 0xFFFF
    case 0x1F800000..<0x1F800400:   //Scratchpad
        address -= 0x1F800000
        return (cast(^u32)&spad_mem[address])^
    case 0x1F801000..=0x1F801020:   //Mem ctrl 1
        return memctrl_read32(address)
    case 0x1F801040..=0x1F80105E:   //IO ports
        return u32(phr_read16(address))
    case 0x1F801060:                //Mem ctrl 2
        return memctrl_read32(address)
    case 0x1F801070:                //Interrupt status
        return cop0_get_status()
    case 0x1F801074:                //Interrupt mask
        return cop0_get_mask()
    case 0x1F801080..=0x1F8010F4:   //DMA
        return dma_read32(address)
    case 0x1F801100..=0x1F801128:   //Timers
        return tmr_read32(address)
    case 0x1F801800..=0x1F801803:   //CDRom
        return u32(cd_read8(address))
    case 0x1F801810..=0x1F801814:   //GPU
        return gpu_read32(address)
    case 0x1F801820..=0x1F801824:   //MDEC
        return mdec_read32(address)
    case 0x1F801C00..=0x1F801E80:   //SPU
        fmt.println(address)
    case 0x1F802000..=0x1F802064:   //Exp 2
        fmt.println(address)
    case 0x1FA00000..=0x1FBFFFFF:   //Exp 3
        fmt.println(address)
    case 0x1FC00000..<0x1FC80000:   //BIOS
        address -= 0x1FC00000
        return (cast(^u32)&bios_mem[address])^
    case:                           //Rest of memory
        fmt.println(address)
        panic("Unused mem access")
    }
    return 0
}

bus_read16 :: proc(address: u32) -> u16 {
    address := address
    if address % 2 != 0 {
        cop0_exception(.adel)
    }
    address = bus_mask(address)
    switch address {
    case 0..<0x00200000:            //Main mem
        return (cast(^u16)&main_mem[address])^
    case 0x1F000000..<0x1F800000:   //Exp 1
        return 0xFFFF
    case 0x1F800000..<0x1F800400:   //Scratchpad
        address -= 0x1F800000
        return (cast(^u16)&spad_mem[address])^
    case 0x1F801000..=0x1F801020:   //Mem ctrl 1
        fmt.println(address)
    case 0x1F801040..=0x1F80105E:   //IO ports
        return phr_read16(address)
    case 0x1F801060:                //Mem ctrl 2
        fmt.println(address)
    case 0x1F801070:                //Interrupt status
        return u16(cop0_get_status())
    case 0x1F801074:                //Interrupt mask
        return u16(cop0_get_mask())
    case 0x1F801080..=0x1F8010F4:   //DMA
        return u16(dma_read32(address))
    case 0x1F801100..=0x1F801128:   //Timers
        return tmr_read16(address)
    case 0x1F801800..=0x1F801803:   //CDRom
        return u16(cd_read8(address))
    case 0x1F801810..=0x1F801814:   //GPU
        return u16(gpu_read32(address))
    case 0x1F801820..=0x1F801824:   //MDEC
        return u16(mdec_read32(address))
    case 0x1F801C00..=0x1F801E80:   //SPU
        return spu_read16(address)
    case 0x1F802000..=0x1F802064:   //Exp 2
        fmt.println(address)
    case 0x1FA00000..=0x1FBFFFFF:   //Exp 3
        fmt.println(address)
    case 0x1FC00000..<0x1FC80000:   //BIOS
        address -= 0x1FC00000
        return (cast(^u16)&bios_mem[address])^
    case:                           //Rest of memory
        fmt.println(address)
        panic("Unused mem access")
    }
    return 0
}

bus_read8 :: proc(address: u32) -> u8 {
    address := address
    address = bus_mask(address)
    switch address {
    case 0..<0x1F000000:            //Main mem
        address = address & 0x1FFFFF
        return main_mem[address]
    case 0x1F000000..<0x1F800000:   //Exp 1
        return exp_read8(address)
    case 0x1F800000..<0x1F800400:   //Scratchpad
        address -= 0x1F800000
        return spad_mem[address]
    case 0x1F801000..=0x1F801020:   //Mem ctrl 1
        fmt.println(address)
    case 0x1F801040..=0x1F80105E:   //IO ports
        return phr_read8(address)
    case 0x1F801060:                //Mem ctrl 2
        fmt.println(address)
    case 0x1F801070:                //Interrupt status
        panic("Unimplemented read")
    case 0x1F801074:                //Interrupt mask
        return u8(cop0_get_mask())
    case 0x1F801080..=0x1F8010F4:   //DMA
        return u8(dma_read32(address))
    case 0x1F801100..=0x1F801128:   //Timers
        return u8(tmr_read16(address))
    case 0x1F801800..=0x1F801803:   //CDRom
        return cd_read8(address)
    case 0x1F801810..=0x1F801814:   //GPU
        return u8(gpu_read32(address))
    case 0x1F801820..=0x1F801824:   //MDEC
        fmt.println(address)
    case 0x1F801C00..=0x1F801E80:   //SPU
        fmt.println(address)
    case 0x1F802000..=0x1F802064:   //Exp 2
        return exp_read8(address)
    case 0x1FA00000..=0x1FBFFFFF:   //Exp 3
        return exp_read8(address)
    case 0x1FC00000..<0x1FC80000:   //BIOS
        address -= 0x1FC00000
        return bios_mem[address]
    case:                           //Rest of memory
        fmt.println(address)
        panic("Unused mem access")
    }
    return 0
}

bus_write32 :: proc(address: u32, value: u32) {
    address := address
    if cop0_get(sr) & 0x10000 != 0 { //Dont write to mem when cache is isolated
        return
    }
    if address >= 0xFFFE0000 { //Writing to cache ctrl
        return
    }
    address = bus_mask(address)
    switch address {
    case 0..<0x00200000:            //Main RAM
        (cast(^u32)&main_mem[address])^ = value
    case 0x1F000000..<0x1F800000:   //Exp 1
        fmt.println(address)
    case 0x1F800000..<0x1F800400:   //Scratchpad
        address -= 0x1F800000
        (cast(^u32)&spad_mem[address])^ = value
    case 0x1F801000..=0x1F801020:   //Mem ctrl 1
        memctrl_write32(address, value)
    case 0x1F801040..=0x1F80105E:   //IO ports
        phr_write16(address, u16(value))
    case 0x1F801060:                //Mem ctrl 2
        memctrl_write32(address, value)
    case 0x1F801070:                //Interrupt status
        cop0_set_status(value)
    case 0x1F801074:                //Interrupt mask
        cop0_set_mask(value)
    case 0x1F801080..=0x1F8010F4:   //DMA
        dma_write32(address, value)
    case 0x1F801100..=0x1F801128:   //Timers
        tmr_write32(address, value)
    case 0x1F801800..=0x1F801803:   //CDRom
        cd_write8(address, u8(value))
    case 0x1F801810..=0x1F801814:   //GPU
        gpu_write32(address, value)
    case 0x1F801820..=0x1F801824:   //MDEC
        mdec_write32(address, value)
    case 0x1F801C00..=0x1F801E80:   //SPU
        spu_write16(address, u16(value))
    case 0x1F802000..=0x1F804000:   //Exp 2
        fmt.println(address)
    case 0x1FA00000..=0x1FBFFFFF:   //Exp 3
        fmt.println(address)
    case 0x1FC00000..<0x1FC80000:   //Bios
        fmt.println("Read-only bios")
    case:                           //Rest of memory
        fmt.println(address)
        panic("Unused mem access")
    }
}

//TODO: Some regions will zero out rest of the word?
bus_write16 :: proc(address: u32, value: u32) {
    address := address
    if address % 2 != 0 {
        cop0_exception(.ades)
    }
    if cop0_get(sr) & 0x10000 != 0 { //Dont write to mem when cache is isolated
        return
    }
    address = bus_mask(address)
    switch address {
    case 0..<0x00200000:            //Main RAM
        (cast(^u16)&main_mem[address])^ = u16(value)
    case 0x1F000000..<0x1F800000:   //Exp 1
        fmt.println(address)
    case 0x1F800000..<0x1F800400:   //Scratchpad
        address -= 0x1F800000
        (cast(^u16)&spad_mem[address])^ = u16(value)
    case 0x1F801000..=0x1F801020:   //Mem ctrl 1
        fmt.println(address)
    case 0x1F801040..=0x1F80105E:   //IO ports
        phr_write16(address, u16(value))
    case 0x1F801060:                //Mem ctrl 2
        fmt.println(address)
    case 0x1F801070:                //Interrupt status
        cop0_set_status(u32(value))
    case 0x1F801074:                //Interrupt mask
        cop0_set_mask(u32(value))
    case 0x1F801080..=0x1F8010F4:   //DMA
        dma_write32(address, value)
    case 0x1F801100..=0x1F801128:   //Timers
        tmr_write16(address, u16(value))
    case 0x1F801800..=0x1F801803:   //CDRom
        cd_write8(address, u8(value))
    case 0x1F801810..=0x1F801814:   //GPU
        gpu_write32(address, value)
    case 0x1F801820..=0x1F801824:   //MDEC
        mdec_write32(address, u32(value))
    case 0x1F801C00..=0x1F801E80:   //SPU
        spu_write16(address, u16(value))
    case 0x1F802000..=0x1F804000:   //Exp 2
        fmt.println(address)
    case 0x1FA00000..=0x1FBFFFFF:   //Exp 3
        fmt.println(address)
    case 0x1FC00000..<0x1FC80000:   //Bios
        fmt.println("Read-only bios")
    case:                           //Rest of memory
        fmt.println(address)
        panic("Unused mem access")
    }
}

//TODO: Some regions will zero out rest of the word?
bus_write8 :: proc(address: u32, value: u32) {
    address := address
    if cop0_get(sr) & 0x10000 != 0 { //Dont write to mem when cache is isolated
        return
    }
    address = bus_mask(address)
    switch address {
    case 0..<0x1F000000:            //Main RAM
        address = address & 0x1FFFFF
        main_mem[address] = u8(value)
    case 0x1F000000..<0x1F800000:   //Exp 1
        exp_write8(address, u8(value))
    case 0x1F800000..<0x1F800400:   //Scratchpad
        address -= 0x1F800000
        spad_mem[address] = u8(value)
    case 0x1F801000..=0x1F801020:   //Mem ctrl 1
        fmt.println(address)
    case 0x1F801040..=0x1F80105E:   //IO ports
        phr_write8(address, u8(value))
    case 0x1F801060:                //Mem ctrl 2
        fmt.println(address)
    case 0x1F801070:                //Interrupt status
        cop0_set_status(u32(value))
    case 0x1F801074:                //Interrupt mask
        cop0_set_status(u32(value))
    case 0x1F801080..=0x1F8010F4:   //DMA
        dma_write32(address, (value))
    case 0x1F801100..=0x1F801128:   //Timers
        tmr_write16(address, u16(value))
    case 0x1F801800..=0x1F801803:   //CDRom
        cd_write8(address, u8(value))
    case 0x1F801810..=0x1F801814:   //GPU
        gpu_write32(address, value)
    case 0x1F801820..=0x1F801824:   //MDEC
        mdec_write32(address, u32(value))
    case 0x1F801C00..=0x1F801E80:   //SPU
        fmt.println(address)
    case 0x1F802000..=0x1F802064:   //Exp 2
        exp_write8(address, u8(value))
    case 0x1FA00000..=0x1FBFFFFF:   //Exp 3
        exp_write8(address, u8(value))
    case 0x1FC00000..<0x1FC80000:   //Bios
        fmt.println("Read-only bios")
    case:                           //Rest of memory
        fmt.println(address)
        panic("Unused mem access")
    }
}
