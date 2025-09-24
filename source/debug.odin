package main

import "core:fmt"
import sdl "vendor:sdl3"
import sdlttf "vendor:sdl3/ttf"

DebugType :: enum {
    cpu,
    gpu,
    last,
}
@(private="file")
debug_type: DebugType

@(private="file")
renderer : ^sdl.Renderer
@(private="file")
font : ^sdlttf.Font

debug_init :: proc(renderera: ^sdl.Renderer) {
    font = sdlttf.OpenFont("SpaceMono-Regular.ttf", 18)
    renderer = renderera
}

debug_draw :: proc() {
    switch debug_type {
    case .cpu:
        debug_cpu_draw()
    case .gpu:
        debug_gpu_draw()
    case .last:
        //NA
    }
}

debug_switch :: proc() {
    tmp := u32(debug_type)
    tmp += 1
    debug_type = DebugType(tmp)
    if debug_type == .last {
        debug_type = .cpu
    }
    draw_debug_window()
}

debug_text :: proc(text: cstring, posX: f32, posY: f32) {
    surface := sdlttf.RenderText_Solid(font, text, len(text), {255, 255, 255, 255})
    texture := sdl.CreateTextureFromSurface(renderer, surface)

    texW : f32 = 0
    texH : f32 = 0
    sdl.GetTextureSize(texture, &texW, &texH)

    text_rect: sdl.FRect
    text_rect.x = posX
    text_rect.y = posY
    text_rect.w = texW
    text_rect.h = texH

    sdl.RenderTexture(renderer, texture, nil, &text_rect)
    sdl.DestroySurface(surface)
    sdl.DestroyTexture(texture)
}
