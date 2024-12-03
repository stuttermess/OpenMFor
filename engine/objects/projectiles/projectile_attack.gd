extends ShapeCast2D






@export var killer_type: StringName = Data.ATTACKERS.fireball


@export var killing_detection_scale: float = 1.0


@export var is_reflectable: bool = false

@export var trigger_enemy_failed_signal: bool = true

@export var special_tags: Array[StringName]



var velocity: Vector2


var belongs_to: Data.PROJECTILE_BELONGS

@onready var par: Node = get_parent()

signal killed(what: Node, result: Dictionary)
signal killed_notify
signal killed_succeeded
signal killed_failed
signal damaged_player
signal damaged_player_failed


func _physics_process(delta: float)->void :
    if &"velocity" in par && par.get(&"velocity") is Vector2:
        velocity = par.velocity if !par is CharacterBody2D else par.get_real_velocity()
        target_position = (velocity * delta * killing_detection_scale).rotated( - global_rotation)

    if &"belongs_to" in par:
        belongs_to = par.belongs_to

    match belongs_to:
        Data.PROJECTILE_BELONGS.PLAYER: _kill_enemy()
        Data.PROJECTILE_BELONGS.ENEMY: _hurt_player()


func _kill_enemy()->void :
    var result: Dictionary = {}
    var enemy_attacked: Node = null

    for i in get_collision_count():
        var ins: Area2D = get_collider(i) as Area2D
        if !ins || ins.get_parent() == get_parent():
            continue

        enemy_attacked = ins.get_node_or_null(^"EnemyAttacked")
        if !enemy_attacked:
            continue

        enemy_attacked.set_meta(&"attacker_speed", velocity)
        result = await enemy_attacked.got_killed(
            killer_type, special_tags, trigger_enemy_failed_signal
        )
    if result.is_empty():
        return 

    var attackee: Node = result.attackee if &"attackee" in result else null
    if result.result:
        killed_notify.emit()
        killed.emit(attackee, result)
        killed_succeeded.emit()
        return 
    else:
        killed_notify.emit()
        if trigger_enemy_failed_signal == true:
            killed.emit(attackee, result)
            killed_failed.emit()
        if enemy_attacked:
            enemy_attacked.set_meta(&"attacker_speed", Vector2.ZERO)
        return 

func _hurt_player()->void :
    for i in get_collision_count():
        var ins: PhysicsBody2D = get_collider(i) as PhysicsBody2D
        if !ins:
            continue
        elif ins is Player:
            if &"suit" in ins && ins.suit && &"behavior_crouch_reflect_fireballs" in ins.suit && ins.suit.behavior_crouch_reflect_fireballs == true && ins.is_crouching == true && is_reflectable:



                    damaged_player_failed.emit()
                    break

            damaged_player.emit()
            ins.hurt()
            break
