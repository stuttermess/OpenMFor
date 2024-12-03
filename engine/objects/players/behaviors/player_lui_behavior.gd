extends ByNodeScript

const trail = preload("res://engine/objects/effects/trail/trail.tscn")

var player: Player

var trail_timer: float


func _ready()->void :
    player = node as Player


func _physics_process(delta: float)->void :
    if player.get_tree().paused: return 

    if trail_timer > 0.0: trail_timer -= 1 * Thunder.get_delta(delta)
    if !player.is_on_floor() && trail_timer <= 0.0:
        trail_timer = 1.5
        Effect.trail.call_deferred(
            player, 
            player.sprite.sprite_frames.get_frame_texture(player.sprite.animation, player.sprite.frame), 
            player.sprite.position + Vector2(0, -16), 
            player.sprite.flip_h, 
            player.sprite.flip_v, 
            true, 
            0.05, 
            1.0, 
            null, 
            1
        )
