extends Control

var opened: bool = false
var skip_to_save: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: VBoxContainer = $VBoxContainer


func _ready()->void :
    animation_player.play(&"init")
    Scenes.custom_scenes.game_over = self
    Scenes.scene_ready.connect(func ():
        if !Thunder._current_hud: return 
        Thunder._current_hud.game_over_finished.connect(func ():
            if skip_to_save:
                var sgr_path = ProjectSettings.get_setting("application/thunder_settings/save_game_room_path")

                if SettingsManager.get_tweak("replace_circle_transitions_with_fades", false):
                    TransitionManager.accept_transition(
                        load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
                            .instantiate()
                            .with_scene(sgr_path)
                    )
                    return 

                TransitionManager.accept_transition(
                    load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
                        .instantiate()
                        .with_speeds(0.03, -0.1)
                        .with_pause()
                        .on_player_after_middle(true)
                )

                await TransitionManager.transition_middle
                Scenes.goto_scene(sgr_path)
            else:
                toggle()
        )
    )


func toggle(no_resume: bool = false)->void :
    while Scenes.custom_scenes.pause.opened:
        await get_tree().physics_frame
        if !Scenes.custom_scenes.pause._no_unpause:
            break
    opened = !opened

    if opened:
        v_box_container.move_selector(0)
        animation_player.play("open")


        SettingsManager.show_mouse()
    else:
        animation_player.play_backwards("open")
        Audio.stop_music_channel(99, false)
        SettingsManager.hide_mouse()

        Data.reset_all_values()
        Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)
        if !no_resume:
            Scenes.reload_current_scene()

    get_tree().paused = opened
    await get_tree().physics_frame
    v_box_container.focused = opened
