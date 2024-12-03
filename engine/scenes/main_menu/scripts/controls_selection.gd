@tool
extends MenuSelection

@onready var value: Label = $Value
@onready var icon: TextureRect = $Joy / Icon
@onready var icon_2: TextureRect = $Joy / Icon2
@onready var icons_array: Array[TextureRect] = [icon, icon_2]
@onready var or_string: Label = $Joy / OR

@export var action_name: String
@export var enable_cancel: bool = true
@export var displayed_texture: Texture2D:
    set(new_value):
        displayed_texture = new_value
        if has_node(^"Text"):
            $Text.texture = displayed_texture

var changing: bool = false

const change_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _ready()->void :
    if Engine.is_editor_hint():
        return 

    icon.texture.region.size = Vector2(32, 32)
    assert ( !action_name.is_empty(), "Action Name is empty for " + name)


func _physics_process(delta: float)->void :
    if Engine.is_editor_hint():
        return 

    super (delta)

    if get_parent().focused:
        _text_process()

    if !focused:
        changing = false


func _handle_select(mouse_input: bool = false)->void :
    if !changing:
        changing = true
        icon.visible = false
        get_parent().focused = false
        value.text = "..."
        super (mouse_input)


func _text_process()->void :
    if changing:
        value.text = "..."
        return 

    if SettingsManager.device_keyboard:
        value.text = SettingsManager.settings.controls[action_name]
        icon.visible = false
        icon_2.visible = false
        or_string.visible = false
        return 

    if _device_check(["xbox", "xinput"]):
        _gamepad_icon_logic(
            preload("res://engine/scenes/main_menu/textures/gamepad_icons/xbox_icons.png"), 
            15
        )
    elif _device_check(["ps3", "ps4", "ps5", "dualshock", "playstation 3", "playstation 4", "playstation 5"]):
        _gamepad_icon_logic(
            preload("res://engine/scenes/main_menu/textures/gamepad_icons/ps_icons.png"), 
            20, 
            [-1, 5, 16, 17, 18, 19, 48, 50]
        )





    else:
        icon.visible = false
        icon_2.visible = false
        or_string.visible = false
        value.text = "Joy " + str(SettingsManager.settings.controls_joypad[action_name])


func _device_check(arr: Array[String])->bool:
    for i in len(arr):
        if arr[i] in SettingsManager.device_name.to_lower():
            return true
    return false


func _gamepad_icon_logic(texture: Texture2D, max_icons: int = 15, icon_exceptions: Array = [-1, 48, 50])->void :
    var actions_array: Array = SettingsManager.settings.controls_joypad[action_name]

    var placeholder_text: PackedStringArray
    var loop_ind: int = -1
    icon_2.visible = false
    for joy_index in actions_array:
        loop_ind += 1
        if loop_ind > 1:
            break
        if (joy_index > max_icons && joy_index < 40) || joy_index > 51 || joy_index in icon_exceptions:
            icons_array[loop_ind].visible = false
            placeholder_text.append("Joy " + str(joy_index))
            if joy_index == -1:
                placeholder_text.append("Joy Unknown")
            return 
        icons_array[loop_ind].texture.atlas = texture
        icons_array[loop_ind].texture.region.position.x = wrapi(joy_index * 32, 0, 320)
        icons_array[loop_ind].texture.region.position.y = floor(joy_index / 10.0) * 32
        icons_array[loop_ind].visible = true

    or_string.visible = icon_2.visible

    value.text = " / ".join(placeholder_text)


func _input(event: InputEvent)->void :
    if Engine.is_editor_hint():
        return 
    if !changing:
        return 

    if event is InputEventKey && event.pressed && !event.echo:
        if SettingsManager.device_keyboard && ( !event.is_action("ui_cancel") || !enable_cancel):
            var scancode: String = event.as_text()
            SettingsManager.settings.controls[action_name] = scancode
            SettingsManager._load_keys()
            Audio.play_1d_sound(change_sound, true, {"ignore_pause": true, "bus": "1D Sound"})

        _after_change()
    elif event is InputEventJoypadButton && event.is_pressed():
        if !SettingsManager.device_keyboard:
            set_joy_control(event.button_index)
            Audio.play_1d_sound(change_sound, true, {"ignore_pause": true, "bus": "1D Sound"})

        _after_change()
    elif event is InputEventJoypadMotion && abs(event.axis_value) >= 0.5 && !SettingsManager.device_keyboard:
        set_joy_control(40 + (event.axis * 2) + (0 if signf(event.axis_value) < 0 else 1))
        Audio.play_1d_sound(change_sound, true, {"ignore_pause": true, "bus": "1D Sound"})

        _after_change()


func _after_change()->void :
    changing = false


    await get_tree().physics_frame
    await get_tree().physics_frame

    get_parent().focused = true


func set_joy_control(joy_index: int)->void :
    var joy_array: Array = SettingsManager.settings.controls_joypad[action_name].duplicate()
    joy_array.push_front(joy_index)
    if joy_array.size() > 2:
        joy_array.resize(joy_array.size() - 1)
    print(joy_array.map(func (v): return type_string(typeof(v))))
    if joy_array.count(joy_index) > 1:
        joy_array.resize(1)

    SettingsManager.settings.controls_joypad[action_name] = joy_array
    SettingsManager._load_joy_controls()
