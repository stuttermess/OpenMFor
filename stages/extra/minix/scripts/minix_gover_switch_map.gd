extends MenuSelection

@onready var _is_simple_fade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)

func _handle_select(mouse_input: bool = false)->void :
    super (mouse_input)
    TransitionManager.transition_middle.connect(func ():
        TransitionManager.current_transition.paused = true
        Scenes.scene_changed.connect(func (_current_scene):
            TransitionManager.current_transition.paused = false
        , CONNECT_ONE_SHOT)
        Scenes.goto_scene("res://stages/extra/minix/minix.tscn")
        get_tree().set_deferred("paused", false)
    , CONNECT_ONE_SHOT)
    Pause.get_child(0).open_blocked = false
    Audio.stop_all_musics()
    Audio.stop_music_channel(2, true)
    SettingsManager.hide_mouse()
    _start_transition()


func _start_transition()->void :
    if !_is_simple_fade:
        TransitionManager.accept_transition(
            load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
                .instantiate()
                .with_speeds(0.02, -0.1)
        )
    else:
        Audio.stop_all_sounds()
        get_tree().paused = false
        TransitionManager.accept_transition(
            load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
                .instantiate()
                .with_scene("res://stages/extra/minix/minix.tscn")
        )
