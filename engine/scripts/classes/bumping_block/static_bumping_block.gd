@icon("res://engine/scripts/classes/bumping_block/icon.png")

extends AnimatableBody2D
class_name StaticBumpingBlock




const _HITTER: PackedScene = preload("res://engine/objects/bumping_blocks/_hitter/hit.tscn")


@export var result: InstancePowerup

@export var result_as_sibling_node: bool = true

@export var active: bool = true
@export var lock_while_triggered: bool = false
var _triggered: bool = false

@export_group("Sounds")

@export var appear_sound: AudioStream = null

@export var bump_sound: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/bump.wav")

@export var break_sound: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/break.wav")

@export_group("Block Visibility")

@export var initially_visible_and_solid: bool = true:
    set(to):
        initially_visible_and_solid = to
        if !Engine.is_editor_hint(): return 
        if !initially_visible_and_solid:
            $Sprites.modulate.a = 0.25
        else:
            $Sprites.modulate.a = 1

@export var exists_once: bool = false

var _unsolid_layer: int = 16
var _unsolid_mask: int = 1


var _no_result_appearing_animation: bool = false

var _ignore_colliding_body_correction: bool = false

@onready var collision_layer_ori: int = collision_layer
@onready var collision_mask_ori: int = collision_mask

@onready var _collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var _sprites: Node2D = $Sprites
@onready var _animated_sprite_2d: AnimatedSprite2D = $Sprites / AnimatedSprite2D


signal bumped

signal result_appeared


var current_tw: Tween


func _enter_tree()->void :
    if !Engine.is_editor_hint(): return 


func _ready()->void :
    if !Engine.is_editor_hint():
        modulate.a = 1
        if !Data.values.onetime_blocks && exists_once: return queue_free()
        if !initially_visible_and_solid:
            collision_layer = _unsolid_layer
            collision_mask = _unsolid_mask
            _collision_shape_2d.set_deferred(&"disabled", true)
        _ignore_colliding_body_correction = !initially_visible_and_solid
        _sprites.visible = initially_visible_and_solid


func _physics_process(delta)->void :
    if Engine.is_editor_hint():
        _editor_process()
        return 

func _editor_process()->void :
    pass






func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false):
    if _triggered && lock_while_triggered: return 
    if !active: return 

    _sprites.visible = true
    _ignore_colliding_body_correction = false
    if !initially_visible_and_solid:
        collision_layer = collision_layer_ori
        collision_mask = collision_mask_ori
        _collision_shape_2d.set_deferred(&"disabled", false)

    _triggered = true


    if is_instance_valid(current_tw):
        current_tw.kill()

    current_tw = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
    current_tw.tween_property(_animated_sprite_2d, "position", Vector2(0, -8).rotated(deg_to_rad(bump_rotation)), 0.12).set_ease(Tween.EASE_OUT)
    current_tw.tween_property(_animated_sprite_2d, "position", Vector2.ZERO, 0.12).set_ease(Tween.EASE_IN)
    current_tw.tween_callback(_lt.bind(disable))

    if result:
        call_deferred(&"_creation", result.prepare())
        result_appeared.emit()
    else:
        Audio.play_sound(bump_sound, self)

    bumped.emit()
    hit_attack()

func _lt(disable):
    if !disable:
        _triggered = false

func _creation(creation: InstanceNode2D)->void :
    if !creation: return 

    var created: Node2D = NodeCreator.prepare_ins_2d(creation, self).execute_instance_script({}, &"_pre_ready").create_2d().execute_instance_script({}, &"_after_ready").get_node()


    if created && created.has_method(&"_from_bumping_block"): created._from_bumping_block()

    Thunder.reorder_on_top_of(created, self)

    creation.set_meta(&"no_appearing", _no_result_appearing_animation)

    Audio.play_sound(appear_sound, self)


func is_body_colliding(body: CollisionObject2D, shape_cast: ShapeCast2D)->bool:
    if !shape_cast: push_error("Shape Cast is not valid.");return false
    if !shape_cast.enabled: return false

    if shape_cast.is_colliding():
        for i in shape_cast.get_collision_count():
            var collider = shape_cast.get_collider(i)

            return is_instance_of(collider, body)
    return false


func is_player_colliding(shape_cast: ShapeCast2D)->bool:
    if !shape_cast: push_error("Shape Cast is not valid.");return false
    if !shape_cast.enabled: return false

    if shape_cast.is_colliding():
        for i in shape_cast.get_collision_count():
            var collider = shape_cast.get_collider(i)

            return collider is Player
    return false


func hit_attack()->void :
    var hitter: float = - _collision_shape_2d.shape.size.y / 2 if _collision_shape_2d.shape is RectangleShape2D else -16
    NodeCreator.prepare_2d(_HITTER, self).create_2d().bind_global_transform(Vector2(0, hitter - 1))
