extends Node







const COIN_EFFECT = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")
const COIN = preload("res://engine/objects/items/coin/coin.wav")

const ICEBLOCK_PATH = "res://engine/objects/items/ice_block/ice_block.tscn"

@export_category("EnemyAttacked")
@export_group("General")

@export_node_path("Node2D") var center_node: NodePath = ^"../.."
@export_group("Stomping", "stomping_")

@export var stomping_enabled: bool = true


@export var stomping_hurtable: bool = true




@export var stomping_standard: Vector2 = Vector2.DOWN


@export var stomping_offset: Vector2

@export var stomping_creation: InstanceNode2D

@export var stomping_scores: int

@export var stomping_sound: AudioStream


@export var stomping_player_jumping_min: float = 450


@export var stomping_player_jumping_max: float = 700
@export var stomping_only_from_above: bool = false
@export var stomping_delay_frames: float = 5
@export_group("Killing", "killing_")


@export var killing_enabled: bool = true




@export var killing_immune: Dictionary = {
    Data.ATTACKERS.head: false, 
    Data.ATTACKERS.starman: false, 
    Data.ATTACKERS.shell: false, 
    &"shell_defence": 0, 
    &"shell_forced": false, 
    Data.ATTACKERS.fireball: false, 
    Data.ATTACKERS.beetroot: false, 
    Data.ATTACKERS.iceball: false, 
    Data.ATTACKERS.iceblock: false, 
    Data.ATTACKERS.hammer: false, 
    Data.ATTACKERS.boomerang: false, 

}

@export var killing_creation: InstanceNode2D

@export var killing_scores: int

@export var killing_sound_succeeded: AudioStream

@export var killing_sound_failed: AudioStream

@export var turn_into_coin_on_level_end: bool = true
@export_group("Frozen")

@export var frozen_enabled: bool = true

@export_node_path("CanvasItem") var ice_sprite: NodePath



@export var ice_sprite_autoset: bool = true

@export var ice_sprite_offset: Vector2

@export var ice_fragile: bool

@export var frozen_sound: AudioStream = preload("res://engine/objects/items/ice_block/sfx/ice_break.mp3")
@export_group("Sound", "sound_")
@export var sound_pitch: float = 1.0
@export_group("Extra")

@export var custom_vars: Dictionary

@export var custom_script: Script

var _stomping_delayer: SceneTreeTimer:
    get = get_stomping_delayer

@warning_ignore("unused_private_class_variable")
@onready var _extra_script: Script = ByNodeScript.activate_script(custom_script, self, custom_vars)
@onready var _center: Node2D = get_node_or_null(center_node)
@onready var _ice_sprite: Node2D = get_node_or_null(ice_sprite)

@onready var _stomping_combo_enabled: bool = SettingsManager.get_tweak("stomping_combo", false)


signal stomped

signal stomped_succeeded

signal stomped_failed

signal killed

signal killed_succeeded

signal killed_failed

signal attack_custom_signal

signal killed_frozen

var _on_killed: bool


func _ready()->void :
    stomped_succeeded.connect(_lss)
    killed_succeeded.connect(_lks)
    killed_failed.connect(_lkf)
    killed_frozen.connect(_lkfz)
    if turn_into_coin_on_level_end:
        add_to_group(&"end_level_sequence")
    if (
        !is_instance_valid(_ice_sprite) && 
        ice_sprite_autoset && 
        is_instance_valid(_center) && 
        "sprite" in _center && 
        _center.sprite
    ):
        _ice_sprite = _center.get_node_or_null(_center.sprite)


func _lss():
    Audio.play_sound(stomping_sound, _center, false, {pitch = sound_pitch})
func _lks():
    Audio.play_sound(killing_sound_succeeded, _center, false, {pitch = sound_pitch})
func _lkf():
    Audio.play_sound(killing_sound_failed, _center, false, {pitch = sound_pitch})
func _lkfz():
    Audio.play_sound(frozen_sound, _center, false, {pitch = sound_pitch})






func got_stomped(by: Node2D, vel: Vector2, offset: Vector2 = Vector2(0, -2))->Dictionary:
    var result: Dictionary

    if !stomping_enabled || _stomping_delayer: return result

    if !_center:
        push_error("[No Center Node Error] No _center node set. Please check if you have set the _center node of EnemyAttacked. At " + str(get_path()))
        return result

    var dot: float = by.global_position.direction_to(
        _center.global_transform.translated(stomping_offset + offset).get_origin()
    ).dot(stomping_standard.rotated(_center.global_rotation))
    var dotdown: float = vel.dot(stomping_standard.rotated(_center.global_rotation))

    stomped.emit()
    if dot > 0 && !(stomping_only_from_above && dotdown < 0):
        stomping_delay()
        stomped_succeeded.emit()
        if stomping_scores > 0:
            if !_stomping_combo_enabled:
                ScoreText.new(str(stomping_scores), _center)
                Data.values.score += stomping_scores
            elif is_instance_valid(by):
                var _do_combo: bool = true
                if by.stomping_combo.get_combo() == 0:
                    var try = Combo.STOMP_COMBO_ARRAY.find(stomping_scores)
                    if try > 0:
                        by.stomping_combo._combo = try
                    else:
                        var combo_size: int = len(Combo.STOMP_COMBO_ARRAY)
                        for i in combo_size:
                            if stomping_scores < Combo.STOMP_COMBO_ARRAY[i]:
                                by.stomping_combo._combo = max(0, i)
                                _do_combo = false
                                ScoreText.new(str(stomping_scores), by)
                                Data.values.score += stomping_scores
                                break
                if _do_combo:
                    by.stomping_combo.combo()

        _creation(stomping_creation)

        result = {
            result = true, 
            jumping_min = stomping_player_jumping_min, 
            jumping_max = stomping_player_jumping_max
        }
    elif stomping_hurtable:
        if by is Player && by.is_invincible(): return result
        stomped_failed.emit()
        result = {result = false}

    return result





func got_killed(by: StringName, special_tags: Array = [], trigger_killed_failed: bool = true)->Dictionary:
    var result: Dictionary

    if !killing_enabled || (by != &"self" && !by in killing_immune) || _on_killed:
        return result

    _on_killed = true
    var shell_attack: = false


    if by != &"self" && killing_immune[by]:
        if trigger_killed_failed:
            killed_failed.emit()

        result = {
            result = false, 
            attackee = self
        }

    elif &"freezible" in special_tags && frozen_enabled:
        var _add_pos = Vector2.ZERO
        if is_instance_valid(_ice_sprite):
            _add_pos = _ice_sprite.position

        var ice: = NodeCreator.prepare_2d(load(ICEBLOCK_PATH), _center).create_2d().get_node() as PhysicsBody2D


        ice.ready.connect(ice.move_and_collide.bind(Vector2.DOWN.rotated(ice.global_rotation)))
        (func ()->void :
            ice.global_transform = _center.global_transform.translated_local(_add_pos)
            ice.unfreeze_offset = - _add_pos
            ice.destroy_enabled = true
            ice.contained_item = _center
            ice.contained_item_enemy_killed = self
            ice.forced_heavy_break = ice_fragile

            var in_ice_spr: Node2D = null
            if is_instance_valid(_ice_sprite):
                in_ice_spr = _ice_sprite.duplicate()
            ice.draw_sprite(in_ice_spr, ice_sprite_offset)

            _center.get_parent().remove_child(_center)
        ).call_deferred()

        result = {
            result = true, 
            attackee = self
        }

        killed_frozen.emit()

    else:

        if &"shell_attack" in special_tags:
            shell_attack = true

        killed_succeeded.emit()

        _creation(killing_creation)

        var no_score: bool = &"no_score" in special_tags
        if killing_scores > 0 && !no_score:
            ScoreText.new(str(killing_scores), _center)
            Data.values.score += killing_scores

        result = {
            result = true, 
            attackee = self
        }

        if shell_attack:
            result.type = &"shell"


    get_tree().physics_frame.connect(func ():
        _on_killed = false
    , CONNECT_ONE_SHOT)

    return result


func _creation(creation: InstanceNode2D)->void :
    if !creation: return 

    var vars: Dictionary = {
        enemy_attacked = self, 
    }
    NodeCreator.prepare_ins_2d(creation, _center).execute_instance_script(vars).create_2d()


func stomping_delay()->void :
    _stomping_delayer = get_tree().create_timer(get_physics_process_delta_time() * stomping_delay_frames)
    _stomping_delayer.timeout.connect(
        func ()->void :
            _stomping_delayer = null
    )


func get_stomping_delayer()->SceneTreeTimer:
    return _stomping_delayer


func _on_level_end()->void :
    if !killing_enabled: return 
    if !Thunder.view.is_getting_closer(_center, 32):
        if Thunder.view.is_getting_closer(_center, 320):
            _center.queue_free.call_deferred()
        return 
    Audio.play_1d_sound(COIN)
    NodeCreator.prepare_2d(COIN_EFFECT, _center).bind_global_transform().create_2d().call_method(func (node):
        node.score_given = 1000
        node.global_rotation = 0
    )
    Data.add_coin()
    _center.queue_free.call_deferred()
