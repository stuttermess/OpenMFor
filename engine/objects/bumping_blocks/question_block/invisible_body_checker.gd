extends Area2D




var _active: bool = true

@onready var parent: StaticBumpingBlock = $".."

func _ready()->void :
    if parent.initially_visible_and_solid:
        queue_free.call_deferred()
        return 
    parent.bumped.connect(func ()->void :
        _active = false
        queue_free.call_deferred()
    )


func got_bumped(by: Node2D)->void :
    if !_active: return 
    if parent._triggered: return 
    if by is Player: return 

    parent.call_bump()
