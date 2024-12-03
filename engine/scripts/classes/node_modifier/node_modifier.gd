@icon("./node_modifier.svg")
extends Node
class_name NodeModifier

@export var custom_target: NodePath
@export var target_base_class_name: String = "Node"

@onready var target_node: Node = get_node_or_null(custom_target) if custom_target else get_parent()


func _init()->void :
    ready.connect(_custom_ready)


func _custom_ready()->void :
    if !is_instance_valid(target_node):
        printerr("[NodeModifier]: Failed to retrieve the target node. Please check the target reference.")
