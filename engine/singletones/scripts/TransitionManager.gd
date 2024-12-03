extends Node


var current_transition: Transition

signal transition_start
signal transition_middle
signal transition_end

func accept_transition(trans: Transition)->void :
    GlobalViewport.container.add_child(trans)
    current_transition = trans

    trans.start.connect(func ():
        transition_start.emit()
    )
    trans.middle.connect(func ():
        transition_middle.emit()
    )
    trans.end.connect(func ():
        transition_end.emit()
        trans.queue_free()
        current_transition = null
    )
