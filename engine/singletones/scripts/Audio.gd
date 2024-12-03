extends Node











enum FadingMethod{
	LINEAR, 
	LERP, 
	SMOOTH_STEP
}


var _settings_sound_bus_volume_db: float = 0:
	set(to):
		_settings_sound_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("1D Sound"), _target_sound_bus_volume_db + to)


var _settings_music_bus_volume_db: float = 0:
	set(to):
		_settings_music_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _target_music_bus_volume_db + to)


var _target_sound_bus_volume_db: float = 0:
	set(to):
		_target_sound_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("1D Sound"), _settings_sound_bus_volume_db + to)



var _target_music_bus_volume_db: float = 0:
	set(to):
		_target_music_bus_volume_db = to
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _settings_music_bus_volume_db + to)

var _music_channels: Dictionary = {}
var _music_tweens: Array[Tween]
var _duplicated_sounds: Array[AudioStream]

var _calculate_player_position = _lcpp.bind()

signal any_music_finished


func _init()->void :
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready()->void :
	Scenes.pre_scene_changed.connect(_stop_all_musics_scene_changed)


func _physics_process(delta):
	if !_duplicated_sounds.is_empty():
		_duplicated_sounds.clear()


func _lcpp(ref: Node2D)->Vector2:
	return ref.global_position


func _create_2d_player(pos: Vector2, is_global: bool, is_permanent: bool = false)->AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	if !is_permanent: player.finished.connect(player.queue_free)
	player.global_position = pos
	GlobalViewport.add_child.call_deferred(player)
	return player


func _create_1d_player(is_global: bool, is_permanent: bool = false)->AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	if !is_permanent: player.finished.connect(player.queue_free)
	if !is_global: Scenes.pre_scene_changed.connect(player.queue_free)
	add_child.call_deferred(player)
	return player


func _create_openmpt_player(is_global: bool)->OpenMPT:
	var openmpt = OpenMPT.new()
	if !is_global: Scenes.pre_scene_changed.connect(openmpt.queue_free)
	add_child(openmpt)
	openmpt.stop()
	return openmpt








func play_sound(resource: AudioStream, ref: Node2D, is_global: bool = true, other_keys: Dictionary = {})->void :

	if resource == null: return 

	if _duplicated_sounds.has(resource): return 
	_duplicated_sounds.append(resource)
	var player = _create_2d_player(_calculate_player_position.call(ref), is_global)
	player.bus = "Sound" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
	player.stream = resource
	player.play.call_deferred()

	if &"pitch" in other_keys && other_keys.pitch is float:
		player.pitch_scale = other_keys.pitch
	if &"volume" in other_keys && other_keys.volume is float:
		player.volume_db = other_keys.volume


	player.volume_db += 5
	player.process_mode = Node.PROCESS_MODE_ALWAYS if &"ignore_pause" in other_keys && other_keys.ignore_pause else Node.PROCESS_MODE_PAUSABLE










func play_1d_sound(resource: AudioStream, is_global: bool = true, other_keys: Dictionary = {})->void :

	if resource == null: return 

	if _duplicated_sounds.has(resource): return 
	_duplicated_sounds.append(resource)
	var player = _create_1d_player(is_global)
	player.bus = "Sound" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
	player.stream = resource
	player.play.call_deferred()

	if &"pitch" in other_keys && other_keys.pitch is float:
		player.pitch_scale = other_keys.pitch
	if &"volume" in other_keys && other_keys.volume is float:
		player.volume_db = other_keys.volume
	player.process_mode = Node.PROCESS_MODE_ALWAYS if &"ignore_pause" in other_keys && other_keys.ignore_pause else Node.PROCESS_MODE_PAUSABLE




















func play_music(resource: Resource, channel_id: int, other_keys: Dictionary = {}, is_global: bool = false, is_permanent: bool = true)->AudioStreamPlayer:
	await get_tree().physics_frame
	if !resource: return null

	if !_music_channels.has(channel_id) || !is_instance_valid(_music_channels[channel_id]):
		_music_channels[channel_id] = _create_1d_player(is_global, is_permanent)
	var music_player = _music_channels[channel_id]

	music_player.finished.connect(func (): any_music_finished.emit(), CONNECT_ONE_SHOT)

	var openmpt: OpenMPT = null

	if ClassDB.get_parent_class(resource.get_class()) == &"AudioStream":
		music_player.stream = resource
		music_player.bus = &"Music" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
		music_player.play.call_deferred()
	elif &"data" in resource:
		openmpt = _create_openmpt_player(is_global)
		if !openmpt:
			return null

		openmpt.load_module_data(resource.data)
		if !openmpt.is_module_loaded():
			printerr("[Audio] Failed to load file using tracker loader")
			openmpt.queue_free()
			music_player.queue_free()
			return null
		music_player.set_meta(&"openmpt", openmpt)

		var generator = AudioStreamGenerator.new()
		generator.buffer_length = 0.04
		generator.mix_rate = 44100

		music_player.stream = generator
		music_player.bus = &"Music" if !(&"bus" in other_keys && other_keys.bus) else other_keys.bus
		(func ()->void :
			music_player.play()

			openmpt.set_audio_generator_playback(music_player)
			openmpt.set_render_interpolation(resource.interpolation)
			openmpt.set_repeat_count(0 if !resource.loop else -1)

			openmpt.start(true)

		).call_deferred()
	else:
		printerr("Invalid data provided in method Audio.play_music")
		return null

	if &"pitch" in other_keys && other_keys.pitch is float:
		_music_channels[channel_id].pitch_scale = other_keys.pitch
	if &"volume" in other_keys && other_keys.volume is float:
		_music_channels[channel_id].volume_db = other_keys.volume
	if &"fade_duration" in other_keys && other_keys.fade_duration is float:
		if &"fade_to" in other_keys && other_keys.fade_to is float:
			fade_music_1d_player(_music_channels[channel_id], other_keys.fade_to, other_keys.fade_duration)
	_music_channels[channel_id].process_mode = Node.PROCESS_MODE_ALWAYS if &"ignore_pause" in other_keys && other_keys.ignore_pause else Node.PROCESS_MODE_PAUSABLE


	if &"start_from_sec" in other_keys && other_keys.start_from_sec is float && other_keys.start_from_sec > 0.0:
		if openmpt:
			openmpt.set_position_seconds.call_deferred(other_keys.start_from_sec)
		else:
			_music_channels[channel_id].seek.call_deferred(other_keys.start_from_sec)

	return music_player if is_instance_valid(music_player) else null







func fade_music_1d_player(player: AudioStreamPlayer, to: float, duration: float, method: Tween.TransitionType = Tween.TRANS_LINEAR, stop_after_fading: bool = false, _ease: Tween.EaseType = Tween.EASE_IN)->void :
	if !player: return 
	if !is_instance_valid(player): return 

	var tween: Tween = create_tween().set_trans(method).set_ease(_ease)
	tween.tween_property(player, "volume_db", to, duration)
	tween.tween_callback(
		func ()->void :
			if stop_after_fading && is_instance_valid(player):
				player.stop()
				if player.has_meta("openmpt"):
					var openmpt = player.get_meta("openmpt")
					if is_instance_valid(openmpt):
						openmpt.queue_free()
				player.free()
			tween.kill()
			if tween in _music_tweens:
				_music_tweens.erase(tween)
	)
	_music_tweens.append(tween)



func stop_music_channel(channel_id: int, fade: bool)->void :
	if !channel_id in _music_channels: return 
	if !_music_channels[channel_id]: return 
	if !fade:
		_music_channels[channel_id].stop()
		if _music_channels[channel_id].has_meta("openmpt"):
			var openmpt = _music_channels[channel_id].get_meta("openmpt")
			if is_instance_valid(openmpt):
				openmpt.queue_free()
	else:
		fade_music_1d_player(_music_channels[channel_id], -40, 2, Tween.TRANS_SINE, true)



func stop_all_musics(fade: bool = false)->void :
	for i in _music_channels.keys():
		if !is_instance_valid(_music_channels[i]):
			continue
		if !fade:
			if _music_channels[i].has_meta("openmpt"):
				var openmpt = _music_channels[i].get_meta("openmpt")
				if is_instance_valid(openmpt):
					openmpt.queue_free()

			_music_channels[i].queue_free()
			_music_channels.erase(i)
		else:
			fade_music_1d_player(_music_channels[i], -40, 1.5, Tween.TRANS_LINEAR, true)

func _stop_all_musics_scene_changed()->void :
	for i in _music_channels.keys():
		if !is_instance_valid(_music_channels[i]) || !_music_channels[i].get_meta(&"play_when_scene_changed", true):
			continue
		if _music_channels[i].has_meta("openmpt"):
			var openmpt = _music_channels[i].get_meta("openmpt")
			if is_instance_valid(openmpt):
				openmpt.queue_free()
		if &"OpenMPT" in _music_channels[i].name:
			i.queue_free()

		_music_channels[i].queue_free()
		_music_channels.erase(i)


func stop_all_sounds()->void :
	for i in GlobalViewport.get_children():
		if i is AudioStreamPlayer2D || i is AudioStreamPlayer:
			i.stop()
			i.queue_free()
