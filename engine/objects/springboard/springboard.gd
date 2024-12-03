extends GeneralMovementBody2D

@export var spring_jump_height: float = 975

@onready var enemy_attacked: Node = $Body / EnemyAttacked

@onready var animation_node: Node2D = $Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_better: bool
var is_playing_backwards: bool

func _ready()->void :
    animation_player.animation_finished.connect(_animation_finished)
    is_better = SettingsManager.get_tweak("better_springboards", true)


func trigger(pl = null)->void :
    sprite_node.play(&"default")
    sprite_node.frame = 0
    var current_player: Player = Thunder._current_player
    if is_instance_valid(current_player):
        current_player._has_jumped = true

    if animation_node.visible:
        animation_player.play(&"jump")


func _animation_finished(anim: String)->void :
    if !is_playing_backwards:
        animation_player.play(&"jump", -1, -2.0, true)
        is_playing_backwards = true
    else:
        is_playing_backwards = false


func _input(event: InputEvent)->void :
    if event.is_action_pressed("m_jump"):
        enemy_attacked.stomping_player_jumping_max = spring_jump_height
        if !is_better:
            await get_tree().create_timer(0.1).timeout
            enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min

    elif event.is_action_released("m_jump") && is_better:
        enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min
