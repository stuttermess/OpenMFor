extends Node2D

@export var goto_scene: String
@export var world_name: String

var skippable: bool = false

func _ready()->void :
    if !ProfileManager.current_profile.has_completed_world(world_name):
        ProfileManager.current_profile.data.current_world = goto_scene
        ProfileManager.current_profile.complete_world(world_name)
        ProfileManager.save_current_profile()
    await get_tree().create_timer(1.0, true, false, true).timeout
    skippable = true

func _physics_process(delta: float)->void :
    if !skippable: return 
    if Input.is_action_just_pressed("m_jump") || Input.is_action_just_pressed("ui_accept"):
        skippable = false
        TransitionManager.accept_transition(
            load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
                .instantiate()
                .with_speeds(0.01, -0.1)
        )

        TransitionManager.transition_middle.connect(func ():
            TransitionManager.current_transition.paused = true
            Scenes.goto_scene(goto_scene)
            Scenes.scene_changed.connect(func (_current_scene):
                TransitionManager.current_transition.paused = false
            , CONNECT_ONE_SHOT)
        , CONNECT_ONE_SHOT)
