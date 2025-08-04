extends ColorRect

var holding := false
var last_pos := Vector2i()
@onready var downloader: HTTPRequest = $Downloader
@onready var github: HTTPRequest = $GithubGetter

var downloading := false
var last_bytes := 0
var current_bytes := 0
var Dsize := 123.0

var last_time := 0.0
var speed := 0.0

func _on_sensor_button_down() -> void:
	holding = true
	last_pos = get_local_mouse_position()

func _on_sensor_button_up() -> void:
	holding = false

func _process(delta: float) -> void:
	if holding:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - last_pos)
	
	if downloading:
		var now_time = Time.get_ticks_msec() / 1000.0
		current_bytes = downloader.get_downloaded_bytes()
		
		# update speed every 0.25 seconds
		if now_time - last_time >= 1.5:
			var delta_bytes = current_bytes - last_bytes
			speed = delta_bytes / (now_time - last_time) / 1_000_000.0 # MB/s
			last_time = now_time
			last_bytes = current_bytes
		
		var downloaded_mb = snapped(current_bytes / 1_000_000.0, 0.1)
		var total_mb = snapped(Dsize / 1.048576, 0.1)
		var speed_str = "%.1f" % speed
		
		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\n%s / %sMB - %sMB/s" % [downloaded_mb, total_mb, speed_str]
		$LOWER/Bar.value = calcPercentage(downloaded_mb, total_mb)

func _on_x_pressed() -> void:
	get_tree().quit()

func _on__pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_play_pressed() -> void:
	$Anim.play("play")
	downloader.download_file = "user://Parkour.exeb"
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nRetrieving necessary data..."
	
	github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
	var gh = await github.request_completed
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nPreparing..."
	
	var dat = JSON.parse_string(gh[3].get_string_from_utf8())
	downloader.request(dat.mirror)
	Dsize = dat.size
	downloading = true

func calcPercentage(partialValue, totalValue) -> float:
	return float(partialValue / totalValue) * 100.0
