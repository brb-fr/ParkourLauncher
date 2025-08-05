extends ColorRect

var holding := false
var last_pos := Vector2i()
@onready var downloader: HTTPRequest = $Downloader
@onready var github: HTTPRequest = $GithubGetter

var downloading := false
var last_bytes := 0
var current_bytes := 0
var Dsize_bytes := 0  # size in bytes now

var last_time := 0.0
var speed := 0.0 # MB/s decimal

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

		if now_time - last_time >= 1.0:
			var delta_bytes = current_bytes - last_bytes
			speed = delta_bytes / (now_time - last_time) / 1_000_000.0 # MB/s decimal
			last_time = now_time
			last_bytes = current_bytes

		var downloaded_mb = snapped(current_bytes / 1_000_000.0, 0.1)
		var total_mb = snapped(Dsize_bytes / 1_000_000.0, 0.1)
		var speed_str = "%.1f" % speed

		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\n%s / %sMB - %sMB/s" % [downloaded_mb, total_mb, speed_str]
		$LOWER/Bar.value = calcPercentage(downloaded_mb, total_mb)

func _on_x_pressed() -> void:
	get_tree().quit()

func _on__pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_play_pressed() -> void:
	$LOWER/Retry.hide()
	$LOWER/Loading.show()
	$LOWER/Bar.show()
	$Anim.play("play")
	downloader.download_file = "user://Parkour.exe"
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nRetrieving necessary data..."

	github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
	var gh = await github.request_completed
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nPreparing..."

	var dat = JSON.parse_string(gh[3].get_string_from_utf8())
	downloader.request(dat.mirror)
	Dsize_bytes = dat.size  # now in bytes
	downloading = true

func calcPercentage(partialValue, totalValue) -> float:
	return float(partialValue / totalValue) * 100.0

func _on_downloader_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == OK:
		print("done: ", result)
	else:
		print(str("err: ", result))
		if result == 4:
			$LOWER/Text.text = "[b]Download Failed[/b]\nInternet disconnected."
		else:
			$LOWER/Text.text = "[b]Download Failed[/b]\nError code: %s." % str(result)
		$LOWER/Retry.show()
		$LOWER/Loading.hide()
		$LOWER/Bar.hide()
	downloading = false

func _on_retry_pressed() -> void:
	$LOWER/Retry.hide()
	$LOWER/Loading.show()
	$LOWER/Bar.show()
	downloader.download_file = "user://Parkour.exe"
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nRetrieving necessary data..."

	github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
	var gh = await github.request_completed
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nPreparing..."

	var dat = JSON.parse_string(gh[3].get_string_from_utf8())
	downloader.request(dat.mirror)
	Dsize_bytes = dat.size  # bytes
	downloading = true
func is_process_running(process_name: String) -> bool:
	if OS.get_name() != "Windows":
		return false
	var output = []
	OS.execute(
		"powershell.exe",
		["-NoProfile", "-NonInteractive", "-Command", "Get-Process -Name %s | Measure-Object | Select-Object -ExpandProperty Count" % process_name],
		output
	)
	if output.size() > 0:
		var count = output[0].to_int()
		return count > 0
	return false
func _ready() -> void:
	print(FileAccess.get_file_as_bytes("user://Parkour.exe").size())
