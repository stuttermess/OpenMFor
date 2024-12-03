extends MenuSelection

@onready var node_2d: Node2D = $"../.."
@onready var control = $"../../../Leaderboard/SubViewportContainer/SubViewport/Control/CanvasLayer/Title"

func _handle_select(mouse_input: bool = false)->void :
    super (mouse_input)
    get_parent().focused = false
    node_2d.start_game()
