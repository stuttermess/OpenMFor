extends Control
class_name MenuItemsController



@export var focused: bool = true

@export var current_item_index: int = 0

@export var control_forward: StringName = "ui_down"

@export var control_backward: StringName = "ui_up"

@export var control_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_main.wav")

@export var mouse_input: bool = true

@export var trigger_selection_immediately: bool = true
@export_group("Previous Screen", "prev_screen")

@export var prev_screen_node_path: NodePath

@export var prev_screen_control_cancel: StringName = "ui_cancel"


signal selected(item_index: int, item_node: Control, immediate: bool, mouse_input: bool)

var selectors: Array

func _ready()->void :
    _update_selectors()
    SettingsManager.mouse_pressed.connect(_on_mouse_pressed)
    SettingsManager.mouse_moved.connect(_on_mouse_moved)


    if trigger_selection_immediately:
        selected.emit(current_item_index, selectors[current_item_index], true, false)
        selectors[current_item_index]._handle_focused(true)


var _mouse_can_process: bool
func _physics_process(delta: float)->void :
    _mouse_can_process = false
    if !focused: return 

    var sel = current_item_index
    if Input.is_action_just_pressed(control_forward):
        current_item_index = 0 if sel + 1 > selectors.size() - 1 else current_item_index + 1
        _selection(false)
        return 

    if Input.is_action_just_pressed(control_backward):
        current_item_index = selectors.size() - 1 if sel - 1 < 0 else current_item_index - 1
        _selection(false)
        return 

    if has_node(prev_screen_node_path) && Input.is_action_just_pressed(prev_screen_control_cancel):
        get_node(prev_screen_node_path)._handle_select(false)

    _mouse_can_process = true


func move_selector(index: int, immediate: bool = false)->void :
    current_item_index = index
    _selection_update(immediate)


func _update_selectors()->void :
    selectors = []
    for child in get_children():
        if child is HSeparator || child is VSeparator:
            continue
        selectors.push_back(child)


func _selection(_mouse_input: bool = false)->void :
    if control_sound:
        Audio.play_1d_sound(control_sound, true, {"ignore_pause": true, "bus": "1D Sound"})
    _selection_update(false, _mouse_input)


func _selection_update(immediate: bool = false, _mouse_input: bool = false)->void :
    if selectors.size() <= current_item_index: return 
    if !is_instance_valid(selectors[current_item_index]): return 

    var item = selectors[current_item_index] as MenuSelection

    selected.emit(current_item_index, item, immediate, _mouse_input)
    item._handle_focused(true)

    for selector in selectors:
        if selector != item && selector.focused:
            selector._handle_focused(false)


func _on_mouse_pressed(index: MouseButton)->void :
    if !_can_mouse_process(): return 
    if !_mouse_can_process: return 
    if index != MOUSE_BUTTON_LEFT: return 

    for item in selectors:
        if !is_instance_valid(item): continue
        if !item is Control: continue
        if item.mouse_hovered && item.trigger_mouse:
            item._handle_select(true)


func _on_mouse_moved()->void :
    if !_can_mouse_process(): return 

    for item in selectors:
        if !is_instance_valid(item): continue
        if !item is Control: continue
        if item.get_global_rect().has_point(item.get_global_mouse_position()):
            if item.mouse_hovered == false:
                item.mouse_hovered = true
                current_item_index = selectors.find(item)
                _selection(true)
        else:
            item.mouse_hovered = false

    _mouse_can_process = true


func _can_mouse_process()->bool:
    if !focused: return false
    if !SettingsManager.get_tweak("mouse_in_menus", true): return false
    if get_tree().paused && !can_process(): return false
    if !get_tree().root.get_visible_rect().has_point(SettingsManager._current_mouse_pos): return false
    return true
