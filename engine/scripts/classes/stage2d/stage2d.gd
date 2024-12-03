@tool
@icon("./icon.svg")
extends Node2D
class_name Stage2D





@export var disable_pause_menu: bool = false

var _is_stage_ready: bool
signal stage_ready


func _ready()->void :
    await get_tree().physics_frame
    while get_tree().is_paused():
        await get_tree().physics_frame
    for i in 5:
        await get_tree().physics_frame
    _is_stage_ready = true
    stage_ready.emit()



func restart()->void :
    Scenes.reload_current_scene()
