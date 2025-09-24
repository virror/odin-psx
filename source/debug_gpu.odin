package main

import "core:fmt"

debug_gpu_draw :: proc() {
    debug_text(fmt.caprintf("Tex base page x: %i", gpustat.texture_x), 10, 10)
    debug_text(fmt.caprintf("Semi transparency: %i", gpustat.transparency), 10, 35)
    debug_text(fmt.caprintf("Tex base page y: %i", gpustat.texture_y), 300, 10)
    debug_text(fmt.caprintf("Tex color depth: %v", gpustat.texture_colors), 10, 60)
    debug_text(fmt.caprintf("Dither: %v", gpustat.dither), 300, 35)
    debug_text(fmt.caprintf("Draw to disp area: %v", gpustat.draw_display), 10, 85)
    debug_text(fmt.caprintf("Set mask when draw: %v", gpustat.set_mask), 300, 60)
    debug_text(fmt.caprintf("Draw pixels: %v", gpustat.draw_pixels), 10, 110)
    debug_text(fmt.caprintf("Interlaced field: %v", gpustat.interlace), 300, 85)
    debug_text(fmt.caprintf("Reverse flag: %v", gpustat.flip_screen), 10, 135)
    debug_text(fmt.caprintf("Texture disable: %v", gpustat.texture_disable), 300, 110)
    debug_text(fmt.caprintf("Video mode: %v", gpustat.video_mode), 10, 160)
    debug_text(fmt.caprintf("Horizontal res: %v", gpustat.hor_res), 300, 135)
    debug_text(fmt.caprintf("Vertical res: %v", gpustat.vert_res), 10, 185)
    debug_text(fmt.caprintf("Disp color depth: %v", gpustat.color_depth), 300, 160)
    debug_text(fmt.caprintf("Verical interlace: %v", gpustat.vert_interlace), 10, 210)
    debug_text(fmt.caprintf("Display disable: %v", gpustat.disp_disable), 300, 185)
    debug_text(fmt.caprintf("Interrupt req: %v", gpustat.irq), 10, 235)
    debug_text(fmt.caprintf("dma/data request: %i", gpustat.dma), 300, 210)
    debug_text(fmt.caprintf("Ready to recive cmd: ?"), 10, 260)
    debug_text(fmt.caprintf("Ready to send: ?"), 300, 235)
    debug_text(fmt.caprintf("Ready to recive dma: ?"), 10, 285)
    debug_text(fmt.caprintf("dma direction: %v", gpustat.dma_dir), 300, 260)
    debug_text(fmt.caprintf("Draw even/odd: %v", gpustat.draw_odd), 300, 285)
}