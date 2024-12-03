extends Control
class_name MenuSelection



var focused: bool = false

var mouse_hovered: bool = false

@export var selected_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_enter.wav")

@export var trigger_action: StringName = "ui_accept"

@export var trigger_mouse: bool = true


func _handle_focused(focus: bool)->void :
    focused = focus


func _handle_select(mouse_input: bool = false)->void :
    if selected_sound:
        Audio.play_1d_sound(selected_sound, true, {"ignore_pause": true, "bus": "1D Sound"})


func _physics_process(delta: float)->void :
    if !focused || !get_parent().focused: return 

    if Input.is_action_just_pressed(trigger_action):
        _handle_select(false)
