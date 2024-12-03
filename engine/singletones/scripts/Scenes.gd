extends Node







signal scene_reloaded


signal scene_changed(to: Node)


signal pre_scene_changed


signal scene_ready


signal scene_change_failed

const LOADING_SCREEN = preload("res://engine/components/loading_screen/loading_screen.tscn")


var _current_scene_buffer: PackedScene

var current_scene: Node

var previous_scene_name: StringName

var previous_scene_path: StringName

var custom_scenes: Dictionary = {}



func _ready()->void :
    current_scene = get_tree().current_scene
    get_tree().root.remove_child.call_deferred(current_scene)
    GlobalViewport.vp.add_child.call_deferred(current_scene)



func load_scene_deferred(scene: Node)->void :
    if !scene: return 
    previous_scene_name = current_scene.name
    previous_scene_path = current_scene.scene_file_path
    current_scene.free()
    current_scene = scene
    GlobalViewport.vp.add_child(current_scene)
    scene_changed.emit(current_scene)
    scene_ready.emit()




func load_scene_from_packed(pck: PackedScene)->void :
    if !pck: return 
    if !pck.can_instantiate():
        scene_change_failed.emit()
        return 
    previous_scene_name = current_scene.name
    previous_scene_path = current_scene.scene_file_path
    current_scene.free()
    var scene: Node = pck.instantiate()

    current_scene = scene
    GlobalViewport.vp.add_child(current_scene)
    scene_changed.emit(current_scene)
    scene_ready.emit()
    get_tree().paused = false



func goto_scene(path: String)->void :
    pre_scene_changed.emit()
    if !_current_scene_buffer || _current_scene_buffer.resource_path != path:
        _current_scene_buffer = load(path)
    load_scene_from_packed.call_deferred(_current_scene_buffer)


func goto_scene_with_loading(path: String)->void :
    if _current_scene_buffer && _current_scene_buffer.resource_path == path:
        reload_current_scene()
        return 
    pre_scene_changed.emit()
    var loading: Control = LOADING_SCREEN.instantiate()
    loading.scene = path
    load_scene_deferred.call_deferred(loading)



func reload_current_scene()->void :
    scene_reloaded.emit()
    pre_scene_changed.emit()
    goto_scene(current_scene.scene_file_path)
