extends Node

func _ready()->void :
    await get_tree().physics_frame
    if SecretsManager.is_console_enabled():
        ProfileManager.current_profile.data.executed = true

func skip_continue_save():
    Data.values.skip_progress_continue = true
    if KevinGlobal.activated:
        ProfileManager.current_profile.data.kevin_mode_enabled = true
