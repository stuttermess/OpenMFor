extends Node2D

@export var goto_scene: String = "res://stages/cutscenes/starting/starting2.tscn"

@onready var canvas_layer = $CanvasLayer

@onready var skip_layer = $CanvasLayer / ColorRect2
@onready var buziol_layer = $CanvasLayer / ColorRect
@onready var buziol_animation_player = $CanvasLayer / ColorRect / AnimationPlayer
@onready var transition_layer = $CanvasLayer / ColorRect3
@onready var originally_created_label = $CanvasLayer / ColorRect / Label5

@onready var music_loader = $MusicLoader

@onready var main_camera_path = $Path2D / PathFollow2D
@onready var clouds_bg = $ParallaxBackground
@onready var second_camera_path = $Path2D2 / PathFollow2D
@onready var second_camera = $Path2D2 / PathFollow2D / Camera2D

var _original_time_scale: float
var _skippable: bool
var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)

func _ready()->void :
    _flow_intros()
    await get_tree().create_timer(1.2, false).timeout
    _skippable = true

func _enter_tree()->void :
    print("[Cutscene] altered time scale from %s" % Engine.time_scale)
    _original_time_scale = Engine.time_scale
    Engine.time_scale = 1

func _restore()->void :
    print("[Cutscene] restored time scale %s" % _original_time_scale)
    Engine.time_scale = _original_time_scale

func _flow_intros()->void :


    canvas_layer.visible = false

    originally_created_label.size = Vector2(640, 128)














    music_loader.play_buffered()



    await get_tree().create_timer(5, false).timeout
    var tw = create_tween()
    tw.tween_property(main_camera_path, "speed", 300, 1.8)

    await get_tree().create_timer(32, false).timeout

    clouds_bg.fade_clouds = true
    var tw2 = create_tween()
    tw2.tween_property(main_camera_path, "speed", 1200, 1.8)

    await get_tree().create_timer(1.4, false).timeout
    main_camera_path.queue_free()
    second_camera.enabled = true
    second_camera.make_current()
    second_camera_path.speed = 1100

    await get_tree().create_timer(0.1, false).timeout
    var tw3 = create_tween()
    tw3.tween_property(second_camera_path, "speed", 60, 1.5)

    await get_tree().create_timer(35, false).timeout
    _fade_out()

func _unhandled_input(event: InputEvent):
    if !_skippable: return 
    if event is InputEventKey:
        _fade_out()

func _fade_out()->void :
    _skippable = false

    _restore()
    await get_tree().physics_frame

    if !_crossfade:
        TransitionManager.accept_transition(
            load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
                .instantiate()
                .with_speeds(0.04, -0.1)
                .with_pause()

        )

        await TransitionManager.transition_middle
        Scenes.goto_scene(goto_scene)
    else:
        TransitionManager.accept_transition(
            load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
                .instantiate()
                .with_scene(goto_scene)
        )
