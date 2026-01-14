package norseIsland

import "core:math"
import rl "vendor:raylib"

// --- Configuration Constants ---
// The "Canvas" size when the island is fully expanded
MAX_W :: 1280
MAX_H :: 720
// The minimum collapsed island
MIN_W :: 250
MIN_H :: 150

DynamicIsland :: struct {
	x:               f32,
	y:               f32,
	width:           f32,
	height:          f32,
	target_width:    f32,
	target_height:   f32,
	corner_radius:   f32,
	is_hovered:      bool,
	animation_speed: f32,
}

WindowManager :: struct {
	monitor_w:    i32,
	monitor_h:    i32,
	current_w:    i32,
	current_h:    i32,
	is_expanded:  bool,
	screen_y_pos: i32,
}

island_new :: proc() -> DynamicIsland {
	return DynamicIsland {
		x = MIN_W / 2,
		y = 10,
		width = 150,
		height = 70,
		target_width = 150,
		target_height = 70,
		corner_radius = 35,
		is_hovered = false,
		animation_speed = 8.0,
	}
}

get_centered_window_x :: proc(mon_w: i32, win_w: i32) -> i32 {
	return (mon_w - win_w) / 2
}

island_update :: proc(island: ^DynamicIsland, wm: ^WindowManager) {
	mouse_pos := rl.GetMousePosition()

	hover_padding: f32 = 20
	is_hovering :=
		(mouse_pos.x >= island.x - island.width / 2 - hover_padding &&
			mouse_pos.x <= island.x + island.width / 2 + hover_padding &&
			mouse_pos.y >= island.y - hover_padding &&
			mouse_pos.y <= island.y + island.height + hover_padding)

	island.is_hovered = is_hovering

	if island.is_hovered {
		// Expand the island
		island.target_width = 600
		island.target_height = 400

		if !wm.is_expanded {
			wm.is_expanded = true
			wm.current_w = MAX_W
			wm.current_h = MAX_H

			rl.SetWindowSize(wm.current_w, wm.current_h)
			rl.SetWindowPosition(
				get_centered_window_x(wm.monitor_w, wm.current_w),
				wm.screen_y_pos,
			)
			island.x = MAX_W / 2
		}
	} else {
		// Collapse the island
		island.target_width = 150
		island.target_height = 70

		if wm.is_expanded && math.abs(island.width - 150.0) < 1.0 {
			wm.is_expanded = false
			wm.current_w = MIN_W
			wm.current_h = MIN_H

			rl.SetWindowSize(wm.current_w, wm.current_h)
			rl.SetWindowPosition(
				get_centered_window_x(wm.monitor_w, wm.current_w),
				wm.screen_y_pos,
			)

			island.x = MIN_W / 2
		}
	}

	dt := rl.GetFrameTime()
	island.width = math.lerp(island.width, island.target_width, island.animation_speed * dt)
	island.height = math.lerp(island.height, island.target_height, island.animation_speed * dt)
}

island_draw :: proc(island: DynamicIsland) {
	// Draw glow
	if island.is_hovered {
		glow_color := rl.Color{100, 150, 255, 50}
		draw_rounded_rect(
			island.x - island.width / 2 - 8,
			island.y - 8,
			island.width + 16,
			island.height + 16,
			island.corner_radius + 8,
			glow_color,
		)
	}

	// Draw body
	draw_rounded_rect(
		island.x - island.width / 2,
		island.y,
		island.width,
		island.height,
		island.corner_radius,
		rl.Color{30, 40, 90, 255},
	)

	// Draw content
	if island.is_hovered {
		rl.DrawText("Dynamic Island", i32(island.x - 100), i32(island.y + 40), 28, rl.WHITE)
		rl.DrawText("Hover to interact", i32(island.x - 90), i32(island.y + 100), 16, rl.LIGHTGRAY)
		rl.DrawText("Move away to collapse", i32(island.x - 110), i32(island.y + 140), 14, rl.GRAY)
	} else {
		// Simple dot when collapsed
		rl.DrawCircle(i32(island.x), i32(island.y + island.height / 2), 6, rl.WHITE)
	}
}

draw_rounded_rect :: proc(x: f32, y: f32, width: f32, height: f32, radius: f32, color: rl.Color) {
	r := math.min(radius, math.min(width / 2, height / 2))
	xi := i32(math.round(x))
	yi := i32(math.round(y))
	wi := i32(math.round(width))
	hi := i32(math.round(height))
	ri := math.round(r)
	rl.DrawRectangle(xi + i32(ri), yi, wi - i32(2 * ri), hi, color)
	rl.DrawRectangle(xi, yi + i32(ri), wi, hi - i32(2 * ri), color)
	rl.DrawCircle(xi + i32(ri), yi + i32(ri), ri, color)
	rl.DrawCircle(xi + wi - i32(ri), yi + i32(ri), ri, color)
	rl.DrawCircle(xi + i32(ri), yi + hi - i32(ri), ri, color)
	rl.DrawCircle(xi + wi - i32(ri), yi + hi - i32(ri), ri, color)
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_UNDECORATED, .WINDOW_TRANSPARENT, .WINDOW_TOPMOST, .WINDOW_HIDDEN})

	rl.InitWindow(MIN_W, MIN_H, "Dynamic Island")
	rl.SetWindowOpacity(0.99) // KDE Fix
	rl.SetTargetFPS(120)

	wm := WindowManager {
		monitor_w   = rl.GetMonitorWidth(0),
		monitor_h   = rl.GetMonitorHeight(0),
		current_w   = MIN_W,
		current_h   = MIN_H,
		is_expanded = false,
	}

	wm.screen_y_pos = i32(f32(wm.monitor_h) * 0.02)

	initial_x := get_centered_window_x(wm.monitor_w, MIN_W)
	rl.SetWindowPosition(initial_x, wm.screen_y_pos)

	island := island_new()
	rl.ClearWindowState({.WINDOW_HIDDEN})

	for !rl.WindowShouldClose() {
		island_update(&island, &wm)

		rl.BeginDrawing()
		rl.ClearBackground({0, 0, 0, 0})

		island_draw(island)

		rl.EndDrawing()

		if rl.IsKeyPressed(.ESCAPE) {
			break
		}
	}

	rl.CloseWindow()
}
