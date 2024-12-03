extends "res://engine/objects/players/deaths/player_death.gd"

func _transition_circle()->void :

    TransitionManager.accept_transition(
    load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
        .instantiate()
        .with_speeds(circle_closing_speed, - circle_opening_speed)
        .with_pause()
    )

    var marker = _create_marker()
    TransitionManager.current_transition.on(marker)
    await TransitionManager.transition_middle

    if jump_to_scene.is_empty():
        Scenes.reload_current_scene()
    else:
        Scenes.goto_scene(jump_to_scene)
        get_tree().paused = false
