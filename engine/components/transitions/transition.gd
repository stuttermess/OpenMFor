extends Control
class_name Transition


signal start
signal middle
signal end


func build()->void :
    TransitionManager.accept_transition(self)
    start.emit()
