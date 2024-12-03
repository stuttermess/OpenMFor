@icon("./gravity_body_2d.svg")
extends CorrectedCharacterBody2D
class_name GravityBody2D






const GRAVITY: float = 2500.0

@export_group("Speed")

@export var speed: Vector2:
    set(value):
        velocity = value.rotated(gravity_dir.angle() - PI / 2)
    get:
        return velocity.rotated( - gravity_dir.angle() + PI / 2)
@export_group("Gravity")


@export var gravity_dir: Vector2 = Vector2.DOWN

@export var gravity_dir_rotation: bool = true

@export var gravity_scale: float

@export_range(0, 100000, 0.1) var max_falling_speed: float
@export_group("Collision")


@export var collision: bool = true
@export_group("Up Direction")

@export var auto_update_up_direction: bool = true


var speed_previous: Vector2

@onready var _up_temp: Vector2 = up_direction


signal collided

signal collided_wall

signal collided_ceiling

signal collided_floor






func motion_process(delta: float, slide: bool = false)->void :
    var gravity: float = gravity_scale * GRAVITY

    speed_previous = speed

    speed += gravity * gravity_dir * delta * 0.5

    var is_speed_capped: bool
    if max_falling_speed > 0 && speed.y > max_falling_speed:
        speed.y = max_falling_speed
        is_speed_capped = true

    if auto_update_up_direction:
        update_up_direction()

    do_movement(delta, slide, false)

    if !is_speed_capped:
        speed += gravity * gravity_dir * delta * 0.5

    if slide && floor_constant_speed && !is_on_wall():
        speed.x = speed_previous.x

    _collision_signals()






func do_movement(delta: float, slide: bool = false, emit_detection_signal: bool = true)->void :
    if velocity.is_equal_approx(Vector2.ZERO): return 

    if !collision:
        global_position += velocity * delta
        return 

    if is_on_floor() && velocity.y > 0:
        velocity.y = 1

    if correct_collision:
        move_and_slide_corrected()
    else:
        move_and_slide()

    if slide:
        velocity = get_real_velocity()

    if !emit_detection_signal: return 
    _collision_signals()


func _collision_signals()->void :
    if is_on_wall():
        collided.emit()
        collided_wall.emit()
    if is_on_ceiling():
        collided.emit()
        collided_ceiling.emit()
    if is_on_floor():
        collided.emit()
        collided_floor.emit()




func accelerate(to: Vector2, a: float)->void :
    speed = speed.move_toward(to, a)



func accelerate_x(to: float, a: float)->void :
    speed.x = move_toward(speed.x, to, a)



func accelerate_y(to: float, a: float)->void :
    speed.y = move_toward(speed.y, to, a)



func turn_x()->void :
    if speed_previous.x == 0:
        speed.x *= -1
        return 
    speed_previous.x *= -1
    speed.x = speed_previous.x



func turn_y()->void :
    if speed_previous.y == 0:
        speed.y *= -1
        return 
    speed_previous.y *= -1
    speed.y = speed_previous.y



func jump(jumping_speed: float)->void :
    speed.y = - abs(jumping_speed)



func vel_set(vel: Vector2)->void :
    speed = vel



func vel_set_x(velx: float)->void :
    speed.x = velx



func vel_set_y(vely: float)->void :
    speed.y = vely



func stop_notify(wall_notify: bool = true, ceiling_notify: bool = true, floor_notify: bool = true)->void :
    if wall_notify && is_on_wall() && speed.x != 0: speed.x = 0
    if ceiling_notify && is_on_ceiling() && speed.y < 0 && !slide_on_ceiling: speed.y = 0
    if floor_notify && is_on_floor() && speed.y > 0 && !floor_stop_on_slope: speed.y = 0




func get_global_gravity_dir()->Vector2:
    return gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir




func update_up_direction()->void :
    up_direction = _up_temp.rotated(global_rotation)




func is_on_slope()->bool:
    var dot: float = get_floor_normal().dot(get_global_gravity_dir())
    return dot < 0 && !is_equal_approx(dot, -1)



func is_able_slope_down()->bool:
    return !floor_stop_on_slope && !is_on_wall() && is_on_slope()
