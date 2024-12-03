extends Node




const ATTACKERS: Dictionary = {
    head = &"head", 
    starman = &"starman", 
    shell = &"shell", 
    fireball = &"fireball", 
    beetroot = &"beetroot", 
    iceball = &"iceball", 
    iceblock = &"iceblock", 
    hammer = &"hammer", 
    boomerang = &"boomerang"
}


enum PLAYER_POWER{
    SMALL, 
    SUPER, 
    FULL
}



enum PROJECTILE_BELONGS{
    PLAYER, 
    ENEMY
}


var values: Dictionary = {
    lives = -1, 
    score = 0, 
    prev_score = 0, 
    coins = 0, 
    time = -1, 
    checkpoint = -1, 
    checked_cps = [], 
    onetime_blocks = true
}


var technical_values: Dictionary = {
    impulse_progress_continue = false, 
}

@warning_ignore("unused_private_class_variable")
@onready var _default_values: Dictionary = values.duplicate(true)

signal coin_added
signal score_added
signal life_added
signal values_reset


func add_coin(amount: int = 1)->void :
    coin_added.emit()
    values.coins += 1
    if values.coins > 99:
        values.coins = 0
        Thunder.add_lives(1)
        Audio.play_1d_sound(preload("res://engine/objects/players/prefabs/sounds/1up.wav"), false)
        if is_instance_valid(Thunder._current_hud):
            Thunder._current_hud.pulse_label(Thunder._current_hud.coins)


func add_score(amount: int)->void :
    score_added.emit()
    values.score += amount
    if SettingsManager.get_tweak("life_every_2_mil_score", false):
        var two_mil: int = floor(values.score / 1000000)
        if two_mil > values.prev_score:
            values.prev_score = two_mil

            await get_tree().create_timer(0.3, false).timeout
            Thunder.add_lives(1)
            Audio.play_1d_sound(preload("res://engine/objects/players/prefabs/sounds/1up.wav"), false)

            if is_instance_valid(Thunder._current_hud):
                Thunder._current_hud.pulse_label(Thunder._current_hud.mario_score)


func add_lives(amount: int = 1)->void :
    life_added.emit()
    values.lives += amount


func reset_all_values()->void :
    values_reset.emit()
    Thunder._current_player_state = null
    Thunder._current_player_state_path = ""
    values = _default_values.duplicate(true)
