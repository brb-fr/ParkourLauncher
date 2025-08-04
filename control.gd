extends ColorRect

var holding := false
var last_pos :=Vector2i()

func _on_sensor_button_down() -> void:
	holding = true
	last_pos = get_local_mouse_position()

func _on_sensor_button_up() -> void:
	holding = false
func _process(delta: float) -> void:
	if holding:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position()-last_pos)


func _on_x_pressed() -> void:
	get_tree().quit()


func _on__pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
