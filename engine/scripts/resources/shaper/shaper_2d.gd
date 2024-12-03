extends Resource
class_name Shaper2D







@export var shape: Shape2D

@export var shape_pos: Vector2



func install_shape_for(collision_shape: CollisionShape2D)->void :
    if !shape: return 
    if collision_shape.shape != shape:
        collision_shape.set_deferred(&"shape", shape)
    if collision_shape.position != shape_pos:
        collision_shape.set_deferred(&"position", shape_pos)



func install_shape_for_caster(caster: ShapeCast2D)->void :
    if !shape: return 
    if caster.shape != shape:
        caster.set_deferred(&"shape", shape)
    if caster.position != shape_pos:
        caster.set_deferred(&"position", shape_pos)


func is_shape_equal(collision_shape: CollisionShape2D)->bool:
    return shape && collision_shape.shape == shape
