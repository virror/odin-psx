package main

import "core:fmt"

@(private="file")
exp1_base_addr: u32
@(private="file")
exp2_base_addr: u32
@(private="file")
exp1_delay: u32
@(private="file")
exp3_delay: u32
@(private="file")
bios_delay: u32
@(private="file")
spu_delay: u32
@(private="file")
cdrom_delay: u32
@(private="file")
exp2_delay: u32
@(private="file")
com_delay: u32
@(private="file")
ram_size: u32

memctrl_read32 :: proc(address: u32) -> u32 {
    switch address {
    case 0x1F801000:
        return (exp1_base_addr & 0x00FFFFFF) + 0x1F000000
    case 0x1F801004:
        return (exp2_base_addr & 0x00FFFFFF) + 0x1F000000
    case 0x1F801008:
        return exp1_delay
    case 0x1F80100C:
        return exp3_delay
    case 0x1F801010:
        return bios_delay
    case 0x1F801014:
        return spu_delay
    case 0x1F801018:
        return cdrom_delay
    case 0x1F80101C:
        return exp2_delay
    case 0x1F801020:
        return com_delay
    case 0x1F801060:
        return ram_size
    case:
        fmt.println("Invalid read from memctrl!")
        return 0
    }
}

memctrl_write32 :: proc(address: u32, value: u32) {
    switch address {
    case 0x1F801000:
        exp1_base_addr = value
    case 0x1F801004:
        exp2_base_addr = value
    case 0x1F801008:
        exp1_delay = value
    case 0x1F80100C:
        exp3_delay = value
    case 0x1F801010:
        bios_delay = value
    case 0x1F801014:
        spu_delay = value
    case 0x1F801018:
        cdrom_delay = value
    case 0x1F80101C:
        exp2_delay = value
    case 0x1F801020:
        com_delay = value
    case 0x1F801060:
        ram_size = value
    }
}