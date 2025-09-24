package main

import "core:fmt"
import sdl "vendor:sdl3"

Input_type :: enum {
    analog,
    digital,
    mouse,
    wheel,
}

input_1_lo: u8 = 0xFF
input_1_hi: u8 = 0xFF
input_2_lo: u8 = 0xFF
input_2_hi: u8 = 0xFF
input_3_lo: u8 = 0xFF
input_3_hi: u8 = 0xFF

input_process :: proc(event: ^sdl.Event) {
    switch CONTROLLER {
    case .digital:
        input_digital(event)
    case .analog:
        input_digital(event)
        input_analog(event)
    case .mouse:
        input_mouse(event)
    case .wheel:
        input_wheel(event)
    }
}

controller_create :: proc() -> ^sdl.Gamepad {
    controller: ^sdl.Gamepad
    count: i32
    ids := sdl.GetGamepads(&count)
    for i in 0 ..< count {
        if (sdl.IsGamepad(ids[i])) {
            controller = sdl.OpenGamepad(ids[i])
            if (controller != nil) {
                break
            }
        }
    }
    return controller
}

@(private="file")
input_digital :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.KEY_DOWN:
        switch event.key.key {
        case sdl.K_Z:     // Select
            input_1_lo &= 0xFE
        case sdl.K_X:     // Start
            input_1_lo &= 0xF7
        case sdl.K_UP:    // D-pad up
            input_1_lo &= 0xEF
        case sdl.K_RIGHT: // D-pad right
            input_1_lo &= 0xDF
        case sdl.K_DOWN:  // D-pad down
            input_1_lo &= 0xBF
        case sdl.K_LEFT:  // D-pad left
            input_1_lo &= 0x7F
        case sdl.K_Q:     // L2
            input_1_hi &= 0xFE
        case sdl.K_E:     // R2
            input_1_hi &= 0xFD
        case sdl.K_R:     // L1
            input_1_hi &= 0xFB
        case sdl.K_T:     // R1
            input_1_hi &= 0xF7
        case sdl.K_W:     // Triangle
            input_1_hi &= 0xEF
        case sdl.K_D:     // Circle
            input_1_hi &= 0xDF
        case sdl.K_S:     // X
            input_1_hi &= 0xBF
        case sdl.K_A:     // Square
            input_1_hi &= 0x7F
        }
    case sdl.EventType.GAMEPAD_BUTTON_DOWN:
        #partial switch sdl.GamepadButton(event.jbutton.button) {
        case sdl.GamepadButton.BACK:             // Select
            input_1_lo &= 0xFE
        case sdl.GamepadButton.LEFT_STICK:        // Left stick/L3
            input_1_lo &= 0xFD
        case sdl.GamepadButton.RIGHT_STICK:       // Right stick/R3
            input_1_lo &= 0xFB
        case sdl.GamepadButton.START:            // Start
            input_1_lo &= 0xF7
        case sdl.GamepadButton.DPAD_UP:          // D-pad up
            input_1_lo &= 0xEF
        case sdl.GamepadButton.DPAD_RIGHT:       // D-pad right
            input_1_lo &= 0xDF
        case sdl.GamepadButton.DPAD_DOWN:        // D-pad down
            input_1_lo &= 0xBF
        case sdl.GamepadButton.DPAD_LEFT:        // D-pad left
            input_1_lo &= 0x7F
        case sdl.GamepadButton.LEFT_SHOULDER:     // L1
            input_1_hi &= 0xFB
        case sdl.GamepadButton.RIGHT_SHOULDER:    // R1
            input_1_hi &= 0xF7
        case sdl.GamepadButton.NORTH:                // Triangle
            input_1_hi &= 0xEF
        case sdl.GamepadButton.EAST:                // Circle
            input_1_hi &= 0xDF
        case sdl.GamepadButton.SOUTH:                // X
            input_1_hi &= 0xBF
        case sdl.GamepadButton.WEST:                // Square
            input_1_hi &= 0x7F
        }
    case sdl.EventType.KEY_UP:
        switch event.key.key {
        case sdl.K_Z:     // Select
            input_1_lo |= 0x01
        case sdl.K_X:     // Start
            input_1_lo |= 0x08
        case sdl.K_UP:    // D-pad up
            input_1_lo |= 0x10
        case sdl.K_RIGHT: // D-pad right
            input_1_lo |= 0x20
        case sdl.K_DOWN:  // D-pad down
            input_1_lo |= 0x40
        case sdl.K_LEFT:  // D-pad left
            input_1_lo |= 0x80
        case sdl.K_Q:     // L2
            input_1_hi |= 0x01
        case sdl.K_E:     // R2
            input_1_hi |= 0x02
        case sdl.K_R:     // L1
            input_1_hi |= 0x04
        case sdl.K_T:     // R1
            input_1_hi |= 0x08
        case sdl.K_W:     // Triangle
            input_1_hi |= 0x10
        case sdl.K_D:     // Circle
            input_1_hi |= 0x20
        case sdl.K_S:     // X
            input_1_hi |= 0x40
        case sdl.K_A:     // Square
            input_1_hi |= 0x80
        }
    case sdl.EventType.GAMEPAD_BUTTON_UP:
        #partial switch sdl.GamepadButton(event.jbutton.button) {
        case sdl.GamepadButton.BACK:             // Select
            input_1_lo |= 0x01
        case sdl.GamepadButton.LEFT_STICK:        // Left stick/L3
            input_1_lo |= 0x02
        case sdl.GamepadButton.RIGHT_STICK:       // Right stick/R3
            input_1_lo |= 0x04
        case sdl.GamepadButton.START:            // Start
            input_1_lo |= 0x08
        case sdl.GamepadButton.DPAD_UP:          // D-pad up
            input_1_lo |= 0x10
        case sdl.GamepadButton.DPAD_RIGHT:       // D-pad right
            input_1_lo |= 0x20
        case sdl.GamepadButton.DPAD_DOWN:        // D-pad down
            input_1_lo |= 0x40
        case sdl.GamepadButton.DPAD_LEFT:        // D-pad left
            input_1_lo |= 0x80
        case sdl.GamepadButton.LEFT_SHOULDER:     // L1
            input_1_hi |= 0x04
        case sdl.GamepadButton.RIGHT_SHOULDER:    // R1
            input_1_hi |= 0x08
        case sdl.GamepadButton.NORTH:                // Triangle
            input_1_hi |= 0x10
        case sdl.GamepadButton.EAST:                // Circle
            input_1_hi |= 0x20
        case sdl.GamepadButton.SOUTH:                // X
            input_1_hi |= 0x40
        case sdl.GamepadButton.WEST:                // Square
            input_1_hi |= 0x80
        }
    }
}

@(private="file")
input_analog :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.GAMEPAD_AXIS_MOTION:
        #partial switch sdl.GamepadAxis(event.jbutton.button) {
        case sdl.GamepadAxis.LEFT_TRIGGER:
            if event.jaxis.value > 30000 {
                input_1_hi &= 0xFE
            } else {
                input_1_hi |= 0x01
            }
        case sdl.GamepadAxis.RIGHT_TRIGGER:
            if event.jaxis.value > 30000 {
                input_1_hi &= 0xFD
            } else {
                input_1_hi |= 0x02
            }
        case sdl.GamepadAxis.LEFTX:
            input_3_lo = u8(event.jaxis.value >> 8)
        case sdl.GamepadAxis.LEFTY:
            input_3_hi = u8(event.jaxis.value >> 8)
        case sdl.GamepadAxis.RIGHTX:
            input_2_lo = u8(event.jaxis.value >> 8)
        case sdl.GamepadAxis.RIGHTY:
            input_2_hi = u8(event.jaxis.value >> 8)
        }
    }
}

@(private="file")
input_mouse :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.MOUSE_BUTTON_UP:
        switch event.button.button {
        case 3:
            input_1_hi |= 0x04
        }
    case sdl.EventType.MOUSE_BUTTON_DOWN:
        switch event.button.button {
        case 1:
            input_1_hi |= 0x08
        }
    case sdl.EventType.MOUSE_MOTION:
        if event.motion.windowID == 1 {
            input_2_lo = u8(event.motion.xrel)
            input_2_hi = u8(event.motion.yrel)
        }
    }
}

@(private="file")
input_wheel :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    }
}
