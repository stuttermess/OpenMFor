extends StaticBody2D

@onready var _path_follow = $".."





func _player_landed(player: Player)->void :
    get_parent()._player_landed(player)

func _physics_process(_delta: float)->void :
    global_position = _path_follow.global_position

    if _path_follow.progress < 5:
        reset_physics_interpolation()
