extends Node

@export var enable_game_over_continues: bool = true

func _ready()->void :
    Data.reset_all_values()
    ProfileManager.load_all_profiles()
    ProfileManager.create_new_profile(&"debug")
    Scenes.custom_scenes.game_over.skip_to_save = !enable_game_over_continues
    Data.values.skip_progress_continue = true
