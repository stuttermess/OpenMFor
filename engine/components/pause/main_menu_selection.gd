extends MenuSelection

@onready var pause: Control = $"../.."


func _handle_select(mouse_input: bool = false)->void :
    Audio.stop_all_sounds()
    super (mouse_input)
    Scenes.custom_scenes.pause._no_unpause = false
    pause.toggle(true)

    Scenes.goto_scene(ProjectSettings.get("application/thunder_settings/main_menu_path"))
