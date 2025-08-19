extends ColorRect

var holding := false
var last_pos := Vector2i()
@onready var downloader: HTTPRequest = $Downloader
@onready var github: HTTPRequest = $GithubGetter
var downloading := false
var last_bytes := 0
var updating := false
var current_bytes := 0
var Dsize_bytes := 0  # size in bytes now
signal terminated
var last_time := 0.0
var speed := 0.0 # MB/s decimal
var eta:="-"
func _on_sensor_button_down() -> void:
	holding = true
	last_pos = get_local_mouse_position()

func _on_sensor_button_up() -> void:
	holding = false

func _process(delta: float) -> void:
	if holding:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - last_pos)
	
	if downloading or updating:
		var now_time = Time.get_ticks_msec() / 1000.0
		current_bytes = downloader.get_downloaded_bytes()

		if now_time - last_time >= 1.0:
			var delta_bytes = current_bytes - last_bytes
			speed = delta_bytes / (now_time - last_time) / 1_000_000.0 # MB/s decimal
			last_time = now_time
			last_bytes = current_bytes

		# ETA calculation
		var remaining_bytes = Dsize_bytes - current_bytes
		if speed > 0.01:
			var seconds_remaining = int(remaining_bytes / (speed * 1_000_000.0))
			if seconds_remaining < 60:
				eta = "%dsec" % seconds_remaining
			else:
				eta = "%dmin" % int(seconds_remaining / 60)
		else:
			eta = "-"


		var downloaded_mb = snapped(current_bytes / 1_000_000.0, 0.1)
		var total_mb = snapped(Dsize_bytes / 1_000_000.0, 0.1)
		var speed_str = "%.1f" % speed

		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\n%s / %sMB - %sMB/s\n  ETA: %s" % [downloaded_mb, total_mb, speed_str, eta] if downloading else "[b]Updating Parkour...[/b]\n%s / %sMB - %sMB/s\n  ETA: %s" % [downloaded_mb, total_mb, speed_str, eta]
		$LOWER/Bar.value = calcPercentage(downloaded_mb, total_mb)


func _on_x_pressed() -> void:
	get_tree().quit()

func _on__pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_play_pressed() -> void:
	$LOWER/Retry.text = "RETRY"
	$LOWER/Bar.show_percentage=true
	if !$LOWER/Text.text == "[b]Launching Parkour...[/b]\nChecking for updates failed.":
		$Anim.play("play")
	if !FileAccess.file_exists(ProjectSettings.globalize_path("user://Parkour.exe")):
		$LOWER/Retry.hide()
		$LOWER/Loading.show()
		$LOWER/Bar.show()
		downloader.download_file = ProjectSettings.globalize_path("user://Parkour.exe")
		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nRetrieving necessary data..."
		github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
		var gh = await github.request_completed
		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nPreparing..."
		var dat = JSON.parse_string(gh[3].get_string_from_utf8())
		if dat != null:
			downloader.request(dat.mirror)
			Dsize_bytes = dat.size  # now in bytes
			downloading = true
		else:
			$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nDownload failed..."
			$LOWER/Retry.show()
			$LOWER/Loading.hide()
	else:
		$LOWER/Text.text = "[b]Launching Parkour...[/b]\nChecking for updates..."
		var check = await latest_version()
		if check is String: return
		if check:
			$LOWER/Bar.value = 100
			check()
			$LOWER/Text.text = "[b]Launching Parkour...[/b]\nCalculating bytes..."
			github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
			var gh = await github.request_completed
			var dat = JSON.parse_string(gh[3].get_string_from_utf8())
			await get_tree().create_timer(0.5).timeout
			if FileAccess.get_file_as_bytes(ProjectSettings.globalize_path("user://Parkour.exe")).size() >= dat.size - 100000:
				$LOWER/Text.text = "[b]Launching Parkour...[/b]\nRunning Parkour.exe..."
				OS.shell_open(ProjectSettings.globalize_path("user://Parkour.exe"))
				await get_tree().create_timer(1.5).timeout
				if is_process_running("Parkour"):
					$LOWER/Retry.show()
					$LOWER/Retry.text = "EXIT"
					$LOWER/Loading.hide()
					$LOWER/Text.text = "[b]Parkour Running...[/b]\nGame running..."
					$LOWER/Bar.show_percentage=false
					await terminated
					$Anim.play_backwards("play")
				else:
					_on_retry_pressed()
			else:
				if dat != null:
					downloader.request(dat.mirror)
					Dsize_bytes = dat.size  # now in bytes
					downloading = true
				else:
					$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nDownload failed..."
					$LOWER/Retry.show()
					$LOWER/Loading.hide()
		else:
			$LOWER/Retry.hide()
			$LOWER/Loading.show()
			$LOWER/Bar.show()
			downloader.download_file = ProjectSettings.globalize_path("user://Parkour.exe")
			$LOWER/Text.text = "[b]Updating Parkour...[/b]\nRetrieving necessary data..."
			github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
			var gh = await github.request_completed
			$LOWER/Text.text = "[b]Updating Parkour...[/b]\nPreparing..."
			var dat = JSON.parse_string(gh[3].get_string_from_utf8())
			if dat != null:
				downloader.request(dat.mirror)
				Dsize_bytes = dat.size  # now in bytes
				updating = true
			else:
				$LOWER/Text.text = "[b]Updating Parkour...[/b]\nUpdate failed..."
				$LOWER/Retry.show()
				$LOWER/Loading.hide()
func calcPercentage(partialValue, totalValue) -> float:
	return float(partialValue / totalValue) * 100.0

func _on_downloader_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == OK:
		print("done: ", result)
		copy_from_res("res://discord_game_sdk_x86.dll", "user://discord_game_sdk_x86.dll")
		copy_from_res("res://discord_game_sdk.dll", "user://discord_game_sdk.dll")
		copy_from_res("res://discord_game_sdk_binding.dll", "user://discord_game_sdk_binding.dll")
		copy_from_res("res://discord_game_sdk_binding_debug.dll", "user://discord_game_sdk_binding_debug.dll")
		var file = FileAccess.open("user://version.vfile",FileAccess.WRITE)
		github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/latest-version.json")
		var dat = await github.request_completed
		var dat3 = JSON.parse_string(dat[3].get_string_from_utf8())
		file.store_var(dat3.version)
		$LOWER/Retry.hide()
		$LOWER/Loading.show()
		$Anim.play_backwards("play")
		_ready()
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
	updating = false
func _on_retry_pressed() -> void:
	if $LOWER/Text.text == "[b]Launching Parkour...[/b]\nChecking for updates failed.":
		_on_play_pressed()
	if is_process_running("Parkour"):
		$LOWER/Loading.show()
		$LOWER/Retry.hide()
		$LOWER/Text.text = "[b]Quitting Parkour...[/b]\nKilling Parkour.exe"
		await get_tree().create_timer(0.5).timeout
		OS.kill(get_pid("Parkour"))
		await get_tree().create_timer(1.5).timeout
		if is_process_running("Parkour"):
			_on_retry_pressed()
			return
		$Anim.play_backwards("play")
		$LOWER/Text.text = "[b]Terminated Parkour.[/b]\nSession terminated"
		return
	$LOWER/Retry.text = "RETRY"
	$LOWER/Bar.show_percentage=true
	$LOWER/Retry.hide()
	$LOWER/Loading.show()
	$LOWER/Bar.show()
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nRetrieving necessary data..."

	github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/mirror")
	var gh = await github.request_completed
	$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nPreparing..."

	var dat = JSON.parse_string(gh[3].get_string_from_utf8())
	if dat != null:
		downloader.request(dat.mirror)
		Dsize_bytes = dat.size  # now in bytes
		downloading = true
	else:
		$LOWER/Text.text = "[b]Downloading Parkour...[/b]\nDownload failed..."
		$LOWER/Retry.show()
		$LOWER/Loading.hide()
func is_process_running(process_name: String) -> bool:
	return get_pid(process_name) != 0
func get_pid(process_name: String) -> int:
	if OS.get_name() != "Windows":
		return 0
	var output = []
	OS.execute(
		"powershell.exe",
		["Get-Process -Name %s | Select-Object -ExpandProperty Id" % process_name],
		output,
	)
	if output.size() > 0:
		var count = output[0].to_int()
		return count
	return 0
func _ready() -> void:
	if FileAccess.file_exists(ProjectSettings.globalize_path("user://Parkour.exe")):
		$Play.text = "Launch\nParkour"
	downloader.download_file = ProjectSettings.globalize_path("user://Parkour.exe")
static func copy_from_res(from: String, to: String, chmod_flags: int=-1) -> void:
	var file_from = FileAccess.open(from, FileAccess.READ)
	var file_to = FileAccess.open(to, FileAccess.WRITE)
	file_to.store_buffer(file_from.get_buffer(file_from.get_length()))
	file_to = null
	file_from = null
	if chmod_flags != -1:
		var output = []
		OS.execute("chmod", [chmod_flags, ProjectSettings.globalize_path(to)], output, true)
func check():
	if $LOWER/Text.text == "[b]Parkour Running...[/b]\nGame running...":
		if !is_process_running("Parkour"):
			terminated.emit()
			$LOWER/Text.text = "[b]Parkour Running...[/b]\nGame stopped..."
	await get_tree().create_timer(7.5).timeout
	check()
func latest_version():
	if FileAccess.file_exists("user://version.vfile"):
		github.request("https://raw.githubusercontent.com/brb-fr/Parkour-Updates/refs/heads/main/latest-version.json")
		var dat = await github.request_completed
		var dat3 = JSON.parse_string(dat[3].get_string_from_utf8())
		var file = FileAccess.open("user://version.vfile",FileAccess.READ)
		if dat3 != null:
			if dat3.version <= file.get_var():
				return true
		else:
			$LOWER/Text.text = "[b]Launching Parkour...[/b]\nChecking for updates failed."
			$LOWER/Retry.show()
			$LOWER/Loading.hide()
			return ""
	return false
