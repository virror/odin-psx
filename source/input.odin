package main

import "core:fmt"
import sdl "vendor:sdl2"

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

controller_create :: proc() -> ^sdl.GameController {
    controller: ^sdl.GameController
    for i in 0 ..< sdl.NumJoysticks() {
        if sdl.IsGameController(i) {
            controller = sdl.GameControllerOpen(i)
            if controller != nil {
                break
            }
        }
    }
    return controller
}

@(private="file")
input_digital :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.KEYDOWN:
        #partial switch event.key.keysym.sym {
        case sdl.Keycode.Z:     // Select
            input_1_lo &= 0xFE
        case sdl.Keycode.X:     // Start
            input_1_lo &= 0xF7
        case sdl.Keycode.UP:    // D-pad up
            input_1_lo &= 0xEF
        case sdl.Keycode.RIGHT: // D-pad right
            input_1_lo &= 0xDF
        case sdl.Keycode.DOWN:  // D-pad down
            input_1_lo &= 0xBF
        case sdl.Keycode.LEFT:  // D-pad left
            input_1_lo &= 0x7F
        case sdl.Keycode.Q:     // L2
            input_1_hi &= 0xFE
        case sdl.Keycode.E:     // R2
            input_1_hi &= 0xFD
        case sdl.Keycode.R:     // L1
            input_1_hi &= 0xFB
        case sdl.Keycode.T:     // R1
            input_1_hi &= 0xF7
        case sdl.Keycode.W:     // Triangle
            input_1_hi &= 0xEF
        case sdl.Keycode.D:     // Circle
            input_1_hi &= 0xDF
        case sdl.Keycode.S:     // X
            input_1_hi &= 0xBF
        case sdl.Keycode.A:     // Square
            input_1_hi &= 0x7F
        }
    case sdl.EventType.CONTROLLERBUTTONDOWN:
        #partial switch sdl.GameControllerButton(event.cbutton.button) {
        case sdl.GameControllerButton.BACK:             // Select
            input_1_lo &= 0xFE
        case sdl.GameControllerButton.LEFTSTICK:        // Left stick/L3
            input_1_lo &= 0xFD
        case sdl.GameControllerButton.RIGHTSTICK:       // Right stick/R3
            input_1_lo &= 0xFB
        case sdl.GameControllerButton.START:            // Start
            input_1_lo &= 0xF7
        case sdl.GameControllerButton.DPAD_UP:          // D-pad up
            input_1_lo &= 0xEF
        case sdl.GameControllerButton.DPAD_RIGHT:       // D-pad right
            input_1_lo &= 0xDF
        case sdl.GameControllerButton.DPAD_DOWN:        // D-pad down
            input_1_lo &= 0xBF
        case sdl.GameControllerButton.DPAD_LEFT:        // D-pad left
            input_1_lo &= 0x7F
        case sdl.GameControllerButton.LEFTSHOULDER:     // L1
            input_1_hi &= 0xFB
        case sdl.GameControllerButton.RIGHTSHOULDER:    // R1
            input_1_hi &= 0xF7
        case sdl.GameControllerButton.Y:                // Triangle
            input_1_hi &= 0xEF
        case sdl.GameControllerButton.B:                // Circle
            input_1_hi &= 0xDF
        case sdl.GameControllerButton.A:                // X
            input_1_hi &= 0xBF
        case sdl.GameControllerButton.X:                // Square
            input_1_hi &= 0x7F
        }
    case sdl.EventType.KEYUP:
        #partial switch event.key.keysym.sym {
        case sdl.Keycode.Z:     // Select
            input_1_lo |= 0x01
        case sdl.Keycode.X:     // Start
            input_1_lo |= 0x08
        case sdl.Keycode.UP:    // D-pad up
            input_1_lo |= 0x10
        case sdl.Keycode.RIGHT: // D-pad right
            input_1_lo |= 0x20
        case sdl.Keycode.DOWN:  // D-pad down
            input_1_lo |= 0x40
        case sdl.Keycode.LEFT:  // D-pad left
            input_1_lo |= 0x80
        case sdl.Keycode.Q:     // L2
            input_1_hi |= 0x01
        case sdl.Keycode.E:     // R2
            input_1_hi |= 0x02
        case sdl.Keycode.R:     // L1
            input_1_hi |= 0x04
        case sdl.Keycode.T:     // R1
            input_1_hi |= 0x08
        case sdl.Keycode.W:     // Triangle
            input_1_hi |= 0x10
        case sdl.Keycode.D:     // Circle
            input_1_hi |= 0x20
        case sdl.Keycode.S:     // X
            input_1_hi |= 0x40
        case sdl.Keycode.A:     // Square
            input_1_hi |= 0x80
        }
    case sdl.EventType.CONTROLLERBUTTONUP:
        #partial switch sdl.GameControllerButton(event.cbutton.button) {
        case sdl.GameControllerButton.BACK:             // Select
            input_1_lo |= 0x01
        case sdl.GameControllerButton.LEFTSTICK:        // Left stick/L3
            input_1_lo |= 0x02
        case sdl.GameControllerButton.RIGHTSTICK:       // Right stick/R3
            input_1_lo |= 0x04
        case sdl.GameControllerButton.START:            // Start
            input_1_lo |= 0x08
        case sdl.GameControllerButton.DPAD_UP:          // D-pad up
            input_1_lo |= 0x10
        case sdl.GameControllerButton.DPAD_RIGHT:       // D-pad right
            input_1_lo |= 0x20
        case sdl.GameControllerButton.DPAD_DOWN:        // D-pad down
            input_1_lo |= 0x40
        case sdl.GameControllerButton.DPAD_LEFT:        // D-pad left
            input_1_lo |= 0x80
        case sdl.GameControllerButton.LEFTSHOULDER:     // L1
            input_1_hi |= 0x04
        case sdl.GameControllerButton.RIGHTSHOULDER:    // R1
            input_1_hi |= 0x08
        case sdl.GameControllerButton.Y:                // Triangle
            input_1_hi |= 0x10
        case sdl.GameControllerButton.B:                // Circle
            input_1_hi |= 0x20
        case sdl.GameControllerButton.A:                // X
            input_1_hi |= 0x40
        case sdl.GameControllerButton.X:                // Square
            input_1_hi |= 0x80
        }
    }
}

@(private="file")
input_analog :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.CONTROLLERAXISMOTION:
        #partial switch sdl.GameControllerAxis(event.cbutton.button) {
        case sdl.GameControllerAxis.TRIGGERLEFT:
            if event.caxis.value > 30000 {
                input_1_hi &= 0xFE
            } else {
                input_1_hi |= 0x01
            }
        case sdl.GameControllerAxis.TRIGGERRIGHT:
            if event.caxis.value > 30000 {
                input_1_hi &= 0xFD
            } else {
                input_1_hi |= 0x02
            }
        case sdl.GameControllerAxis.LEFTX:
            input_3_lo = u8(event.caxis.value >> 8)
        case sdl.GameControllerAxis.LEFTY:
            input_3_hi = u8(event.caxis.value >> 8)
        case sdl.GameControllerAxis.RIGHTX:
            input_2_lo = u8(event.caxis.value >> 8)
        case sdl.GameControllerAxis.RIGHTY:
            input_2_hi = u8(event.caxis.value >> 8)
        }
    }
}

@(private="file")
input_mouse :: proc(event: ^sdl.Event) {
    #partial switch event.type {
    case sdl.EventType.MOUSEBUTTONUP:
        switch event.button.button {
        case 3:
            input_1_hi |= 0x04
        }
    case sdl.EventType.MOUSEBUTTONDOWN:
        switch event.button.button {
        case 1:
            input_1_hi |= 0x08
        }
    case sdl.EventType.MOUSEMOTION:
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
