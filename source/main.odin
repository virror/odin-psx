package main

import "core:fmt"
import "core:strings"
import "core:os"
import sdl "vendor:sdl3"
import sdlttf "vendor:sdl3/ttf"
import sdlimg "vendor:sdl3/image"

SHOW_FULL_VRAM :: true
ENABLE_TTY :: true
TTY_FILE :: false
ENABLE_SIDELOAD :: false
SIDELOAD_PATH :: "tests/psxtest_cpu.exe"
DISK_PATH :: ""
CONTROLLER :: Input_type.digital

Vector2f :: distinct [2]f32
Vector2u :: distinct [2]u32
Vector2i :: distinct [2]i32
Vector3f :: distinct [3]f32
Vector3u :: distinct [3]u32
Vector3i :: distinct [3]i32

WIN_WIDTH :: 1024
WIN_HEIGHT :: 512

@(private="file")
exit := false
pause := true
@(private="file")
step := false
@(private="file")
window: ^sdl.Window
@(private="file")
ttyfile: os.Handle
@(private="file")
debug_render: ^sdl.Renderer

main :: proc() {
    if(!sdl.Init(sdl.INIT_VIDEO | sdl.INIT_GAMEPAD)) {
        panic("Failed to init SDL3!")
    }
    defer sdl.Quit()

    if(!sdlttf.Init()) {
        panic("Failed to init SDL3 ttf!")
    }
    defer sdlttf.Quit()

    window = sdl.CreateWindow("psx emu", WIN_WIDTH, WIN_HEIGHT,
        sdl.WINDOW_OPENGL)
    assert(window != nil, "Failed to create main window")
    defer sdl.DestroyWindow(window)
    sdl.SetWindowPosition(window, 100, 100)

    debug_window: ^sdl.Window
    sdl.CreateWindowAndRenderer("debug", 600, 600, sdl.WINDOW_OPENGL, &debug_window, &debug_render)
    assert(debug_window != nil, "Failed to create debug window")
    defer sdl.DestroyWindow(debug_window)
    defer sdl.DestroyRenderer(debug_render)
    sdl.SetWindowPosition(debug_window, 800, 100)

    icon := sdlimg.Load("PSX_logo.png")
    defer sdl.DestroySurface(icon)
    sdl.SetWindowIcon(window, icon)

    controller := controller_create()
    defer sdl.CloseGamepad(controller)

    render_init(window)
    ticks: u64

    //Emu stuff
    debug_init(debug_render)
    bus_init()
    cpu_init()
    dma_init()
    gpu_init()
    cd_init()
    tmr_init()
    phr_init()

    when ENABLE_TTY && TTY_FILE {
        err: os.Errno
        ttyfile, err = os.open("ttylog.ans", os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
        assert(err == nil, "Failed to create ttylog file")
    }

    draw_debug_window()
    render_screen()

    for !exit {
        ticks_to_run := evt_check()
        ticks = 0
        for (ticks < ticks_to_run) {
            if !pause || step {
                tick := cpu_step()
                tmr_update_all(tick)
                ticks += tick
                evt_total_ticks += tick

                if step {
                    step = false
                    draw_debug_window()
                    free_all(context.temp_allocator)
                }
                if evt_evaluate {
                    ticks_to_run = evt_reevaluate()
                    ticks = 0
                }
            } else {
                handle_events()
            }
        }
    }

    when ENABLE_TTY && TTY_FILE {
        os.close(ttyfile)
    }
    render_delete()
}

draw_debug_window :: proc() {
    sdl.RenderClear(debug_render)
    debug_draw()
    sdl.RenderPresent(debug_render)
}

update :: proc() {
    render_screen()
    handle_events()
}

update_window_size :: proc(width: i32, height: i32) {
    sdl.SetWindowSize(window, width, height)
    update_viewport(width, height)
}

update_window_title :: proc(title: string) {
    strs := [?]string {"psx emu - ", title}
    str := strings.clone_to_cstring(strings.concatenate(strs[:]))
    sdl.SetWindowTitle(window, str)
}

pause_emu :: proc() {
    pause = !pause
    if(pause) {
        draw_debug_window()
    }
}

@(private="file")
handle_events :: proc() {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case sdl.EventType.QUIT:
            exit = true
        case sdl.EventType.WINDOW_CLOSE_REQUESTED:
            exit = true
        case:
            input_process(&event)
            handle_dbg_keys(&event)
        }
    }
}

@(private="file")
handle_dbg_keys :: proc(event: ^sdl.Event) {
    if event.type == sdl.EventType.KEY_DOWN {
        switch event.key.key {
        case sdl.K_P:
            pause_emu()
        case sdl.K_S:
            step = true
        case sdl.K_ESCAPE:
            exit = true
        case sdl.K_TAB:
            debug_switch()
        }
    }
}

print_tty :: proc() {
    if (next_pc & 0x3FFFFFFF) == 0x000000B4 {
        switch cpu_reg_get(9) {
        case 0x3D, 0x3B:
            when TTY_FILE {
                os.write_byte(ttyfile, u8(cpu_reg_get(4)))
            } else {
                fmt.print(rune(cpu_reg_get(4)))
            }
        }
    }
}
