extends ByNodeScript

var player: Player
var suit: PlayerSuit
var config: PlayerConfig


func _ready()->void :
    player = node as Player
    player.underwater.got_into_water.connect(player.set.bind(&"is_underwater", true), CONNECT_REFERENCE_COUNTED)
    player.underwater.got_out_of_water.connect(player.set.bind(&"is_underwater", false), CONNECT_REFERENCE_COUNTED)


func _physics_process(delta: float)->void :
    if player.get_tree().paused: return 
    suit = node.suit
    config = suit.physics_config

    delta = player.get_physics_process_delta_time()

    if !player.completed: player.control_process()

    _shape_process()
    if player.warp != Player.Warp.NONE: return 


    _head_process()

    _body_process()

    _floor_process()

    if player.debug_fly:
        _movement_debug(delta)
    if player.no_movement:
        return 
    if player.is_climbing:
        _movement_climbing(delta)
    elif player.is_sliding:
        _movement_sliding(delta)
        _movement_y(delta)
    else:
        _movement_x(delta)
        _movement_y(delta)
    player.motion_process(delta)
    if player.is_on_wall():
        player.speed.x = 0


func _movement_debug(delta)->void :
    var speed: float = 400.0
    var dir: Vector2 = Vector2(
        Input.get_axis(&"m_left", &"m_right"), 
        Input.get_axis(&"m_up", &"m_down")
    )
    var run: int = 1 + int(Input.is_action_pressed(&"m_run"))

    var vel: Vector2 = speed * dir * run
    player.position += vel * delta



func _accelerate(to: float, acce: float, delta: float)->void :
    player.speed.x = move_toward(player.speed.x, to * player.direction, abs(acce) * delta)


func _decelerate(dece: float, delta: float)->void :
    _accelerate(0, dece, delta)


func _movement_x(delta: float)->void :

    if player.slided:
        var do_slide = true if suit.physics_crouchable else true if player.left_right == 0 else false

        if do_slide:
            _start_sliding_movement()
            return 

    if !player.is_crouching && player.has_stuck && player.is_on_floor():
        player.left_right = 0
        player.jumping = 0
        player.speed.x = - player.direction * config.stuck_recovery_speed
    player.is_skidding = (
            player._skid_tweak && 
            (sign(player.left_right) == - player.direction) && 
            abs(player.speed.x) > 1 && 
            player.is_on_floor()
    )

    if player.is_crouching || player.left_right == 0 || player.completed:
        var deceleration: float = (
            config.walk_crouch_deceleration if (
                player.is_crouching && player.left_right == 0
            ) else config.walk_deceleration
        )
        _decelerate(deceleration, delta)
        return 

    if player.left_right != 0 && abs(player.speed.x) < 1:
        @warning_ignore("narrowing_conversion")
        player.direction = signi(player.left_right)
        player.speed.x = player.direction * config.walk_initial_speed

    var max_speed: float
    if sign(player.left_right) == player.direction:
        if player.running:
            max_speed = (
                config.underwater_walk_max_running_speed if player.is_underwater else config.walk_max_running_speed

            )
        else:
            max_speed = (
                config.underwater_walk_max_walking_speed if player.is_underwater else config.walk_max_walking_speed

            )
        _accelerate(max_speed * abs(player.left_right), config.walk_acceleration, delta)
    elif sign(player.left_right) == - player.direction:
        _decelerate(config.walk_turning_acce, delta)
        if abs(player.speed.x) < 1:
            player.direction *= -1
    if abs(player.speed.x) > max_speed && sign(player.left_right) != - player.direction && player.is_underwater:
        _decelerate(config.walk_turning_acce, delta)


func _movement_y(delta: float)->void :
    if player.is_crouching && !ProjectSettings.get_setting("application/thunder_settings/player/jumpable_when_crouching", false):
        return 
    if player.completed: return 


    if player.is_underwater:
        if player.jumped && player.up_down <= 0:
            player.jump(config.swim_out_speed if player.is_underwater_out else config.swim_speed)
            player._has_jumped = true
            player.swam.emit()
            Audio.play_sound(config.sound_swim, player, false, {pitch = suit.sound_pitch})
        if player.speed.y < - abs(config.swim_max_speed) && !player.is_underwater_out:

            player.speed.y = lerp(player.speed.y, - abs(config.swim_max_speed), 0.125)

    else:
        if player.is_on_floor() && player.up_down <= 0:
            if player.jumping > 0 && !player._has_jumped:
                _stop_sliding_movement()
                player._has_jumped = true
                player.jump(config.jump_speed)
                Audio.play_sound(config.sound_jump, player, false, {pitch = suit.sound_pitch})
        elif player.jumping > 0 && player.speed.y < 0.0:
            var buff: float = config.jump_buff_dynamic if (abs(player.speed.x) > 50 && !player.is_on_wall()) else config.jump_buff_static
            player.speed.y -= abs(buff) * delta
    if !player.jumping && player.speed.y >= 0:
        player._has_jumped = false



func _movement_climbing(delta: float)->void :
    if player.is_crouching || player.completed: return 
    if player.is_sliding: _stop_sliding_movement()
    player.vel_set(Vector2(player.left_right, player.up_down) * suit.physics_config.climb_speed)
    if player.left_right != 0:
        player.direction = sign(player.left_right)

    player.speed -= player.gravity_dir * player.gravity_scale * GravityBody2D.GRAVITY * delta * 0.5


    if player.jumping > 0 && !player._has_jumped && player.up_down == 0:
        player._has_jumped = true
        player.is_climbing = false
        player.direction = sign(player.left_right)
        player.jump(config.jump_speed)
        Audio.play_sound(config.sound_jump, player, false, {pitch = suit.sound_pitch})



func _movement_sliding(delta: float)->void :
    if player.completed: return 
    var floor_normal: float = rad_to_deg(player.get_floor_normal().x)
    var dir: bool = player.direction == 1

    var accel: Callable = func (_norm: float)->void :
        _accelerate(config.slide_max_speed, (config.slide_acceleration / 50) * _norm, delta)
        player.is_sliding_accelerating = true

    var decel: Callable = func (_norm: float)->void :
        _decelerate((config.walk_deceleration / 50) * _norm, delta)
        player.is_sliding_accelerating = false


    if floor_normal >= 10.0:
        @warning_ignore("standalone_ternary")
        accel.call(abs(floor_normal)) if dir else decel.call(abs(floor_normal))
        if abs(player.speed.x) < 1: _start_sliding_movement()

    elif floor_normal <= -10.0:
        @warning_ignore("standalone_ternary")
        accel.call(abs(floor_normal)) if !dir else decel.call(abs(floor_normal))
        if abs(player.speed.x) < 1: _start_sliding_movement()

    else:
        decel.call(50)
        if abs(player.speed.x) < 1 || player.left_right != 0:
            _stop_sliding_movement()

    if player.left_right != 0 && sign(player.left_right) != player.direction && !player.slided:
        _stop_sliding_movement()


func _start_sliding_movement()->void :
    player.attack.killing_detection_scale = 8
    player.attack.enabled = true
    var floor_norm = rad_to_deg(player.get_floor_normal().x)
    if floor_norm <= -40.0:
        if player.speed.x > 0:
            player.speed.x = 1
        player.direction = -1
    if floor_norm >= 40.0:
        if player.speed.x < 0:
            player.speed.x = -1
        player.direction = 1
    player.is_sliding = true


func _stop_sliding_movement()->void :
    player.is_sliding = false
    player.is_sliding_accelerating = false
    player.attack.enabled = player.is_starman()
    if !player.is_starman(): player.starman_combo.reset_combo()
    player.attack.killing_detection_scale = 2



func _shape_process()->void :
    var crouch_shape: bool = (
        player.is_crouching && 
        player.warp == Player.Warp.NONE
    )
    var shaper: Shaper2D = (
        suit.physics_shaper_crouch if crouch_shape else suit.physics_shaper
    )
    if !shaper: return 

    var is_colliding: bool = _shape_recovery_process()

    player.has_stuck = is_colliding
    if player.has_stuck:
        shaper = suit.physics_shaper_crouch

    shaper.install_shape_for(player.collision_shape)
    shaper.install_shape_for_caster(player.body)
    shaper.install_shape_for_caster(player.attack)

    if player.collision_shape.shape is RectangleShape2D:
        player.head.position.y = player.collision_shape.position.y - player.collision_shape.shape.size.y / 2 - 2


func _shape_recovery_process()->bool:
    if player.warp != Player.Warp.NONE || player.completed:
        return false

    var raycast: RayCast2D = player.collision_recovery
    raycast.position = suit.physics_shaper.shape_pos
    raycast.target_position.y = (
        - suit.physics_shaper.shape.size.y + 16 - suit.physics_shaper.shape_pos.y
    )
    raycast.force_raycast_update()
    var collider = raycast.get_collider()
    var is_colliding: bool = false
    if collider is TileMap:
        var cell: Vector2i = collider.get_coords_for_body_rid(raycast.get_collider_rid())
        var layer = collider.get_layer_for_body_rid(raycast.get_collider_rid())
        var tile_data: TileData = collider.get_cell_tile_data(layer, cell)
        if tile_data:
            var phys_layer = collider.tile_set.get_physics_layers_count()
            for i in phys_layer:
                for j in tile_data.get_collision_polygons_count(i):
                    if !tile_data.is_collision_polygon_one_way(i, j):
                        is_colliding = true
                        break
    elif collider is CollisionObject2D:
        var i = raycast.get_collider_shape()
        if !collider.is_shape_owner_one_way_collision_enabled(i):
            is_colliding = true
    else:
        is_colliding = raycast.is_colliding()

    return is_colliding



func _head_process()->void :
    player.is_underwater_out = true


    for i in player.head.get_collision_count():
        var collider: Node2D = player.head.get_collider(i) as Node2D
        if !collider: continue

        if collider.is_in_group(&"#water"):
            player.is_underwater_out = false
            if player.bubbler.is_stopped():
                player.bubbler.start()

        if collider is StaticBumpingBlock && collider.has_method(&"got_bumped") && collider.global_position.direction_to(player.head.global_position + 8 * Vector2.DOWN.rotated(player.global_rotation)).dot(Vector2.DOWN.rotated(collider.global_rotation)) > cos(PI / 4) && ((player.speed_previous.y < 0 && !collider.initially_visible_and_solid) || (player.is_on_ceiling() && collider.initially_visible_and_solid) || (player.is_crouching)):





            collider.got_bumped.call_deferred(player)

    player.bubbler.paused = player.is_underwater_out


func _body_process()->void :
    if !player.body.shape: return 

    var player_velocity = player.velocity.normalized()

    for i in player.body.get_collision_count():
        var collider: Node2D = player.body.get_collider(i) as Node2D
        if !is_instance_valid(collider):
            continue
        if !collider.has_node("EnemyAttacked"): continue

        var enemy_attacked: Node = collider.get_node("EnemyAttacked")
        var result: Dictionary = enemy_attacked.got_stomped(player, player_velocity)
        if result.is_empty(): return 
        if result.result == true:
            if player.jumping > 0:
                player.speed.y = - result.jumping_max * config.jump_stomp_multiplicator
            else:
                player.speed.y = - result.jumping_min * config.jump_stomp_multiplicator
        else:
            player.hurt(enemy_attacked.get_meta(&"stomp_tags", {}))


func _floor_process()->void :



    if !is_instance_valid(player): return 
    if !player.is_on_floor(): return 

    for i in player.get_slide_collision_count():
        var collision: KinematicCollision2D = player.get_slide_collision(i)
        if !collision: continue

        var collider = collision.get_collider()
        if !is_instance_valid(collider): continue

        if collider.has_method("_player_landed"):
            collider._player_landed(player)
