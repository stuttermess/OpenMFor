extends Transition

var paused: bool = false
var speed_closing: float = 0.05
var speed_opening: float = -0.05
var circle: float = 1.0
var middle_switch: bool = false

var _is_with_pause: bool = false
var _on_player_after_middle: bool = false

@onready var color_rect: ColorRect = $ColorRect


func _ready()->void :
    name = "circle_transition"







    start.emit()


func on(ref: Variant, direct = false)->Transition:
    if ref is Node2D:
        color_rect.material.set_shader_parameter(&"center", Thunder.view.get_pos_ratio_in_screen(ref))
    elif ref is Vector2:
        if !direct:
            color_rect.material.set_shader_parameter(&"center", Thunder.view.get_pos_ratio_in_screen_by_pos(get_viewport_transform(), get_viewport_rect().size, ref))
        else:
            color_rect.material.set_shader_parameter(&"center", ref)

    return self


func on_player_after_middle(enabled: bool)->Transition:
    if !enabled:
        return self
    _on_player_after_middle = true
    return self



func with_speeds(s_closing: float, s_opening: float)->Transition:
    speed_closing = s_closing
    speed_opening = s_opening
    return self


func with_pause()->Transition:
    _is_with_pause = true
    return self


func _process(delta: float)->void :
    if paused: return 

    color_rect.material.set_shader_parameter("circle_size", circle)

    if circle >= 0:
        circle = max(circle - speed_closing * Thunder.get_delta(delta), 0)


func _physics_process(delta: float)->void :
    if paused: return 

    if circle == 0 && !middle_switch:

        if _is_with_pause:
            paused = true
        await get_tree().physics_frame
        middle.emit()

        if _is_with_pause:
            Scenes.scene_ready.connect(func ():
                var pl = Thunder._current_player

                if _on_player_after_middle && is_instance_valid(pl):
                    on(pl)
                else:
                    on(Vector2(0.5, 0.5), true)
                    await get_tree().physics_frame

                    paused = false
            , CONNECT_ONE_SHOT)
        await get_tree().physics_frame
        middle_switch = true

        speed_closing = speed_opening

    if middle_switch && circle > 2:
        end.emit()