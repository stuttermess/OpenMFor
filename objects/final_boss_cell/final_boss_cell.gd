extends Node2D

const RED_MUSHROOM = preload("res://engine/objects/powerups/red_mushroom/red_mushroom.tscn")
const FIRE_FLOWER = preload("res://engine/objects/powerups/fire_flower/fire_flower.tscn")
const JUMP = preload("res://engine/objects/players/prefabs/sounds/jump.wav")
const BREAK = preload("res://engine/objects/bumping_blocks/_sounds/break.wav")
const FINAL_BOSS_CELL_PALOCHKA = preload("res://objects/final_boss_cell/final_boss_cell_palochka.tscn")

@onready var cell = $Cell
@onready var marker_2d = $Marker2D
@onready var cell_peach = $CellPeach
@onready var marker_mario_destroyer_pos = $MarkerMarioDestroyerPos
@onready var world = $World
@onready var animation_player = $AnimationPlayer

@onready var mario = Thunder._current_player

var amount_counter = 0

var _player_speed: float = 0.0
var _moving: bool = false
var _run_away: bool = false


func _ready()->void :
    await get_tree().create_timer(2, false).timeout

    _creation_mushroom()
    _creation_flower()


func _creation_mushroom()->void :
    await get_tree().create_timer(1, false).timeout

    if !is_instance_valid(mario) || mario.completed: return 

    _creation_mushroom()

    var hasMushroom = false

    for i in Scenes.current_scene.get_children():
        if i.name.begins_with("RedMushroom"):
            hasMushroom = true

    var hasFlower = false

    for i in Scenes.current_scene.get_children():
        if i.name.begins_with("FireFlower"):
            hasFlower = true

    if !hasMushroom && !hasFlower && Thunder._current_player_state.type == PlayerSuit.Type.SMALL && amount_counter < 4:
        cell_peach.animation = "throw"

        var mushroom = RED_MUSHROOM.instantiate()
        mushroom.global_position = marker_2d.global_position
        mushroom.speed.x = 0
        mushroom.appear_distance = 0

        Scenes.current_scene.add_child(mushroom)

        amount_counter += 1
        await get_tree().create_timer(1, false).timeout
        cell_peach.animation = "default"


func _creation_flower()->void :
    await get_tree().create_timer(5, false).timeout

    if !is_instance_valid(mario) || mario.completed: return 

    _creation_flower()

    var hasFlower = false

    for i in Scenes.current_scene.get_children():
        if i.name.begins_with("FireFlower"):
            hasFlower = true

    if !hasFlower && Thunder._current_player_state.type == PlayerSuit.Type.SUPER && amount_counter < 4:
        cell_peach.animation = "throw"

        var flower = FIRE_FLOWER.instantiate()
        flower.global_position = marker_2d.global_position
        flower.speed.x = 0
        flower.appear_distance = 0

        Scenes.current_scene.add_child(flower)

        amount_counter += 1
        await get_tree().create_timer(1, false).timeout
        cell_peach.animation = "default"


func cutscene()->void :
    if !is_instance_valid(mario):
        printerr("SHIT HAPPENED IN CUTSCENE!")
        return 

    mario.completed = true

    await get_tree().create_timer(1, false).timeout

    animation_player.pause()
    _fade_help()

    if mario.global_position.x > marker_mario_destroyer_pos.global_position.x:
        mario.direction = -1
    elif mario.global_position.x < marker_mario_destroyer_pos.global_position.x:
        mario.direction = 1

    var tw = create_tween()
    tw.tween_property(self, "global_position:y", 364, 4)
    await tw.finished



    _moving = true


func _fade_help()->void :
    var tw = create_tween()
    tw.tween_property(world, "modulate:a", 0, 0.5)


func _physics_process(delta: float)->void :
    if _run_away:
        _player_speed = move_toward(_player_speed, 325, delta * 250)
        cell_peach.speed.x = move_toward(cell_peach.speed.x, 325, delta * 250)
        mario.speed.x = _player_speed

    if !_moving: return 


    if mario.global_position.x > marker_mario_destroyer_pos.global_position.x + 156:
        _player_speed = move_toward(_player_speed, -325, delta * 250)
        mario.direction = -1
    elif mario.global_position.x < marker_mario_destroyer_pos.global_position.x - 156:
        _player_speed = move_toward(_player_speed, 325, delta * 250)
        mario.direction = 1
    elif mario.global_position.x > marker_mario_destroyer_pos.global_position.x + 16:
        _player_speed = move_toward(_player_speed, -125, delta * 250)
        mario.direction = -1
    elif mario.global_position.x < marker_mario_destroyer_pos.global_position.x - 16:
        _player_speed = move_toward(_player_speed, 125, delta * 250)
        mario.direction = 1
    else:
        _player_speed = 0
        _moving = false
        await get_tree().create_timer(0.2, false).timeout
        mario.direction = 1
        await get_tree().create_timer(0.5, false).timeout
        Audio.play_sound(JUMP, mario)
        Audio.play_sound(BREAK, mario)

        _particles()
        cell.visible = false
        mario.jump(-800)

        await get_tree().create_timer(0.4, false).timeout
        cell_peach.z_index = 5
        await get_tree().create_timer(0.4, false).timeout

        _run_away = true
        cell_peach.play("walk")

        await get_tree().create_timer(2, false).timeout

        Scenes.current_scene.throw_to_scene()

    mario.speed.x = _player_speed

func _particles()->void :
    for i in range(10):
        var particle = FINAL_BOSS_CELL_PALOCHKA.instantiate()
        particle.global_position = marker_mario_destroyer_pos.global_position - Vector2(0, 32)
        particle.speed = Vector2(randi_range(-200, -100), randi_range(-400, -100))

        Scenes.current_scene.add_child(particle)
