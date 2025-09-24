package main

import "core:fmt"

Event :: struct {
    time: u64,
    function: proc(),
    index: u64,
}

@(private="file")
events: map[u64]Event
@(private="file")
event_index: u64
evt_total_ticks: u64
evt_evaluate: bool = false

evt_check :: proc() -> u64 {
    for _, v in events {
        if evt_total_ticks >= v.time {
            v.function()
            evt_remove(v)
        }
    }
    return evt_reevaluate()
}

evt_reevaluate :: proc() -> u64 {
    min_val := u64(0xFFFFFFFFFFFFFFFF)
    for _, v in events {
        min_val = min(min_val, v.time - evt_total_ticks)
    }
    evt_evaluate = false
    return min_val
}

evt_add :: proc(time: u64, function: proc()) {
    evt: Event
    evt.time = time + evt_total_ticks
    evt.function = function
    evt.index = event_index
    events[event_index] = evt
    event_index += 1
    evt_evaluate = true
}

@(private="file")
evt_remove :: proc(event: Event) {
    delete_key(&events, event.index)
}