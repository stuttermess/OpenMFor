extends Command

static func register()->Command:
    return new().set_name("fly").add_param("on/off", TYPE_STRING, true).set_description("Fly mode for the player")

func execute(args: Array)->Command.ExecuteResult:
    var player: Player = Thunder._current_player
    if !player:
        return Command.ExecuteResult.new("ERROR: No player is available!")

    var set_to: String = "Success"
    if len(args) == 0:
        if !player.debug_fly:
            set_on(player)
            set_to += ": ON"
        else:
            set_off(player)
            set_to += ": OFF"
        return Command.ExecuteResult.new(set_to)

    match args[0]:
        "on":
            set_on(player)
        "off":
            set_off(player)
        _:
            return Command.ExecuteResult.new("ERROR: Invalid argument provided")

    return Command.ExecuteResult.new(set_to)


func set_on(player: Player)->void :
    player.debug_fly = true
    player.no_movement = true


func set_off(player: Player)->void :
    player.debug_fly = false
    player.no_movement = false
