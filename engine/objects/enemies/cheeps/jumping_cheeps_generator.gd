extends Node

@export var cheep_scene: PackedScene = preload("res://engine/objects/enemies/cheeps/cheep_red_jumping.tscn")
@export var enabled: bool = true

@export_subgroup("Spawn rate")
@export var random_pool: int = 20
@export var random_equals: int = 10
@export var chance_every_sec: float = 0.1
@export_subgroup("Cheep spawn speed")
@export var speed_min: Vector2 = Vector2(-7 * 50, -8 * 50)
@export var speed_max: Vector2 = Vector2(-1 * 50, -5 * 50)

func _ready()->void :
    _time()

func _time()->void :
    await get_tree().create_timer(chance_every_sec, false).timeout
    _time()

    if !enabled: return 

    if randi_range(0, random_pool) == random_equals:
        Thunder.view.cam_border()
        var to_pos = Vector2(Thunder.view.border.end) + Vector2(randi_range(-100, 0), 0)

        var fishgoggles = cheep_scene.instantiate()
        fishgoggles.global_position = to_pos
        fishgoggles.reset_physics_interpolation()
        fishgoggles.speed.x = randi_range(speed_min.x, speed_max.x)
        fishgoggles.speed.y = randi_range(speed_min.y, speed_max.y)

        Scenes.current_scene.add_child(fishgoggles)

func enable()->void :
    enabled = true

func disable()->void :
    enabled = false
