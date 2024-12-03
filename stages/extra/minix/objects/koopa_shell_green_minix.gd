extends GeneralMovementBody2D

const Shell: Script = preload("./koopa_shell_green_minix.gd")

@export_category("KoopaShell")
@export var stopping: bool = true
@export var restoring_damage_delay: float = 0.6
@export_subgroup("Attack")
@export_range(0, 256) var sharpness: int
@export_group("Sound", "sound_")
@export var kicked_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/kick.wav")
@export var combo_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/kick.wav")

var _delayer: SceneTreeTimer

const COMBO_ARRAY: Array[int] = [100, 200, 500, 1000, 2000, 5000, 5000, 5000, 5000]

@onready var combo: Combo = Combo.new(self, 99, true, COMBO_ARRAY)

@onready var body: Area2D = $Body
@onready var enemy_attacked: Node = $Body / EnemyAttacked
@onready var animation: AnimatedSprite2D = get_node_or_null(sprite)
@onready var attack: ShapeCast2D = $Attack

@onready var init_speed: float = speed.x
@onready var attack_type: StringName = attack.killer_type

@onready var disappear_timer: Timer = $Timer
var tw: Tween = null


func _ready()->void :
    super ()

    _delayer = get_tree().create_timer(0.05, false)
    _delayer.timeout.connect(
        func ()->void :
            _delayer = null
    )

    attack.belongs_to = Data.PROJECTILE_BELONGS.PLAYER
    status_update()
    disappear_timer.timeout.connect(disappearing_shell)


func status_update()->void :
    update_dir()
    vel_set_x(0.0 if stopping else init_speed * - dir)
    body.solid = stopping
    body.turn_back = stopping
    attack.killer_type = &"" if stopping else attack_type

    if !stopping:
        animation.play()
        disappear_timer.stop()
        if tw && tw.is_valid():
            tw.stop()
            tw = null
            sprite_node.modulate.a = 1.0

        _delayer = get_tree().create_timer(restoring_damage_delay, false)
        await _delayer.timeout
        _delayer = null


        enemy_attacked.stomping_enabled = true
        enemy_attacked.stomping_hurtable = true

    else:
        animation.stop()
        animation.frame = 0
        disappear_timer.start()


        enemy_attacked.stomping_enabled = false
        enemy_attacked.stomping_hurtable = false
        combo.reset_combo()


func status_swap(to: bool)->void :
    stopping = to
    status_update()


func disappearing_shell()->void :
    tw = create_tween()
    tw.tween_property(sprite_node, "modulate:a", 0.0, 2.4)
    tw.tween_callback(queue_free)


func sound()->void :
    Audio.play_sound(kicked_sound, self)


func _on_killing(target_enemy_attacked: Node, result: Dictionary)->void :
    if target_enemy_attacked == enemy_attacked: return 

    if is_instance_of(target_enemy_attacked.owner, Shell) && !target_enemy_attacked.owner.stopping && sharpness <= target_enemy_attacked.killing_immune.shell_defence:


            enemy_attacked.set_meta(
                &"attacker_speed", target_enemy_attacked.owner.speed
            )
            enemy_attacked.got_killed(&"shell_forced")
            target_enemy_attacked.set_meta(&"attacker_speed", speed)
            target_enemy_attacked.got_killed(&"shell_forced")
            Thunder._current_camera.shock(0.1, Vector2.ONE * 2)

    elif result.result && sharpness >= target_enemy_attacked.killing_immune.shell_defence:
        var status_node = Scenes.current_scene.get_node("CanvasLayer/Status")
        if !combo.get_combo() <= 0:
            target_enemy_attacked.sound_pitch = 1 + min(combo.get_combo(), 7) * 0.135
        target_enemy_attacked.set_meta(&"attacker_speed", speed)
        target_enemy_attacked.got_killed(&"shell_forced", [&"no_score"])
        Thunder._current_camera.shock(0.08, Vector2.ONE * 3)
        combo.combo()
        status_node.status(combo.get_combo())
        if combo.get_combo() >= 10:
            combo.reset_combo()

    else:
        if &"speed" in target_enemy_attacked.owner:
            enemy_attacked.set_meta(
                &"attacker_speed", target_enemy_attacked.owner.speed
            )
        enemy_attacked.got_killed(&"shell_forced")


func _on_body_entered(player: Node2D)->void :
    if !stopping: return 
    if player != Thunder._current_player: return 
    if Thunder._current_player.warp > Player.Warp.NONE: return 
    if is_instance_valid(_delayer) || enemy_attacked.get_stomping_delayer(): return 
    status_swap(false)
    sound()


func _on_collided_wall()->void :
    for i in get_slide_collision_count():
        var j: KinematicCollision2D = get_slide_collision(i)
        if j.get_collider() is StaticBumpingBlock:
            if j.get_collider().has_method(&"got_bumped"):
                j.get_collider().got_bumped.call_deferred(self)
            elif j.get_collider().has_method(&"bricks_break"):
                j.get_collider().bricks_break.call_deferred()
    turn_x()
