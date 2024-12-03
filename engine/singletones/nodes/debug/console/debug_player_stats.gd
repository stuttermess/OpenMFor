extends Label

var target_text: String


func _physics_process(delta: float)->void :
    visible = Console.player_stats_shown
    if !Console.player_stats_shown: return 
    var other_text: String = "PAUSE:" + str(get_tree().paused) + "\nNICK: %s CHAR: %s" % [

        CharacterManager.get_character_display_name(), 
        SettingsManager.settings.get("character", ""), 
    ]

    var pl: Player = Thunder._current_player
    if !pl:
        text = "Player Not Found " + other_text + target_text
        return 

    target_text = "\nX: %s\nY: %s\nSPDX: %s\nSPDY: %s\nsuit: %s | lr:%s ud:%s\nSTUCK:%s SLIDED:%s ISSLIDING:%s\nCOMPL:%s NOMOVE:%s WARPSTATE:%s\nFCWS: %s%s%s%s\nITEM:%s\n" % [










        pl.global_position.x, 
        pl.global_position.y, 
        pl.speed.x, 
        pl.speed.y, 
        pl.suit.name if pl.get("suit") else null, 
        pl.get("left_right"), 
        pl.get("up_down"), 
        pl.get("has_stuck"), 
        pl.get("slided"), 
        pl.get("is_sliding"), 
        pl.get("completed"), 
        pl.get("no_movement"), 
        pl.get("warp"), 
        int(pl.is_on_floor()), 
        int(pl.is_on_ceiling()), 
        int(pl.is_on_wall()), 
        int(pl.is_on_slope()), 
        pl.get("holding_item"), 
    ]
    text = other_text + target_text
