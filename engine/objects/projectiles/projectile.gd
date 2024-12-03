extends GeneralMovementBody2D
class_name Projectile

@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER
@export var vision_path: NodePath = ^"VisibleOnScreenNotifier2D"

@onready var vision_node: VisibleOnScreenNotifier2D = get_node_or_null(vision_path)


func _ready()->void :
    add_to_group(&"end_level_sequence")
    super ()



func _on_level_end()->void :
    pass



func offscreen_handler(delete_offscreen_after_sec: float = 2.0, offscreen_offset: float = 32)->void :
    assert (vision_node, "Please set up Vision Path in the inspector for the projectile")
    await get_tree().physics_frame
    if !is_inside_tree():
        return 
    if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:

        if !vision_node.is_on_screen():
            queue_free()

        elif !Thunder.view.screen_top(global_position, offscreen_offset, true):
            queue_free()

    elif !vision_node.is_on_screen():
        await get_tree().create_timer(delete_offscreen_after_sec, false).timeout
        if is_inside_tree() && !vision_node.is_on_screen():
            queue_free()
