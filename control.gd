extends ColorRect

var holding := false
var last_pos :=Vector2i()
@onready var downloader: HTTPRequest = $Downloader
@onready var github: HTTPRequest = $GithubGetter

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

#[b]Downlaoding Parkour...[/b]\nRetrieving necessary packages...
#[b]Launching Parkour[/b]\nExecuting Parkour.exe
#[b]Downloading Parkour...[/b]\n0 / 123MB - 1MB/s
#[b]Downloading Parkour...[/b]\nPreparing...

func _on_play_pressed() -> void:
	$Anim.play("play")
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nRetrieving necessary packages..."
	github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
	var gh = await github.request_completed
	if gh[0] == 200:
		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nPreparing..."
		downloader.request(JSON.parse_string(gh[3].get_string_from_utf8().mirror))
		var dw = dow
