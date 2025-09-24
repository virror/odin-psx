package main

import "core:fmt"

Transp_mode :: enum u8 {
    Bd2pFd2,
    BpF,
    BmF,
    BpFd4,
}

Texture_colors :: enum u8 {
    n4bit,
    n8bit,
    n15bit,
}

Hor_res :: enum u8 {
    n256,
    n320,
    n512,
    n640,
    n368,
}

Vert_res :: enum u8 {
    n240,
    n480,
}

Video_mode :: enum u8 {
    ntsc,
    pal,
}

Color_depth :: enum u8 {
    n15,
    n24,
}

Dma_dir :: enum u8 {
    off,
    na,
    cputogpu,
    gputocpu,
}

Gpustat :: bit_field u32 {
    texture_x: u16                  | 4,
    texture_y: u16                  | 1,
    transparency: Transp_mode       | 2,
    texture_colors: Texture_colors  | 2,
    dither: bool                    | 1,
    draw_display: bool              | 1,
    set_mask: bool                  | 1,
    draw_pixels: bool               | 1,
    interlace: bool                 | 1,
    flip_screen: bool               | 1,
    texture_disable: bool           | 1,
    apa: bool                       | 1,
    hor_res: Hor_res                | 2,
    vert_res: Vert_res              | 1,
    video_mode: Video_mode          | 1,
    color_depth: Color_depth        | 1,
    vert_interlace: bool            | 1,
    disp_disable: bool              | 1,
    irq: bool                       | 1,
    dma: u8                         | 1,
    rtrcw: u8                       | 1,
    rtsvtc: u8                      | 1,
    rtrdb: u8                       | 1,
    dma_dir: Dma_dir                | 2,
    draw_odd: bool                  | 1,
}

CommandBuf :: struct {
    data: [12]u32,
    length: u32,
    pointer: u32,
    function: proc(value: u32),
    img_mode: bool,
    poly_mode: bool,
}

ImageData :: struct {
    width: u32,
    height: u32,
    dest_x: u32,
    dest_y: u32,
    i: u32,
    j: u32,
}

Vertex :: struct {
    x: i32,
    y: i32,
    c: u32,
    tc: Vector2u,
}

Rend_opt :: struct {
    shad: u32,
    tex: u32,
    trans: u32,
    raw: u32,
    poly: u32,
}

Draw_area :: struct {
    top: u16,
    bottom: u16,
    left: u16,
    right: u16,
}

Disp_range :: struct {
    x1: u16,
    x2: u16,
    y1: u16,
    y2: u16,
}

@(private="file")
CYCLES_PER_SCANLINE :: 2174
@(private="file")
LINES_TO_VBLANK :: 240
@(private="file")
LINES_PER_FRAME :: 263

gpustat: Gpustat

@(private="file")
cmd_buf: CommandBuf
@(private="file")
texture_flip: Vector2u
@(private="file")
disp_start: Vector2u
@(private="file")
disp_range: Disp_range
@(private="file")
tex_mask: Vector2u
@(private="file")
tex_offset: Vector2u
@(private="file")
draw_area: Draw_area
@(private="file")
draw_offset: Vector2i
@(private="file")
img_data: ImageData
@(private="file")
gpu_read_value: u32
@(private="file")
line_cnt: u32

@(private="file")
vram: [1024 * 512]u16
@(private="file")
vram24: [682 * 512]u32
texture: u32

gpu_init :: proc() {
    gpustat.disp_disable = true
    evt_add(CYCLES_PER_SCANLINE, hblank)
    create_quad({1,1}, {1,-1}, {-1, 1}, {-1, -1}, {1,1,1}, {1,1,1}, {1,1,1}, {1,1,1})
    line_cnt = 0
}

hblank :: proc() {
    line_cnt += 1

    if line_cnt < LINES_TO_VBLANK {
        gpustat.draw_odd = !gpustat.draw_odd
    }
    if line_cnt == LINES_TO_VBLANK {
        vblank()
    } else if line_cnt == LINES_PER_FRAME {
        line_cnt = 0
    }
    tmr_update_hblank()
    evt_add(CYCLES_PER_SCANLINE, hblank)
}

vblank :: proc() {
    width :i32= gpu_get_hor_res(gpustat.hor_res)
    height := (i32(gpustat.vert_res) + 1) * 240
    when SHOW_FULL_VRAM {
        if gpustat.color_depth == .n15 {
            width = 1024
        } else {
            width = 682
        }
        height = 512
    }
    if gpustat.color_depth == .n15 {
        texture = texture_create15(width, height, &vram[0])
    } else {
        apa :u32= 0
        for y :u32= 0; y < u32(height); y += 1 {
            for x :u32= 0; x < u32(width)-1; x += 3 {
                vram24[apa * 2 + y * 682] = (u32(vram[x + y * 1024])) | (u32(vram[x + 1 + y * 1024] & 0xFF00) << 8)
                vram24[apa * 2 + 1 + y * 682] = ((u32(vram[x + 1 + y * 1024]) & 0xFF)) | (u32(vram[x + 2 + y * 1024]) << 8)
                apa += 1
            }
            apa = 0
        }
        texture = texture_create24(width, height, &vram24[0])
    }
    update()
    texture_destroy(texture)
    cop0_set_irq(IRQ.VBLANK)
}

gpu_read32 :: proc(address: u32) -> u32 {
    switch address {
    case 0x1f801810:
        return gpu_read_read()
    case 0x1f801814:
        return gpu_read_stat()
    case:
        panic("Invalid gpu address")
    }
}

gpu_write32 :: proc(address: u32, value: u32) {
    switch address {
    case 0x1f801810:
        gpu_gp0(value)
    case 0x1f801814:
        gpu_gp1(value)
    }
}

gpu_gp0 :: proc(command: u32) {
    cmd := command >> 24
    value := command & 0xFFFFFF

    if cmd_buf.pointer == 0 {
        sub_cmd := command >> 29

        switch sub_cmd {
        case 0x0:   //Misc commands
            switch cmd {
            case 0x00:
                cmd_buf.function = gpu_0_00
                cmd_buf.length = 1
            case 0x01:
                cmd_buf.function = gpu_0_01
                cmd_buf.length = 1
            case 0x02:
                cmd_buf.function = gpu_0_02
                cmd_buf.length = 3
            case 0x1F:
                cmd_buf.function = gpu_0_1F
                cmd_buf.length = 1
            case:
                fmt.printf("gp0 write: 0x%x\n", command)
                panic("")
            }
        case 0x1:   //Tris
            gpu_cmd_tri(command)
        case 0x2:   //Lines
            gpu_cmd_line(command)
        case 0x3:   //Rects
            gpu_cmd_rect(command)
        case 0x4:   //VRAM-VRAM
            cmd_buf.function = gpu_0_80
            cmd_buf.length = 4
        case 0x5:   //CPU-VRAM
            cmd_buf.function = gpu_0_A0
            cmd_buf.length = 3
        case 0x6:   //VRAM-CPU
            cmd_buf.function = gpu_0_C0
            cmd_buf.length = 3
        case 0x7:   //Environment cmds
            switch cmd {
            case 0xE1:
                cmd_buf.function = gpu_0_e1
                cmd_buf.length = 1
            case 0xE2:
                cmd_buf.function = gpu_0_e2
                cmd_buf.length = 1
            case 0xE3:
                cmd_buf.function = gpu_0_e3
                cmd_buf.length = 1
            case 0xE4:
                cmd_buf.function = gpu_0_e4
                cmd_buf.length = 1
            case 0xE5:
                cmd_buf.function = gpu_0_e5
                cmd_buf.length = 1
            case 0xE6:
                cmd_buf.function = gpu_0_e6
                cmd_buf.length = 1
            }
        }
    }

    if cmd_buf.img_mode {
        gpu_img_transfer(command)
    } else if cmd_buf.poly_mode {
        cmd_buf.data[cmd_buf.pointer] = command
        cmd_buf.pointer += 1
        cmd_buf.length += 1

        if command == 0x55555555 || command == 0x50005000 {
            cmd_buf.poly_mode = false
            cmd_buf.pointer = 0
            cmd_buf.function(value)
        }
    } else {
        cmd_buf.data[cmd_buf.pointer] = command
        cmd_buf.pointer += 1

        if cmd_buf.length == cmd_buf.pointer {
            cmd_buf.pointer = 0
            cmd_buf.function(value)
        }
    }
}

@(private="file")
gpu_cmd_rect :: proc(command: u32) {
    cmd_buf.length = 2
    size := (command >> 27) & 0x3
    if size == 0 {
        cmd_buf.length += 1
    }
    if command & 0x4000000 > 0 {
        cmd_buf.length += 1
    }
    cmd_buf.function = gpu_rect
}

@(private="file")
gpu_cmd_line :: proc(command: u32) {
    cmd_buf.function = gpu_line
    poly := (command >> 27 & 0x1)
    if poly == 1 {
        cmd_buf.poly_mode = true
        cmd_buf.length = 0
        return
    }
    shad := (command >> 28 & 0x1)
    if shad == 1 {
        cmd_buf.length = 4
    } else {
        cmd_buf.length = 3
    }
}

@(private="file")
gpu_cmd_tri :: proc(command: u32) {
    shad := (command >> 28 & 0x1)
    quad := (command >> 27 & 0x1)
    tex := (command >> 26 & 0x1)
    vert := 3 + quad
    cmd_buf.length = (vert * (tex + 1)) + ((vert - 1) * shad) + 1

    tri_func := tex | (shad << 1)
    switch tri_func {
    case 0:
        cmd_buf.function = gpu_tri_1
    case 1:
        cmd_buf.function = gpu_tri_2
    case 2:
        cmd_buf.function = gpu_tri_3
    case 3:
        cmd_buf.function = gpu_tri_4
    }
}

@(private="file")
gpu_img_transfer :: proc(data: u32) {
    cmd_buf.pointer += 1

    if cmd_buf.length == cmd_buf.pointer {
        cmd_buf.pointer = 0
        cmd_buf.img_mode = false
    }

    vram[((img_data.j + img_data.dest_y) * 1024) + img_data.dest_x + img_data.i] = u16(data)
    vram[((img_data.j + img_data.dest_y) * 1024) + img_data.dest_x + img_data.i + 1] = u16(data >> 16)
    img_data.i += 2
    if img_data.i >= img_data.width {
        img_data.i = 0
        img_data.j += 1
        if img_data.j >= img_data.height {
            img_data.j = 0
        }
    }
}

@(private="file")
gpu_gp1 :: proc(command: u32) {
    cmd := command >> 24
    value := command & 0xFFFFFF
    switch cmd {
    case 0x00:
        gpu_1_00()
    case 0x01:
        gpu_1_01(value)
    case 0x02:
        gpu_1_02(value)
    case 0x03:
        gpu_1_03(value)
    case 0x04:
        gpu_1_04(value)
    case 0x05:
        gpu_1_05(value)
    case 0x06:
        gpu_1_06(value)
    case 0x07:
        gpu_1_07(value)
    case 0x08:
        gpu_1_08(value)
    case 0x10:
        gpu_1_10(value)
    case:
        fmt.printf("gp1 write: 0x%x\n", command)
        panic("")
    }
}

@(private="file")
gpu_read_read :: proc() -> u32 {
    return gpu_read_value
}

@(private="file")
gpu_read_stat :: proc() -> u32 {
    rv := gpustat
    rv.rtrcw = 1
    rv.rtsvtc = 1
    rv.rtrdb = 1
    return u32(rv)
}

@(private="file")
gpu_get_hor_res :: proc(h: Hor_res) -> i32 {
    switch h {
    case .n256:
        return 256
    case .n320:
        return 320
    case .n512:
        return 512
    case .n640:
        return 640
    case .n368:
        return 368
    }
    return 512
}

@(private="file")
gpu_get_color24 :: proc(value: u32) -> u32 {
    return (value & 0xFFFFFF)
}

@(private="file")
gpu_get_size :: proc(value: u32) -> Vector2u {
    x := value & 0xFFFF
    y := (value >> 16) & 0xFFFF
    return {x, y}
}

@(private="file")
gpu_get_vertex :: proc(value: u32) -> Vertex {
    x := i32(value & 0xFFFF)
    y := i32((value >> 16) & 0xFFFF)
    return {x, y, 0, {0, 0}}
}

@(private="file")
gpu_get_clut :: proc(value: u32) -> Vector2u {
    x := ((value >> 16) & 0x3F) << 4
    y := (value >> 22) & 0x1FF
    return {x, y}
}

@(private="file")
gpu_get_page :: proc(value: u32) -> Vector2u {
    x := ((value >> 16) & 0xF) << 6
    y := ((value >> 16) & 0x10) << 4
    return {x, y}
}

@(private="file")
gpu_get_textcoord :: proc(value: u32) -> Vector2u {
    x := value & 0xFF
    y := (value >> 8) & 0xFF
    return {x, y}
}

gpu_get_winding :: proc(v1: Vertex, v2: Vertex, v3: Vertex) -> (Vertex, Vertex, Vertex) {
    a: Vertex = v1
    b: Vertex
    c: Vertex

    if((v2.x - a.x) * (v3.y - a.y) - (v2.y - a.y) * (v3.x - a.x) < 0) {
        b = v3
        c = v2
    } else {
        b = v2
        c = v3
    }
    return a, b, c
}

gpu_get_edge :: proc(a: Vertex, b: Vertex, c: Vertex) -> i32 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

@(private="file")
gpu_color_15torgb :: proc(color: u16) -> Vector3i {
    return {i32(color & 0x1F), i32((color >> 5) & 0x1F), i32((color >> 10) & 0x1F)}
}

@(private="file")
gpu_color_24torgb :: proc(color: u32) -> Vector3i {
    return {i32(color & 0xFF), i32((color >> 8) & 0xFF), i32((color >> 16) & 0xFF)}
}

gpu_calc_transparency :: proc(color: u16, x: u32, y: u32, transp: Transp_mode) -> u16 {
    back := vram[x + y * 1024]
    b := gpu_color_15torgb(back)
    f := gpu_color_15torgb(color)
    switch transp {
    case .Bd2pFd2:
        f.r = b.r / 2 + f.r / 2
        f.g = b.g / 2 + f.g / 2
        f.b = b.b / 2 + f.b / 2
    case .BpF:
        f.r = b.r + f.r
        f.g = b.g + f.g
        f.b = b.b + f.b
    case .BmF:
        f.r = b.r - f.r
        f.g = b.g - f.g
        f.b = b.b - f.b
    case .BpFd4:
        f.r = b.r + f.r / 4
        f.g = b.g + f.g / 4
        f.b = b.b + f.b / 4
    }
    f.r = clamp(f.r, 0, 31)
    f.g = clamp(f.g, 0, 31)
    f.b = clamp(f.b, 0, 31)
    return u16(f.r | (f.g << 5) | (f.b << 10))
}

@(private="file")
gpu_calc_blending :: proc(c1: u16, color: u16) -> u16 {
    a := gpu_color_15torgb(c1)
    b := gpu_color_15torgb(color)

    a.r = (b.r * a.r) / 16
    a.g = (b.g * a.g) / 16
    a.b = (b.b * a.b) / 16

    a.r = clamp(a.r, 0, 31)
    a.g = clamp(a.g, 0, 31)
    a.b = clamp(a.b, 0, 31)

    return u16(a.r | (a.g << 5) | (a.b << 10))
}

@(private="file")
gpu_line_gradient :: proc(color1: Vector3i, color2: Vector3i, gradient: f32) -> u32 {
    r := u32(f32(color1.r) * (1 - gradient) + f32(color2.r) * gradient)
    g := u32(f32(color1.g) * (1 - gradient) + f32(color2.g) * gradient)
    b := u32(f32(color1.b) * (1 - gradient) + f32(color2.b) * gradient)
    return u32(r | (g << 8) | (b << 16))
}

@(private="file")
gpu_get_texel :: proc(v1: Vector2u, clut: Vector2u, page: Vector2u) -> u16 {
    tx := v1.x & 0xFF
    ty := v1.y & 0xFF
    tx = (tx & (~tex_mask.x)) | (tex_offset.x & tex_mask.x)
    ty = (ty & (~tex_mask.y)) | (tex_offset.y & tex_mask.y)
    tex_depth := gpustat.texture_colors

    switch tex_depth {
    case Texture_colors.n4bit:
        texel := vram[(tx >> 2) + page.x + ((ty + page.y) * 1024)]
        index := (texel >> ((tx & 0x3) << 2)) & 0x0F
        return vram[clut.x + u32(index) + (clut.y * 1024)]
    case Texture_colors.n8bit:
        texel := vram[tx >> 1 + page.x + ((ty + page.y) * 1024)]
        index := (texel >> ((tx & 0x1) << 3)) & 0xFF
        return vram[clut.x + u32(index) + (clut.y * 1024)]
    case Texture_colors.n15bit:
        return vram[tx + page.x + ((ty + page.y) * 1024)]
    }
    return 0
}

@(private="file")
gpu_color_24to15 :: proc(color: u32) -> u16 {
    col := u16((color & 0xF8) >> 3)
    col |= u16((color & 0xF800) >> 6)
    col |= u16((color & 0xF80000) >> 9)
    return col
}

@(private="file")
gpu_vram_write :: proc(color24: u32, x: u32, y: u32, convert: bool) {
    if convert {
        color15 := gpu_color_24to15(color24)
        vram[(y * 1024) + x] = color15
    } else {
        vram[(y * 1024) + x] = u16(color24)
    }
}

//gp0 commands
@(private="file")
gpu_0_00 :: proc(value: u32) {
    //Do nothing, nop
}

@(private="file")
gpu_0_01 :: proc(value: u32) { //Clear Cache
    //TODO: Implement when we have texture cache
}

@(private="file")
gpu_0_02 :: proc(value: u32) { // Fill Rectangle in VRAM
    c1 := gpu_get_color24(cmd_buf.data[0])
    dest := gpu_get_size(cmd_buf.data[1])
    dest.x = dest.x & 0x3F0
    dest.y = dest.y & 0x1FF
    size := gpu_get_size(cmd_buf.data[2])
    size.x = ((size.x & 0x3FF) + 0x0F) & 0xFFFFFFF0
    size.y = size.y & 0x1FF

    dest.x = u32(i32(dest.x) + draw_offset.x)
    dest.y = u32(i32(dest.y) + draw_offset.y)

    xmin := max(dest.x, u32(draw_area.left))
    ymin := max(dest.y, u32(draw_area.top))
    xmax := min(dest.x + size.x, u32(draw_area.right))
    ymax := min(dest.y + size.y, u32(draw_area.bottom))

    for y :u32= ymin; y < ymax; y += 1 {
        for x :u32= xmin; x < xmax; x += 1 {
            gpu_vram_write(c1, x, y, true)
        }
    }
}

gpu_0_1F :: proc(value: u32) {
    gpustat.irq = true
}

@(private="file")
gpu_tri_1 :: proc(value: u32) {
    opt: Rend_opt
    opt.trans = (cmd_buf.data[0] >> 25 & 0x1)
    quad := (cmd_buf.data[0] >> 27 & 0x1)

    color := gpu_get_color24(cmd_buf.data[0])
    v1 := gpu_get_vertex(cmd_buf.data[1])
    v2 := gpu_get_vertex(cmd_buf.data[2])
    v3 := gpu_get_vertex(cmd_buf.data[3])

    gpu_tri_draw(v1, v2, v3, color, opt)
    if quad == 1 {
        v4 := gpu_get_vertex(cmd_buf.data[4])
        gpu_tri_draw(v2, v3, v4, color, opt)
    }
}

@(private="file")
gpu_tri_2 :: proc(value: u32) {
    opt: Rend_opt
    opt.tex = (cmd_buf.data[0] >> 26 & 0x1)
    opt.trans = (cmd_buf.data[0] >> 25 & 0x1)
    opt.raw = (cmd_buf.data[0] >> 24 & 0x1)
    quad := (cmd_buf.data[0] >> 27 & 0x1)

    color := gpu_get_color24(cmd_buf.data[0])
    v1 := gpu_get_vertex(cmd_buf.data[1])
    v1.tc = gpu_get_textcoord(cmd_buf.data[2])
    v2 := gpu_get_vertex(cmd_buf.data[3])
    v2.tc = gpu_get_textcoord(cmd_buf.data[4])
    v3 := gpu_get_vertex(cmd_buf.data[5])
    v3.tc = gpu_get_textcoord(cmd_buf.data[6])

    gpu_tri_draw(v1, v2, v3, color, opt)
    if quad == 1 {
        v4 := gpu_get_vertex(cmd_buf.data[7])
        v4.tc = gpu_get_textcoord(cmd_buf.data[8])
        gpu_tri_draw(v2, v3, v4, color, opt)
    }
}

@(private="file")
gpu_tri_3 :: proc(value: u32) {
    opt: Rend_opt
    opt.shad = (cmd_buf.data[0] >> 28 & 0x1)
    opt.trans = (cmd_buf.data[0] >> 25 & 0x1)
    quad := (cmd_buf.data[0] >> 27 & 0x1)

    color := gpu_get_color24(cmd_buf.data[0])
    v1 := gpu_get_vertex(cmd_buf.data[1])
    v1.c = color
    v2 := gpu_get_vertex(cmd_buf.data[3])
    v2.c = gpu_get_color24(cmd_buf.data[2])
    v3 := gpu_get_vertex(cmd_buf.data[5])
    v3.c = gpu_get_color24(cmd_buf.data[4])

    gpu_tri_draw(v1, v2, v3, color, opt)
    if quad == 1 {
        v4 := gpu_get_vertex(cmd_buf.data[7])
        v4.c = gpu_get_color24(cmd_buf.data[6])
        gpu_tri_draw(v2, v3, v4, color, opt)
    }
}

@(private="file")
gpu_tri_4 :: proc(value: u32) {
    opt: Rend_opt
    opt.shad = (cmd_buf.data[0] >> 28 & 0x1)
    opt.tex = (cmd_buf.data[0] >> 26 & 0x1)
    opt.trans = (cmd_buf.data[0] >> 25 & 0x1)
    quad := (cmd_buf.data[0] >> 27 & 0x1)

    color := gpu_get_color24(cmd_buf.data[0])
    v1 := gpu_get_vertex(cmd_buf.data[1])
    v1.c = color
    v1.tc = gpu_get_textcoord(cmd_buf.data[2])
    v2 := gpu_get_vertex(cmd_buf.data[4])
    v2.c = gpu_get_color24(cmd_buf.data[3])
    v2.tc = gpu_get_textcoord(cmd_buf.data[5])
    v3 := gpu_get_vertex(cmd_buf.data[7])
    v2.c = gpu_get_color24(cmd_buf.data[6])
    v3.tc = gpu_get_textcoord(cmd_buf.data[8])

    gpu_tri_draw(v1, v2, v3, color, opt)
    if quad == 1 {
        v4 := gpu_get_vertex(cmd_buf.data[10])
        v4.c = gpu_get_color24(cmd_buf.data[9])
        v4.tc = gpu_get_textcoord(cmd_buf.data[11])
        gpu_tri_draw(v2, v3, v4, color, opt)
    }
}

@(private="file")
gpu_tri_draw :: proc(v1: Vertex, v2: Vertex, v3: Vertex, c1: u32, opt: Rend_opt) {
    p: Vertex
    a, b, c := gpu_get_winding(v1, v2, v3)

    a.x += draw_offset.x
    a.y += draw_offset.y
    b.x += draw_offset.x
    b.y += draw_offset.y
    c.x += draw_offset.x
    c.y += draw_offset.y

    a.c = u32(gpu_color_24to15(a.c))
    b.c = u32(gpu_color_24to15(b.c))
    c.c = u32(gpu_color_24to15(c.c))

    xmin := max(min(a.x, b.x, c.x), i32(draw_area.left))
    ymin := max(min(a.y, b.y, c.y), i32(draw_area.top))
    xmax := min(max(a.x, b.x, c.x), i32(draw_area.right))
    ymax := min(max(a.y, b.y, c.y), i32(draw_area.bottom))

    area :=  gpu_get_edge(a, b, c)
    transp := gpustat.transparency

    clut: Vector2u
    page: Vector2u
    if opt.tex == 1 {
        if opt.shad == 1 {
            page = gpu_get_page(cmd_buf.data[5])
        } else {
            page = gpu_get_page(cmd_buf.data[4])
        }
        clut = gpu_get_clut(cmd_buf.data[2])
    }

    for p.y = ymin; p.y < ymax; p.y += 1 {
        for p.x = xmin; p.x < xmax; p.x += 1 {
            z0 := gpu_get_edge(b, c, p)
            z1 := gpu_get_edge(c, a, p)
            z2 := gpu_get_edge(a, b, p)

            if(z0 >= 0 && z1 >= 0 && z2 >= 0) {
                color := gpu_color_24to15(c1)
                if opt.shad == 1 {
                    r := (z0 * i32((a.c >> 0) & 0x1F) + z1 * i32((b.c >> 0) & 0x1F) + z2 * i32((c.c >> 0) & 0x1F)) / area
                    g := (z0 * i32((a.c >> 5) & 0x1F) + z1 * i32((b.c >> 5) & 0x1F) + z2 * i32((c.c >> 5) & 0x1F)) / area
                    b := (z0 * i32((a.c >> 10) & 0x1F) + z1 * i32((b.c >> 10) & 0x1F) + z2 * i32((c.c >> 10) & 0x1F)) / area
                    color = u16(r | (g << 5) | (b << 10))
                }
                if opt.tex == 1 {
                    tcx := (z0 * i32(a.tc.x) + z1 * i32(b.tc.x) + z2 * i32(c.tc.x)) / area
                    tcy := (z0 * i32(a.tc.y) + z1 * i32(b.tc.y) + z2 * i32(c.tc.y)) / area
                    texel := gpu_get_texel({u32(tcx), u32(tcy)}, clut, page)
                    if texel == 0 {
                        tcx += 1
                        continue
                    }
                    /*if opt.trans == 1 {
                        ptrans = (color & 0x8000) != 0
                    }*/
                    if opt.raw == 1 {
                        color = texel
                    } else {
                        color = gpu_calc_blending(texel, color)
                    }
                }
                if opt.trans == 1 {
                    color = gpu_calc_transparency(color, u32(p.x), u32(p.y), transp)
                }
                gpu_vram_write(u32(color), u32(p.x), u32(p.y), false)
            }
        }
    }
}

@(private="file")
gpu_rect :: proc(value: u32) {
    rect_size := (cmd_buf.data[0] >> 27) & 0x3
    tex := bool(cmd_buf.data[0] >> 26 & 0x1)
    trans := bool(cmd_buf.data[0] >> 25 & 0x1)
    raw := bool(cmd_buf.data[0] >> 24 & 0x1)

    c1 := gpu_get_color24(cmd_buf.data[0])
    pos := gpu_get_vertex(cmd_buf.data[1])

    size: Vector2u
    switch rect_size {
    case 0:
        if tex {
            size = gpu_get_size(cmd_buf.data[3])
        } else {
            size = gpu_get_size(cmd_buf.data[2])
        }
    case 1:
        size = {1, 1}
    case 2:
        size = {8, 8}
    case 3:
        size = {16, 16}
    }

    posx := u32(pos.x + draw_offset.x)
    posy := u32(pos.y + draw_offset.y)

    xmin := max(posx, u32(draw_area.left))
    ymin := max(posy, u32(draw_area.top))
    xmax := min(posx + size.x, u32(draw_area.right))
    ymax := min(posy + size.y, u32(draw_area.bottom))

    transp := gpustat.transparency
    clut: Vector2u
    page: Vector2u
    if tex {
        pos.tc = gpu_get_textcoord(cmd_buf.data[2])
        page = {u32(gpustat.texture_x), u32(gpustat.texture_y)}
        clut = gpu_get_clut(cmd_buf.data[2])
    }

    for y :u32 = ymin; y < ymax; y += 1 {
        for x :u32 = xmin; x < xmax; x += 1 {
            color:= gpu_color_24to15(c1)
            if tex {
                tex_x := x - xmin
                tex_y := y - ymin
                if texture_flip.x == 1 {
                    tex_x = xmax - x
                }
                if texture_flip.y == 1 {
                    tex_y = ymax - y
                }
                color = (gpu_get_texel({tex_x + pos.tc.x, tex_y + pos.tc.y}, clut, page))
                if color == 0 {
                    continue
                }
                if trans {
                    trans = (color & 0x8000) != 0
                }
                if !raw {
                    color = gpu_calc_blending(gpu_color_24to15(c1), color)
                }
            }
            if trans {
                color = gpu_calc_transparency(color, x, y, transp)
            }
            gpu_vram_write(u32(color), x, y, false)
        }
    }
}

@(private="file")
gpu_line :: proc(value: u32) {
    opt: Rend_opt
    opt.shad = (cmd_buf.data[0] >> 28 & 0x1)
    opt.poly = (cmd_buf.data[0] >> 27 & 0x1)
    opt.trans = (cmd_buf.data[0] >> 25 & 0x1)

    length := ((cmd_buf.length - opt.poly - (1 - opt.shad)) / (1 + opt.shad)) - 1
    c1 := gpu_get_color24(cmd_buf.data[0])
    v1: Vertex
    v2: Vertex

    for i :u32= 0; i < length; i += 1 {
        if opt.shad == 1 {
            v1 = gpu_get_vertex(cmd_buf.data[1 + i * 2])
            v1.c = gpu_get_color24(cmd_buf.data[0 + i * 2])
            v2 = gpu_get_vertex(cmd_buf.data[3 + i * 2])
            v2.c = gpu_get_color24(cmd_buf.data[2 + i * 2])
        } else {
            v1 = gpu_get_vertex(cmd_buf.data[1 + i])
            v1.c = c1
            v2 = gpu_get_vertex(cmd_buf.data[2 + i])
            v2.c = c1
        }

        if abs(v2.y - v1.y) < abs(v2.x - v1.x) {
            if v1.x > v2.x {
                gpu_line_low(v2, v1, opt)
            } else {
                gpu_line_low(v1, v2, opt)
            }
        } else {
            if v1.y > v2.y {
                gpu_line_high(v2, v1, opt)
            } else {
                gpu_line_high(v1, v2, opt)
            }
        }
    }
}

@(private="file")
gpu_line_low :: proc(v0: Vertex, v1: Vertex, opt: Rend_opt) {
    dx := v1.x - v0.x
    dy := v1.y - v0.y
    yi :i32= 1
    if dy < 0 {
        yi = -1
        dy = -dy
    }

    length: f32
    rgb1: Vector3i
    rgb2: Vector3i
    D := (dy << 1) - dx
    y := v0.y

    if opt.shad == 1 {
        length = f32(v1.x - v0.x)
        rgb1 = gpu_color_24torgb(v0.c)
        rgb2 = gpu_color_24torgb(v1.c)
    }

    for x :i32= v0.x; x <= v1.x; x += 1 {
        color: u32
        x0 := f32(x - v0.x)
        if opt.shad == 1 {
            color = gpu_line_gradient(rgb1, rgb2, x0 / length)
        } else {
            color = v0.c
        }
        
        gpu_vram_write(color, u32(x), u32(y), true)
        if D > 0 {
            y += yi
            D += ((dy - dx) << 1)
        } else {
            D += dy << 1
        }
    }
}

@(private="file")
gpu_line_high :: proc(v0: Vertex, v1: Vertex, opt: Rend_opt) {
    dx := v1.x - v0.x
    dy := v1.y - v0.y
    xi :i32= 1
    if dx < 0 {
        xi = -1
        dx = -dx
    }

    length: f32
    rgb1: Vector3i
    rgb2: Vector3i
    D := (dx << 1) - dy
    x := v0.x
    
    if opt.shad == 1 {
        length = f32(v1.y - v0.y)
        rgb1 = gpu_color_24torgb(v0.c)
        rgb2 = gpu_color_24torgb(v1.c)
    }

    for y :i32= v0.y; y <= v1.y; y += 1 {
        color: u32
        y0 := f32(y - v0.y)
        if opt.shad == 1 {
            color = gpu_line_gradient(rgb1, rgb2, y0 / length)
        } else {
            color = v0.c
        }

        gpu_vram_write(color, u32(x), u32(y), true)
        if D > 0 {
            x += xi
            D += ((dx - dy) << 1)
        } else {
            D += dx << 1
        }
    }
}

@(private="file")
gpu_0_80 :: proc(value: u32) { //Copy Rectangle (VRAM to VRAM)
    src := gpu_get_size(cmd_buf.data[1])
    src.x = src.x & 0x3FF
    src.y = src.y & 0x1FF
    dst := gpu_get_size(cmd_buf.data[2])
    dst.x = dst.x & 0x3FF
    dst.y = dst.y & 0x1FF
    size := gpu_get_size(cmd_buf.data[3])
    size.x = ((size.x - 1) & 0x3FF) + 1
    size.y = ((size.y - 1) & 0x1FF) + 1

    for y :u32= 0; y < size.y; y += 1 {
        for x :u32= 0; x < size.x; x += 1 {
            data := vram[((y + src.y) * 1024) + x + src.x]
            vram[((y + dst.y) * 1024) + x + dst.x] = data
        }
    }
}

@(private="file")
gpu_0_A0 :: proc(value: u32) { //Copy Rectangle (CPU to VRAM)
    dest := gpu_get_size(cmd_buf.data[1])
    img_data.dest_x = dest.x & 0x3FF
    img_data.dest_y = dest.y & 0x1FF
    xy := gpu_get_size(cmd_buf.data[2])
    img_data.width = ((xy.x - 1) & 0x3FF) + 1
    img_data.height = ((xy.y - 1) & 0x1FF) + 1
    size := (xy.x * xy.y)
    size = (size + 1) & ~u32(1)
    size = size / 2
    cmd_buf.length = size + 1
    cmd_buf.pointer = 1
    cmd_buf.img_mode = true
}

@(private="file")
gpu_0_C0 :: proc(value: u32) { //Copy Rectangle (VRAM to CPU)
    src := gpu_get_size(cmd_buf.data[1])
    src.x &= 0x3FF
    src.y &= 0x1FF
    xy := gpu_get_size(cmd_buf.data[2])
    xy.x = ((xy.x - 1) & 0x3FF) + 1
    xy.y = ((xy.y - 1) & 0x1FF) + 1
    size := (xy.x * xy.y)
    size = (size + 1) & ~u32(1)
    size = size / 2
    gpu_read_value = u32(vram[xy.x + xy.y * 1024])
    //TODO: Implement proper transfer?
}

@(private="file")
gpu_0_e1 :: proc(value: u32) { //Draw mode setting
    gpustat.texture_x = u16(value & 0xF) * 64
    gpustat.texture_y = u16((value >> 4) & 1) * 256
    gpustat.transparency = Transp_mode((value >> 5) & 3)
    gpustat.texture_colors = Texture_colors((value >> 7) & 3)
    gpustat.dither = bool((value >> 9) & 1)
    gpustat.draw_display = bool((value >> 10) & 1)
    gpustat.texture_disable = bool((value >> 11) & 1)
    texture_flip.x = (value >> 12) & 1
    texture_flip.y = (value >> 13) & 1
}

@(private="file")
gpu_0_e2 :: proc(value: u32) { //Texture Window setting
    tex_mask.x = (value & 0x1F) * 8
    tex_mask.y = ((value >> 5) & 0x1F) * 8
    tex_offset.x = ((value >> 10) & 0x1F) * 8
    tex_offset.y = ((value >> 15) & 0x1F) * 8
}

@(private="file")
gpu_0_e3 :: proc(value: u32) { //Set Drawing Area top/left
    draw_area.left = u16(value & 0x3FF)
    draw_area.top = u16((value >> 10) & 0x3FF)
}

@(private="file")
gpu_0_e4 :: proc(value: u32) { //Set Drawing Area bottom/right
    draw_area.right = u16(value & 0x3FF)
    draw_area.bottom = u16((value >> 10) & 0x3FF)
}

@(private="file")
gpu_0_e5 :: proc(value: u32) { //Set Drawing Offset
    x := u16(value & 0x7FF)
    y := u16((value >> 11) & 0x7FF)
    draw_offset.x = (i32(x << 5)) >> 5
    draw_offset.y = (i32(y << 5)) >> 5
}

@(private="file")
gpu_0_e6 :: proc(value: u32) { //Mask Bit Setting
    gpustat.set_mask = bool(value & 1)
    gpustat.draw_pixels = bool((value >> 1) & 1)
}

//gp1 commands
@(private="file")
gpu_1_00 :: proc() { //Soft reset
    gpustat.texture_x = 0
    gpustat.texture_y = 0
    gpustat.transparency = .Bd2pFd2
    gpustat.texture_colors = .n4bit
    gpustat.dither = false
    gpustat.draw_display = false
    gpustat.texture_disable = false
    gpustat.set_mask = false
    gpustat.draw_pixels = false
    gpustat.interlace = true
    gpustat.flip_screen = false
    gpustat.texture_disable = false
    gpustat.hor_res = .n256
    gpustat.vert_res = .n240
    gpustat.video_mode = .ntsc
    gpustat.color_depth = .n15
    gpustat.vert_interlace = false
    gpustat.disp_disable = true
    gpustat.irq = false
    gpustat.dma = 0
    gpustat.dma_dir = .off
    gpustat.draw_odd = false

    texture_flip.x = 0
    texture_flip.y = 0
    disp_start.x = 0
    disp_start.y = 0
    disp_range.x1 = 0x200
    disp_range.x2 = 0x200 + 256 * 10
    disp_range.y1 = 0x10
    disp_range.y2 = 0x10 + 240
    tex_mask.x = 0
    tex_mask.y = 0
    tex_offset.x = 0
    tex_offset.y = 0
    draw_area.top = 0
    draw_area.bottom = 0
    draw_area.left = 0
    draw_area.right = 0
    draw_offset.x = 0
    draw_offset.y = 0
    //TODO: Reset command buffer
}

@(private="file")
gpu_1_01 :: proc(value: u32) { //Reset Command Buffer
    //TODO: Properly implement when proper fifo
    cmd_buf.function = nil
    cmd_buf.length = 0
    cmd_buf.pointer = 0
    for _, i in cmd_buf.data {
        cmd_buf.data[i] = 0
    }
}

@(private="file")
gpu_1_02 :: proc(value: u32) { //Acknowledge GPU Interrupt
    gpustat.irq = false
}

@(private="file")
gpu_1_03 :: proc(value: u32) { //Display Enable
    gpustat.disp_disable = bool(value & 1)
}

@(private="file")
gpu_1_04 :: proc(value: u32) { //Dma direction
    gpustat.dma_dir = Dma_dir(value & 3)
}

@(private="file")
gpu_1_05 :: proc(value: u32) { //Start of Display area
    disp_start.x = value & 0x3FF
    disp_start.y = (value >> 10) & 0x1FF
}

@(private="file")
gpu_1_06 :: proc(value: u32) { //Horizontal Display range
    disp_range.x1 = u16(value & 0xFFF)
    disp_range.x2 = u16((value >> 12) & 0xFFF)
}

@(private="file")
gpu_1_07 :: proc(value: u32) { //Vertical Display range
    disp_range.y1 = u16(value & 0x3FF)
    disp_range.y2 = u16((value >> 10) & 0x3FF)
}

@(private="file")
gpu_1_08 :: proc(value: u32) { //Display mode
    hor_res := Hor_res((value & 3) | ((value >> 4) & 4))
    vert_res := Vert_res((value >> 2) & 1)
    color_depth := Color_depth((value >> 4) & 1)

    if gpustat.hor_res != hor_res || gpustat.vert_res != vert_res {
        width := gpu_get_hor_res(hor_res)
        height := (i32(vert_res) + 1) * 240
        when SHOW_FULL_VRAM {
            if color_depth == .n15 {
                width = 1024
            } else {
                width = 682
            }
            height = 512
        }
        update_window_size(width, height)
    }

    gpustat.hor_res = hor_res
    gpustat.vert_res = vert_res
    gpustat.video_mode = Video_mode((value >> 3) & 1)
    gpustat.color_depth = color_depth
    gpustat.vert_interlace = bool((value >> 5) & 1)
    gpustat.flip_screen = bool((value >> 7) & 1)
}

@(private="file")
gpu_1_10 :: proc(value: u32) { //Get GPU Info
    cmd := value & 0xF
    switch cmd {
    case 0x0:
        //NA
    case 0x1:
        //NA
    case 0x2:
        gpu_read_value = (tex_mask.x / 8) | ((tex_mask.y / 8) << 5) |
                            ((tex_offset.x / 8) << 10) | ((tex_offset.y / 8) << 15)
    case 0x3:
        gpu_read_value = u32(draw_area.left) | (u32(draw_area.top) << 10)
    case 0x4:
        gpu_read_value = u32(draw_area.right) | (u32(draw_area.bottom) << 10)
    case 0x5:
        gpu_read_value = u32(draw_offset.x) | (u32(draw_offset.y) << 11)
    case 0x6:
        //NA
    case 0x7:
        gpu_read_value = 2
    case 0x8:
        gpu_read_value = 0
    case 0x9..=0xF:
        //NA
    }
}
