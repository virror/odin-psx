package main

import "core:fmt"
import "base:intrinsics"

@(private="file")
Vector2i16 :: distinct [2]i16
@(private="file")
Vector3i16 :: distinct [3]i16
@(private="file")
Vector3i32 :: distinct [3]i32
@(private="file")
Vector3f32 :: distinct [3]f32
@(private="file")
Rgbc :: distinct [4]u8

table:= [?]u16 {
    0xff, 0xfd, 0xfb, 0xf9, 0xf7, 0xf5, 0xf3, 0xf1,
    0xef, 0xee, 0xec, 0xea, 0xe8, 0xe6, 0xe4, 0xe3,
    0xe1, 0xdf, 0xdd, 0xdc, 0xda, 0xd8, 0xd6, 0xd5,
    0xd3, 0xd1, 0xd0, 0xce, 0xcd, 0xcb, 0xc9, 0xc8,
    0xc6, 0xc5, 0xc3, 0xc1, 0xc0, 0xbe, 0xbd, 0xbb,
    0xba, 0xb8, 0xb7, 0xb5, 0xb4, 0xb2, 0xb1, 0xb0,
    0xae, 0xad, 0xab, 0xaa, 0xa9, 0xa7, 0xa6, 0xa4,
    0xa3, 0xa2, 0xa0, 0x9f, 0x9e, 0x9c, 0x9b, 0x9a,
    0x99, 0x97, 0x96, 0x95, 0x94, 0x92, 0x91, 0x90,
    0x8f, 0x8d, 0x8c, 0x8b, 0x8a, 0x89, 0x87, 0x86,
    0x85, 0x84, 0x83, 0x82, 0x81, 0x7f, 0x7e, 0x7d,
    0x7c, 0x7b, 0x7a, 0x79, 0x78, 0x77, 0x75, 0x74,
    0x73, 0x72, 0x71, 0x70, 0x6f, 0x6e, 0x6d, 0x6c,
    0x6b, 0x6a, 0x69, 0x68, 0x67, 0x66, 0x65, 0x64,
    0x63, 0x62, 0x61, 0x60, 0x5f, 0x5e, 0x5d, 0x5d,
    0x5c, 0x5b, 0x5a, 0x59, 0x58, 0x57, 0x56, 0x55,
    0x54, 0x53, 0x53, 0x52, 0x51, 0x50, 0x4f, 0x4e,
    0x4d, 0x4d, 0x4c, 0x4b, 0x4a, 0x49, 0x48, 0x48,
    0x47, 0x46, 0x45, 0x44, 0x43, 0x43, 0x42, 0x41,
    0x40, 0x3f, 0x3f, 0x3e, 0x3d, 0x3c, 0x3c, 0x3b,
    0x3a, 0x39, 0x39, 0x38, 0x37, 0x36, 0x36, 0x35,
    0x34, 0x33, 0x33, 0x32, 0x31, 0x31, 0x30, 0x2f,
    0x2e, 0x2e, 0x2d, 0x2c, 0x2c, 0x2b, 0x2a, 0x2a,
    0x29, 0x28, 0x28, 0x27, 0x26, 0x26, 0x25, 0x24,
    0x24, 0x23, 0x22, 0x22, 0x21, 0x20, 0x20, 0x1f,
    0x1e, 0x1e, 0x1d, 0x1d, 0x1c, 0x1b, 0x1b, 0x1a,
    0x19, 0x19, 0x18, 0x18, 0x17, 0x16, 0x16, 0x15,
    0x15, 0x14, 0x14, 0x13, 0x12, 0x12, 0x11, 0x11,
    0x10, 0x0f, 0x0f, 0x0e, 0x0e, 0x0d, 0x0d, 0x0c,
    0x0c, 0x0b, 0x0a, 0x0a, 0x09, 0x09, 0x08, 0x08,
    0x07, 0x07, 0x06, 0x06, 0x05, 0x05, 0x04, 0x04,
    0x03, 0x03, 0x02, 0x02, 0x01, 0x01, 0x00, 0x00,
    0x00,
}

@(private="file")
Mult_matrix :: enum {
    Rotation,
    Light,
    Color,
    Reserved,
}

@(private="file")
Mult_vector :: enum {
    V0,
    V1,
    V2,
    IR,
}

@(private="file")
Trans_vector :: enum {
    TR,
    BK,
    FC,
    None,
}

@(private="file")
Matrix :: struct {
    m11: i16,
    m12: i16,
    m13: i16,
    m21: i16,
    m22: i16,
    m23: i16,
    m31: i16,
    m32: i16,
    m33: i16,
}

@(private="file")
Gte_data :: struct {
    v: [3]Vector3i16,
    rgbc: [4]u8,
    otz: u16,
    ir: [4]i16,
    sxy: [3]Vector2i16,
    sxyp: Vector2i16,
    sz: [4]u16,
    rgb: [3]Rgbc,
    res1: u32,
    mac: [4]i32,
    irgb: i16,
    lzcs: i32,
    lzcr: i32,
}

@(private="file")
Gte_ctrl :: struct {
    rt: Matrix,
    tr: Vector3i32,
    llm: Matrix,
    bk: Vector3i32,
    lcm: Matrix,
    fc: Vector3i32,
    ofx: i32,
    ofy: i32,
    h: u16,
    dqa: i16,
    dqb: i32,
    zsf3: i16,
    zsf4: i16,
    flag: u32,
}

@(private="file")
gte_data: Gte_data
@(private="file")
gte_ctrl: Gte_ctrl

gte_get :: proc(reg: u32) -> u32 {
    switch reg {
    case 0:
        return u32(u16(gte_data.v[0].x)) | (u32(gte_data.v[0].y) << 16)
    case 1:
        return u32(gte_data.v[0].z)
    case 2:
        return u32(u16(gte_data.v[1].x)) | (u32(gte_data.v[1].y) << 16)
    case 3:
        return u32(gte_data.v[1].z)
    case 4:
        return u32(u16(gte_data.v[2].x)) | (u32(gte_data.v[2].y) << 16)
    case 5:
        return u32(gte_data.v[2].z)
    case 6:
        return u32(gte_data.rgbc[0]) | (u32(gte_data.rgbc[1]) << 8) |
                (u32(gte_data.rgbc[2]) << 16) | (u32(gte_data.rgbc[3]) << 24)
    case 7:     //OTZ
        return u32(gte_data.otz)
    case 8:
        return u32(gte_data.ir[0])
    case 9:
        return u32(gte_data.ir[1])
    case 10:
        return u32(gte_data.ir[2])
    case 11:
        return u32(gte_data.ir[3])
    case 12:
        return u32(u16(gte_data.sxy[0].x)) | (u32(gte_data.sxy[0].y) << 16)
    case 13:
        return u32(u16(gte_data.sxy[1].x)) | (u32(gte_data.sxy[1].y) << 16)
    case 14:
        return u32(u16(gte_data.sxy[2].x)) | (u32(gte_data.sxy[2].y) << 16)
    case 15:
        return u32(u16(gte_data.sxy[2].x)) | (u32(gte_data.sxy[2].y) << 16)
    case 16:
        return u32(gte_data.sz[0])
    case 17:
        return u32(gte_data.sz[1])
    case 18:
        return u32(gte_data.sz[2])
    case 19:
        return u32(gte_data.sz[3])
    case 20:
        return u32(gte_data.rgb[0].r) | (u32(gte_data.rgb[0].g) << 8) |
                (u32(gte_data.rgb[0].b) << 16) | (u32(gte_data.rgb[0].a) << 24)
    case 21:
        return u32(gte_data.rgb[1].r) | (u32(gte_data.rgb[1].g) << 8) |
                (u32(gte_data.rgb[1].b) << 16) | (u32(gte_data.rgb[1].a) << 24)
    case 22:
        return u32(gte_data.rgb[2].r) | (u32(gte_data.rgb[2].g) << 8) |
                (u32(gte_data.rgb[2].b) << 16) | (u32(gte_data.rgb[2].a) << 24)
    case 23:
        return gte_data.res1
    case 24:    //MAC0
        return u32(gte_data.mac[0])
    case 25:
        return u32(gte_data.mac[1])
    case 26:
        return u32(gte_data.mac[2])
    case 27:
        return u32(gte_data.mac[3])
    case 28:
        return u32(u16(gte_data.irgb))
    case 29:
        return u32(u16(gte_data.irgb))
    case 30:
        return u32(gte_data.lzcs)
    case 31:
        if u32(gte_data.lzcs) & 0x80000000 > 0 {
            return u32(intrinsics.count_leading_zeros(~gte_data.lzcs))
        } else {
            return u32(intrinsics.count_leading_zeros(gte_data.lzcs))
        }
    case 32:
        return u32(u16(gte_ctrl.rt.m11)) | (u32(gte_ctrl.rt.m12) << 16)
    case 33:
        return u32(u16(gte_ctrl.rt.m13)) | (u32(gte_ctrl.rt.m21) << 16)
    case 34:
        return u32(u16(gte_ctrl.rt.m22)) | (u32(gte_ctrl.rt.m23) << 16)
    case 35:
        return u32(u16(gte_ctrl.rt.m31)) | (u32(gte_ctrl.rt.m32) << 16)
    case 36:
        return u32(gte_ctrl.rt.m33)
    case 37:
        return u32(gte_ctrl.tr.x)
    case 38:
        return u32(gte_ctrl.tr.y)
    case 39:
        return u32(gte_ctrl.tr.z)
    case 40:
        return u32(u16(gte_ctrl.llm.m11)) | (u32(gte_ctrl.llm.m12) << 16)
    case 41:
        return u32(u16(gte_ctrl.llm.m13)) | (u32(gte_ctrl.llm.m21) << 16)
    case 42:
        return u32(u16(gte_ctrl.llm.m22)) | (u32(gte_ctrl.llm.m23) << 16)
    case 43:
        return u32(u16(gte_ctrl.llm.m31)) | (u32(gte_ctrl.llm.m32) << 16)
    case 44:
        return u32(gte_ctrl.llm.m33)
    case 45:
        return u32(gte_ctrl.bk.x)
    case 46:
        return u32(gte_ctrl.bk.y)
    case 47:
        return u32(gte_ctrl.bk.z)
    case 48:
        return u32(u16(gte_ctrl.lcm.m11)) | (u32(gte_ctrl.lcm.m12) << 16)
    case 49:
        return u32(u16(gte_ctrl.lcm.m13)) | (u32(gte_ctrl.lcm.m21) << 16)
    case 50:
        return u32(u16(gte_ctrl.lcm.m22)) | (u32(gte_ctrl.lcm.m23) << 16)
    case 51:
        return u32(u16(gte_ctrl.lcm.m31)) | (u32(gte_ctrl.lcm.m32) << 16)
    case 52:
        return u32(gte_ctrl.lcm.m33)
    case 53:
        return u32(gte_ctrl.fc.x)
    case 54:
        return u32(gte_ctrl.fc.y)
    case 55:
        return u32(gte_ctrl.fc.z)
    case 56:
        return u32(gte_ctrl.ofx)
    case 57:
        return u32(gte_ctrl.ofy)
    case 58:
        return u32(i16(gte_ctrl.h))
    case 59:
        return u32(gte_ctrl.dqa)
    case 60:
        return u32(gte_ctrl.dqb)
    case 61:
        return u32(gte_ctrl.zsf3)
    case 62:
        return u32(gte_ctrl.zsf4)
    case 63:
        flag := (gte_ctrl.flag & 0x7FFFF000) | u32((gte_ctrl.flag & 0x7F87E000) != 0) << 31
        return flag
    case:
        return 0
    }
}

gte_set :: proc(reg: u32, value: u32) {
    switch reg {
    case 0:
        gte_data.v[0].x = i16(value & 0xFFFF)
        gte_data.v[0].y = i16(value >> 16)
    case 1:
        gte_data.v[0].z = i16(value & 0xFFFF)
    case 2:
        gte_data.v[1].x = i16(value & 0xFFFF)
        gte_data.v[1].y = i16(value >> 16)
    case 3:
        gte_data.v[1].z = i16(value & 0xFFFF)
    case 4:
        gte_data.v[2].x = i16(value & 0xFFFF)
        gte_data.v[2].y = i16(value >> 16)
    case 5:
        gte_data.v[2].z = i16(value & 0xFFFF)
    case 6:
        gte_data.rgbc[0] = u8(value)
        gte_data.rgbc[1] = u8((value >> 8) & 0xFF)
        gte_data.rgbc[2] = u8((value >> 16) & 0xFF)
        gte_data.rgbc[3] = u8((value >> 24) & 0xFF)
    case 7:
        gte_data.otz = u16(value)
    case 8:
        gte_data.ir[0] = i16(value)
    case 9:
        gte_data.ir[1] = i16(value)
    case 10:
        gte_data.ir[2] = i16(value)
    case 11:
        gte_data.ir[3] = i16(value)
    case 12:    //SXY0
        gte_data.sxy[0].x = i16(value & 0xFFFF)
        gte_data.sxy[0].y = i16(value >> 16)
    case 13:    //SXY1
        gte_data.sxy[1].x = i16(value & 0xFFFF)
        gte_data.sxy[1].y = i16(value >> 16)
    case 14:    //SXY2
        gte_data.sxy[2].x = i16(value & 0xFFFF)
        gte_data.sxy[2].y = i16(value >> 16)
    case 15:
        gte_data.sxy[0].x = gte_data.sxy[1].x
        gte_data.sxy[1].x = gte_data.sxy[2].x
        gte_data.sxy[2].x = i16(value & 0xFFFF)
        gte_data.sxy[0].y = gte_data.sxy[1].y
        gte_data.sxy[1].y = gte_data.sxy[2].y
        gte_data.sxy[2].y = i16(value >> 16)
    case 16:    //SZ0
        gte_data.sz[0] = u16(value)
    case 17:    //SZ1
        gte_data.sz[1] = u16(value)
    case 18:    //SZ2
        gte_data.sz[2] = u16(value)
    case 19:    //SZ3
        gte_data.sz[3] = u16(value)
    case 20:
        gte_data.rgb[0].r = u8(value)
        gte_data.rgb[0].g = u8((value >> 8) & 0xFF)
        gte_data.rgb[0].b = u8((value >> 16) & 0xFF)
        gte_data.rgb[0].a = u8((value >> 24) & 0xFF)
    case 21:
        gte_data.rgb[1].r = u8(value)
        gte_data.rgb[1].g = u8((value >> 8) & 0xFF)
        gte_data.rgb[1].b = u8((value >> 16) & 0xFF)
        gte_data.rgb[1].a = u8((value >> 24) & 0xFF)
    case 22:
        gte_data.rgb[2].r = u8(value)
        gte_data.rgb[2].g = u8((value >> 8) & 0xFF)
        gte_data.rgb[2].b = u8((value >> 16) & 0xFF)
        gte_data.rgb[2].a = u8((value >> 24) & 0xFF)
    case 23:
        gte_data.res1 = value
    case 24:
        gte_data.mac[0] = i32(value)
    case 25:
        gte_data.mac[1] = i32(value)
    case 26:
        gte_data.mac[2] = i32(value)
    case 27:
        gte_data.mac[3] = i32(value)
    case 28:
        gte_data.ir[1] = i16((value & 0x1F) * 0x80)
        gte_data.ir[2] = i16(((value >> 5) & 0x1F) * 0x80)
        gte_data.ir[3] = i16(((value>> 10) & 0x1F) * 0x80)
        gte_data.irgb = i16(value) & 0x7FFF
    case 29:
        //Read-only
    case 30:
        gte_data.lzcs = i32(value)
    case 31:
        //Read-only
    case 32:
        gte_ctrl.rt.m11 = i16(value & 0xFFFF)
        gte_ctrl.rt.m12 = i16(value >> 16)
    case 33:
        gte_ctrl.rt.m13 = i16(value & 0xFFFF)
        gte_ctrl.rt.m21 = i16(value >> 16)
    case 34:
        gte_ctrl.rt.m22 = i16(value & 0xFFFF)
        gte_ctrl.rt.m23 = i16(value >> 16)
    case 35:
        gte_ctrl.rt.m31 = i16(value & 0xFFFF)
        gte_ctrl.rt.m32 = i16(value >> 16)
    case 36:
        gte_ctrl.rt.m33 = i16(value & 0xFFFF)
    case 37:
        gte_ctrl.tr.x = i32(value)
    case 38:
        gte_ctrl.tr.y = i32(value)
    case 39:
        gte_ctrl.tr.z = i32(value)
    case 40:
        gte_ctrl.llm.m11 = i16(value & 0xFFFF)
        gte_ctrl.llm.m12 = i16(value >> 16)
    case 41:
        gte_ctrl.llm.m13 = i16(value & 0xFFFF)
        gte_ctrl.llm.m21 = i16(value >> 16)
    case 42:
        gte_ctrl.llm.m22 = i16(value & 0xFFFF)
        gte_ctrl.llm.m23 = i16(value >> 16)
    case 43:
        gte_ctrl.llm.m31 = i16(value & 0xFFFF)
        gte_ctrl.llm.m32 = i16(value >> 16)
    case 44:
        gte_ctrl.llm.m33 = i16(value & 0xFFFF)
    case 45:
        gte_ctrl.bk.x = i32(value)
    case 46:
        gte_ctrl.bk.y = i32(value)
    case 47:
        gte_ctrl.bk.z = i32(value)
    case 48:
        gte_ctrl.lcm.m11 = i16(value & 0xFFFF)
        gte_ctrl.lcm.m12 = i16(value >> 16)
    case 49:
        gte_ctrl.lcm.m13 = i16(value & 0xFFFF)
        gte_ctrl.lcm.m21 = i16(value >> 16)
    case 50:
        gte_ctrl.lcm.m22 = i16(value & 0xFFFF)
        gte_ctrl.lcm.m23 = i16(value >> 16)
    case 51:
        gte_ctrl.lcm.m31 = i16(value & 0xFFFF)
        gte_ctrl.lcm.m32 = i16(value >> 16)
    case 52:
        gte_ctrl.lcm.m33 = i16(value & 0xFFFF)
    case 53:
        gte_ctrl.fc.x = i32(value)
    case 54:
        gte_ctrl.fc.y = i32(value)
    case 55:
        gte_ctrl.fc.z = i32(value)
    case 56:    //OFX
        gte_ctrl.ofx = i32(value)
    case 57:    //OFY
        gte_ctrl.ofy = i32(value)
    case 58:    //H
        gte_ctrl.h = u16(value)
    case 59:    //DQA
        gte_ctrl.dqa = i16(value)
    case 60:    //DQB
        gte_ctrl.dqb = i32(value)
    case 61:    //ZSF3
        gte_ctrl.zsf3 = i16(value)
    case 62:    //ZSF4
        gte_ctrl.zsf4 = i16(value)
    case 63:
        gte_ctrl.flag = value
    }
}

gte_command :: proc(value: u32) {
    command := value & 0x3F
    switch command {
    case 0x01:      //RTPS
        gte_01(value)
    case 0x06:      //NCLIP
        gte_06(value)
    case 0x0C:      //OP
        gte_0C(value)
    case 0x10:      //DPCS
        gte_10(value)
    case 0x11:      //INTPL
        gte_11(value)
    case 0x12:      //MVMVA
        gte_12(value)
    case 0x13:      //NCDS
        gte_13(value)
    case 0x14:      //CDP
        gte_14(value)
    case 0x16:      //NCDT
        gte_16(value)
    case 0x1B:      //NCCS
        gte_1B(value)
    case 0x1C:      //CC
        gte_1C(value)
    case 0x1E:      //NCS
        gte_1E(value)
    case 0x20:      //NCT
        gte_20(value)
    case 0x28:      //SQR
        gte_28(value)
    case 0x29:      //DCPL
        gte_29(value)
    case 0x2A:      //DCCT
        gte_2A(value)
    case 0x2D:      //AVSZ3
        gte_2D(value)
    case 0x2E:      //AVSZ4
        gte_2E(value)
    case 0x30:      //RTPT
        gte_30(value)
    case 0x3D:      //GPF
        gte_3D(value)
    case 0x3E:      //GPT
        gte_3E(value)
    case 0x3F:      //NCCT
        gte_3F(value)
    case:
        fmt.printf("Unimplemented gte command: 0x%x\n", command)
        panic("")
    }
}

@(private="file")
gte_get_sf :: proc(command: u32) -> u32 {
    return (command >> 19) & 0x1
}

@(private="file")
gte_get_mm :: proc(command: u32) -> Mult_matrix {
    return Mult_matrix((command >> 17) & 0x3)
}

@(private="file")
gte_get_mv :: proc(command: u32) -> Mult_vector {
    return Mult_vector((command >> 15) & 0x3)
}

@(private="file")
gte_get_tv :: proc(command: u32) -> Trans_vector {
    return Trans_vector((command >> 13) & 0x3)
}

@(private="file")
gte_get_lm :: proc(command: u32) -> bool {
    return bool((command >> 10) & 0x1)
}

@(private="file")
gte_clamp_ir :: proc(input: i32, lm: bool, index: u32) -> i16 {
    retval := input
    if input < 0  && lm{
        retval = 0
        gte_ctrl.flag |= index
    } else if input < -0x8000 && !lm {
        retval = -0x8000
        gte_ctrl.flag |= index
    } else if input > 0x7FFF {
        retval = 0x7FFF
        gte_ctrl.flag |= index
    }
    return i16(retval)
}

@(private="file")
gte_clamp_ir3 :: proc(input: i32, lm: bool) -> i16 {
    retval := input
    if input < 0  && lm{
        retval = 0
    } else if input < -0x8000 && !lm {
        retval = -0x8000
    } else if input > 0x7FFF {
        retval = 0x7FFF
    }
    if ((input >> 12) < -0x8000) || ((input >> 12) > 0x7FFF) {
        gte_ctrl.flag |= 0x400000
    }
    return i16(retval)
}

@(private="file")
gte_clamp_sz3 :: proc(input: i32) ->u16 {
    retval := input
    if input < 0 {
        retval = 0
        gte_ctrl.flag |= 0x40000
    } else if input > 0xFFFF {
        retval = 0xFFFF
        gte_ctrl.flag |= 0x40000
    }
    return u16(retval)
}

@(private="file")
gte_clamp_rtp_div :: proc() ->i64 {
    h := gte_ctrl.h
    sz3 := gte_data.sz[3]

    if h < (sz3 * 2) {
        z := intrinsics.count_leading_zeros(sz3)
        n := i64(u64(h) << u64(z))
        d := i64(u64(sz3) << u64(z))
        u := i64(table[(d - 0x7FC0) >> 7] + 0x101)
        d = (0x2000080 - (u * d)) >> 8
        d = (0x0000080 + (u * d)) >> 8
        return min(0x1FFFF, (((d * n) + 0x8000) >> 16))
    } else {
        gte_ctrl.flag |= 0x20000
        return 0x1FFFF
    }
}

@(private="file")
gte_check_mac123:: proc(input: i64, index: u32) {
    if input > 0x7FFFFFFFFFF {
        gte_ctrl.flag |= (index)
    } else if input < -0x80000000000 {
        gte_ctrl.flag |= (index >> 3)
    }
}

@(private="file")
gte_check_mac0:: proc(input: i64) {
    if input > 2147483647 {
        gte_ctrl.flag |= 0x10000
    } else if input < -2147483648 {
        gte_ctrl.flag |= 0x8000
    }
}

@(private="file")
gte_clamp_sx:: proc(input: i64) ->i16 {
    retval := input
    if input < -0x400 {
        retval = -0x400
        gte_ctrl.flag |= 0x4000
    } else if input > 0x3FF {
        retval = 0x3FF
        gte_ctrl.flag |= 0x4000
    }
    return i16(retval)
}

@(private="file")
gte_clamp_sy:: proc(input: i64) ->i16 {
    retval := input
    if input < -0x400 {
        retval = -0x400
        gte_ctrl.flag |= 0x2000
    } else if input > 0x3FF {
        retval = 0x3FF
        gte_ctrl.flag |= 0x2000
    }
    return i16(retval)
}

@(private="file")
gte_clamp_ir0:: proc(input: i64) ->i16 {
    retval := input
    if input < 0 {
        retval = 0
        gte_ctrl.flag |= 0x1000
    } else if input > 0x1000 {
        retval = 0x1000
        gte_ctrl.flag |= 0x1000
    }
    return i16(retval)
}

@(private="file")
gte_01 :: proc(command: u32) {
    gte_set(15, 0) //Shift FIFO
    gte_data.sz[0] = gte_data.sz[1]
    gte_data.sz[1] = gte_data.sz[2]
    gte_data.sz[2] = gte_data.sz[3]
    gte_ctrl.flag = 0x0

    sf := gte_get_sf(command)
    lm := gte_get_lm(command)

    mac1 := (i64(gte_ctrl.tr.x) * 0x1000 + i64(gte_ctrl.rt.m11) * i64(gte_data.v[0].x) + i64(gte_ctrl.rt.m12) *
                      i64(gte_data.v[0].y) + i64(gte_ctrl.rt.m13) * i64(gte_data.v[0].z))
    gte_check_mac123(mac1, 0x40000000)
    gte_data.mac[1] = i32(mac1 >> (sf * 12))
    mac2 := (i64(gte_ctrl.tr.y) * 0x1000 + i64(gte_ctrl.rt.m21) * i64(gte_data.v[0].x) + i64(gte_ctrl.rt.m22) *
                      i64(gte_data.v[0].y) + i64(gte_ctrl.rt.m23) * i64(gte_data.v[0].z))
    gte_check_mac123(mac2, 0x20000000)
    gte_data.mac[2] = i32(mac2 >> (sf * 12))
    mac3 := (i64(gte_ctrl.tr.z) * 0x1000 + i64(gte_ctrl.rt.m31) * i64(gte_data.v[0].x) + i64(gte_ctrl.rt.m32) *
                      i64(gte_data.v[0].y) + i64(gte_ctrl.rt.m33) * i64(gte_data.v[0].z))
    gte_check_mac123(mac3, 0x10000000)
    gte_data.mac[3] = i32(mac3 >> (sf * 12))

    gte_data.ir[1] = gte_clamp_ir(gte_data.mac[1], lm, 0x1000000)
    gte_data.ir[2] = gte_clamp_ir(gte_data.mac[2], lm, 0x800000)
    if sf == 0 {
        gte_data.ir[3] = gte_clamp_ir3(gte_data.mac[3], lm)
    } else {
        gte_data.ir[3] = gte_clamp_ir(gte_data.mac[3], lm, 0x400000)
    }

    gte_data.irgb = clamp(gte_data.ir[1] / 0x80, 0, 0x1F) | (clamp(gte_data.ir[2] / 0x80, 0, 0x1F) << 5) |
                    (clamp(gte_data.ir[3] / 0x80, 0, 0x1F) << 10)

    sz3 := i32((mac3 >> (sf * 12)) >> ((1 - sf) * 12))
    gte_data.sz[3] = gte_clamp_sz3(sz3)
    div_res := gte_clamp_rtp_div()

    mac0 := div_res * i64(gte_data.ir[1]) + i64(gte_ctrl.ofx)
    gte_check_mac0(mac0)
    gte_data.sxy[2].x = gte_clamp_sx(mac0 >> 16)

    mac0 = div_res * i64(gte_data.ir[2]) + i64(gte_ctrl.ofy)
    gte_check_mac0(mac0)
    gte_data.sxy[2].y = gte_clamp_sy(mac0 >> 16)

    mac0 = div_res * i64(gte_ctrl.dqa) + i64(gte_ctrl.dqb)
    gte_check_mac0(mac0)

    gte_data.ir[0] = gte_clamp_ir0(mac0 >> 12)
    gte_data.mac[0] = i32(mac0)
}

@(private="file")
gte_06 :: proc(command: u32) {
    sx0 := i32(gte_data.sxy[0].x)
    sx1 := i32(gte_data.sxy[1].x)
    sx2 := i32(gte_data.sxy[2].x)
    sy0 := i32(gte_data.sxy[0].y)
    sy1 := i32(gte_data.sxy[1].y)
    sy2 := i32(gte_data.sxy[2].y)
    gte_data.mac[0] = sx0 * sy1 + sx1 * sy2 + sx2 * sy0 - sx0 * sy2 - sx1 * sy0 - sx2 * sy1
}

@(private="file")
gte_0C :: proc(command: u32) {

}

@(private="file")
gte_10 :: proc(command: u32) {

}

@(private="file")
gte_11 :: proc(command: u32) {

}

@(private="file")
gte_12 :: proc(command: u32) {

}

@(private="file")
gte_13 :: proc(command: u32) {

}

@(private="file")
gte_14 :: proc(command: u32) {

}

@(private="file")
gte_16 :: proc(command: u32) {

}

@(private="file")
gte_1B :: proc(command: u32) {

}

@(private="file")
gte_1C :: proc(command: u32) {

}

@(private="file")
gte_1E :: proc(command: u32) {

}

@(private="file")
gte_20 :: proc(command: u32) {

}

@(private="file")
gte_28 :: proc(command: u32) {
    sf := gte_get_sf(command)
    lm := gte_get_lm(command)

    mac1 := (i64(gte_data.ir[1]) * i64(gte_data.ir[1])) >> (sf * 12)
    gte_check_mac123(mac1, 0x40000000)
    gte_data.mac[1] = i32(mac1)
    mac2 := (i64(gte_data.ir[2]) * i64(gte_data.ir[2])) >> (sf * 12)
    gte_check_mac123(mac2, 0x20000000)
    gte_data.mac[2] = i32(mac2)
    mac3 := (i64(gte_data.ir[3]) * i64(gte_data.ir[3])) >> (sf * 12)
    gte_check_mac123(mac3, 0x10000000)
    gte_data.mac[3] = i32(mac3)

    gte_data.ir[1] = gte_clamp_ir(gte_data.mac[1], lm, 0x1000000)
    gte_data.ir[2] = gte_clamp_ir(gte_data.mac[2], lm, 0x800000)
    gte_data.ir[3] = gte_clamp_ir(gte_data.mac[3], lm, 0x400000)
}

@(private="file")
gte_29 :: proc(command: u32) {

}

@(private="file")
gte_2A :: proc(command: u32) {

}

@(private="file")
gte_2D :: proc(command: u32) {
    val :i32= i32(gte_ctrl.zsf3) * i32(gte_data.sz[1] + gte_data.sz[2] + gte_data.sz[3])
    gte_data.otz = u16(val / 0x1000)
    gte_data.mac[0] = val
}

@(private="file")
gte_2E :: proc(command: u32) {
    val :i32= i32(gte_ctrl.zsf4) * i32(gte_data.sz[0] + gte_data.sz[1] + gte_data.sz[2] + gte_data.sz[3])
    gte_data.otz = u16(val / 0x1000)
    gte_data.mac[0] = val
}

@(private="file")
gte_30 :: proc(command: u32) {

}

@(private="file")
gte_3D :: proc(command: u32) {

}

@(private="file")
gte_3E :: proc(command: u32) {

}

@(private="file")
gte_3F :: proc(command: u32) {

}