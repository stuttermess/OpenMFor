extends GravityBody2D
class_name Player

signal suit_appeared
signal suit_changed(to: PlayerSuit)
signal swam
signal shot
signal threw
signal grab_init(node: Node2D)
signal grabbed(side_grabbed: bool)
signal invinciblized(dur: float)
signal starmaned(dur: float)
signal starman_attacked
signal damaged
signal died
signal died_with_body(dead_player_body: Node2D)

enum Warp{
	NONE, 
	IN, 
	OUT, 
}

enum WarpDir{
	LEFT, 
	RIGHT, 
	UP, 
	DOWN
}

@export_group("General")
@export var suit: PlayerSuit






























@export var circle_transition_on_self: bool = true
@export_group("Physics")
@export_enum("Left: -1", "Right: 1") var direction: int = 1:
	set(to):
		direction = to
		if !direction in [-1, 1]:
			direction = [-1, 1].pick_random()
@export_group("Death", "death_")
@export var death_body: PackedScene = preload("res://engine/objects/players/deaths/player_death.tscn")
@export var death_music_override: AudioStream
@export var death_music_ignore_pause: bool = false
@export var death_wait_time: float = 3.5
@export var death_check_for_lives: bool = true

@export_file("*.tscn", "*.scn") var death_jump_to_scene: String = ""
@export var death_stop_music: bool = true

var _physics_behavior: ByNodeScript
var _suit_behavior: ByNodeScript
var _animation_behavior: ByNodeScript
var _grab_behavior: ByNodeScript
var _extra_behavior: ByNodeScript

var holding_item: Node2D = null

var left_right: float
var up_down: float
var jumping: int
var jumped: bool
var running: bool
var attacked: bool
var attacking: bool
var slided: bool

@warning_ignore("unused_private_class_variable")
var _has_jumped: bool

var is_climbing: bool
var is_sliding: bool
var is_crouching: bool
var is_skidding: bool
var is_holding: bool
var is_underwater: bool
var is_underwater_out: bool

var has_stuck: bool
var is_sliding_accelerating: bool

var completed: bool

var debug_god: bool
var debug_fly: bool

var warp: Warp
var warp_dir: WarpDir
var no_movement: bool

var _force_suit: bool
var _suit_appear: bool
var _suit_tree_paused: bool

@warning_ignore("unused_private_class_variable")
@onready var _is_ready: bool = true

@onready var control: PlayerControl = PlayerControl.new()
@onready var starman_combo: Combo = Combo.new(self)
@onready var stomping_combo: Combo = Combo.new(self, 10, true, Combo.STOMP_COMBO_ARRAY)
@onready var _stomping_combo_enabled: bool = SettingsManager.get_tweak("stomping_combo", false)
@onready var _suit_pause_tweak: bool = SettingsManager.get_tweak("pause_on_suit_change", false)
@warning_ignore("unused_private_class_variable")
@onready var _skid_tweak = SettingsManager.get_tweak("player_skid_animation", false)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_recovery: RayCast2D = $CollisionRecovery
@onready var body: ShapeCast2D = $Body
@onready var head: ShapeCast2D = $Head
@onready var underwater: Node = $Underwater
@onready var timer_invincible: Timer = $Invincible
@onready var timer_starman: Timer = $Starman
@onready var attack: ShapeCast2D = $Attack
@onready var bubbler: Timer = $Underwater / Bubbler
@onready var stars: GPUParticles2D = $Sprite / Stars
@onready var skid: GPUParticles2D = $Sprite / Skid
@onready var skid_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/skid.wav")
@onready var death_sprite: Sprite2D = $SpriteDeath


func _ready()->void :

	if Scenes.current_scene is Stage2D && circle_transition_on_self:
		Scenes.current_scene.stage_ready.connect(func ():

			var cam: = Thunder._current_camera
			if is_instance_valid(cam):
				cam.force_update_scroll()




			var trans: = TransitionManager.current_transition
			if is_instance_valid(trans) && trans.has_method("on"):
				trans.on(self)
				trans.paused = false
		, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	elif is_instance_valid(TransitionManager.current_transition):
		Scenes.scene_ready.connect(func ():
			var trans: = TransitionManager.current_transition
			if is_instance_valid(trans) && trans.has_method("on"):
				trans.on(Vector2(0.5, 0.5))
				trans.paused = false
		)

	if !Thunder._current_player_state_path.is_empty():
		suit = load(Thunder._current_player_state_path)
	elif Thunder._current_player_state:
		suit = Thunder._current_player_state
	else:
		var small_suit: PlayerSuit = CharacterManager.get_suit("small")
		Thunder._current_player_state = small_suit
		suit = small_suit

	change_suit(suit, false, true)

	Thunder._current_player = self

	if !is_starman():
		sprite.material.set_shader_parameter(&"mixing", false)

	(func ():
		if Data.values.lives == -1 && death_check_for_lives:
			Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)
	).call_deferred()


var _starman_faded: bool

func _physics_process(delta: float)->void :
	if !Thunder._current_player_state:
		Thunder._current_player_state = suit
	if is_starman() && timer_starman.time_left > 0.0 && timer_starman.time_left < 1.5 && !_starman_faded:



			_starman_faded = true
			Audio.stop_music_channel(98, true)

	if _stomping_combo_enabled && stomping_combo.get_combo() > 0 && is_on_floor():
		stomping_combo.reset_combo()

func change_suit(to: PlayerSuit, appear: bool = true, forced: bool = false)->void :
	_force_suit = forced
	_suit_appear = appear

	if ( !to || (suit && suit.name == to.name)) && !_force_suit: return 
	suit = to.duplicate()

	if suit.animation_sprites:
		sprite.sprite_frames = SkinsManager.apply_player_skin(suit)

	_physics_behavior = null
	_suit_behavior = null
	_animation_behavior = null
	_extra_behavior = null

	if suit.physics_behavior:
		_physics_behavior = ByNodeScript.activate_script(suit.physics_behavior, self)
	if suit.grab_behavior:
		_grab_behavior = ByNodeScript.activate_script(suit.grab_behavior, self)
	if suit.behavior_script:
		_suit_behavior = ByNodeScript.activate_script(suit.behavior_script, self, {suit_resource = suit.behavior_resource})
	if suit.animation_behavior:
		_animation_behavior = ByNodeScript.activate_script(suit.animation_behavior, self)
	if suit.extra_behavior:
		_extra_behavior = ByNodeScript.activate_script(suit.extra_behavior, self, suit.extra_vars)
	if _suit_appear:
		_suit_appear = false
		suit_appeared.emit()

	if !to.resource_path.is_empty():
		Thunder._current_player_state_path = to.resource_path
	Thunder._current_player_state = suit
	suit_changed.emit(suit)

	if appear && _suit_pause_tweak:
		_suit_tree_paused = true
		get_tree().paused = true
		Scenes.custom_scenes.pause._no_unpause = true
		sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		await get_tree().create_timer(1.0, true, true).timeout
		sprite.process_mode = Node.PROCESS_MODE_INHERIT
		_suit_tree_paused = false
		get_tree().paused = false
		Scenes.custom_scenes.pause._no_unpause = false
	if !appear && sprite.animation in ["appear", "attack", "attack_air"]:
		sprite.animation = "default"

	_force_suit = false
	_suit_appear = false
	set_deferred("is_hurting", false)


func control_process()->void :
	left_right = Input.get_axis(control.left, control.right)
	up_down = Input.get_axis(control.up, control.down)
	jumping = int(Input.is_action_pressed(control.jump)) + int(Input.is_action_just_pressed(control.jump))

	jumped = Input.is_action_just_pressed(control.jump)
	running = Input.is_action_pressed(control.run)
	attacked = Input.is_action_just_pressed(control.attack)
	attacking = Input.is_action_pressed(control.attack)
	is_crouching = Input.is_action_pressed(control.down) && is_on_floor() && suit && suit.physics_crouchable && !is_sliding

	slided = Input.is_action_pressed(control.down) && is_on_floor() && abs(rad_to_deg(get_floor_normal().x)) > 39




func invincible(duration: float = 2)->void :
	timer_invincible.start(duration)
	invinciblized.emit(duration)


func starman(duration: float = 10)->void :
	invincible(duration)
	sprite.material.set_shader_parameter(&"mixing", true)
	attack.enabled = true
	timer_starman.start(duration)
	starmaned.emit(duration)
	stars.emitting = true


var is_hurting: bool = false
func hurt(tags: Dictionary = {})->void :
	if !suit || debug_god || is_hurting:
		return 
	if !tags.get(&"hurt_forced", false) && (is_invincible() || completed || warp > Warp.NONE):
		return 
	if warp != Warp.NONE: return 
	is_hurting = true

	if suit.gets_hurt_to:
		change_suit(suit.gets_hurt_to)
		invincible.call_deferred(tags.get(&"hurt_duration", 2))
		Audio.play_sound(suit.sound_hurt, self, false, {pitch = suit.sound_pitch, ignore_pause = true})
	else:
		die(tags)

	damaged.emit()


var is_dying: bool = false
func die(tags: Dictionary = {})->void :
	if warp != Warp.NONE: return 
	if debug_god: return 
	if is_dying: return 
	is_dying = true

	if death_stop_music:
		Audio.stop_all_musics()
	Audio.play_music(
		suit.sound_death if !death_music_override else death_music_override, 
		1 if death_stop_music else 2, 
		{pitch = suit.sound_pitch} if !death_music_ignore_pause && !_suit_pause_tweak else {
			pitch = suit.sound_pitch, 
			ignore_pause = true
		}
	)

	var _db: Node2D
	if death_body:
		_db = NodeCreator.prepare_2d(death_body, self).bind_global_transform().call_method(
			func (db: Node2D)->void :
				db.wait_time = death_wait_time
				db.check_for_lives = death_check_for_lives
				db.jump_to_scene = death_jump_to_scene
				if _suit_pause_tweak:
					Scenes.custom_scenes.pause.paused.connect(db.set_process_mode.bind(Node.PROCESS_MODE_INHERIT))
					Scenes.custom_scenes.pause.unpaused.connect(db.set_process_mode.bind(Node.PROCESS_MODE_ALWAYS))
				if death_sprite:
					var dsdup: Node2D = death_sprite.duplicate()
					var character_death_sprite = CharacterManager.get_misc_texture("death")
					if character_death_sprite:
						dsdup.texture = character_death_sprite
					db.add_child(dsdup)
					dsdup.visible = true
		).create_2d().get_node()

	if _suit_pause_tweak && _db:
		get_tree().paused = true
		_db.process_mode = Node.PROCESS_MODE_ALWAYS
		Scenes.custom_scenes.pause._no_unpause = true

	died.emit()
	died_with_body.emit(_db)
	queue_free()


func is_invincible()->bool:
	return !timer_invincible.is_stopped()


func is_starman()->bool:
	return !timer_starman.is_stopped()


func _on_starman_timeout()->void :
	starman_combo.reset_combo()
	sprite.material.set_shader_parameter(&"mixing", false)
	stars.emitting = false
	attack.enabled = is_sliding
	_starman_faded = false
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if mus_loader:
		if mus_loader.is_paused:
			mus_loader.play_immediately = true
			mus_loader.unpause_music()
		elif !mus_loader.buffer.is_empty():
			mus_loader.play_immediately = true
			mus_loader.play_buffered()
			print("Played buffered")


func _on_starman_killed(what: Node, result: Dictionary)->void :
	if what == self: return 

	if result.result:
		if !starman_combo.get_combo() <= 0:
			what.sound_pitch = 1 + starman_combo.get_combo() * 0.135

		starman_combo.combo()
		starman_attacked.emit()
