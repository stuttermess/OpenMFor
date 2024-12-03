extends RefCounted
class_name NodeCreator







static func _instantiate_2d(pck: PackedScene)->Node2D:
    if !pck: return null
    var node: Node2D = pck.instantiate() as Node2D
    return node



static func prepare_2d(pck: PackedScene, on: Node2D)->NodeCreation:
    if !pck || !on: return NodeCreation.new(null, null)

    var ins: Node2D = _instantiate_2d(pck)
    if !ins: return NodeCreation.new(null, on)

    return NodeCreation.new(ins, on)



static func prepare_ins_2d(ins2d: InstanceNode2D, on: Node2D)->NodeCreation:
    if !ins2d || !on || !ins2d.creation_nodepack: return NodeCreation.new(null, null)

    var ins: Node2D = _instantiate_2d(ins2d.creation_nodepack)
    if !ins: return NodeCreation.new(null, on)

    return NodeCreation.new(ins, on, ins2d)



class NodeCreation extends RefCounted:
    var _node: Node2D
    var _on: Node2D
    var _ins2d: InstanceNode2D


    func _init(node: Node2D, on: Node2D, ins2d: InstanceNode2D = null)->void :
        _node = node
        _on = on
        _ins2d = ins2d



    func get_node()->Node2D:
        return _node




    func call_method(method: Callable, reset_interp_after_call = true)->NodeCreation:
        if !_node: return self
        if method: method.call(_node)
        if reset_interp_after_call: _node.reset_physics_interpolation()
        return self



    func execute_script(custom_script: GDScript, custom_vars: Dictionary = {})->NodeCreation:
        if !_node || !custom_script: return self
        var _scr: Script = ByNodeScript.activate_script(custom_script, _node, custom_vars)
        return self




    func execute_instance_script(custom_vars: Dictionary = {}, which_method: StringName = &"")->NodeCreation:
        if !_node || !_ins2d.custom_script: return self
        var vars: Dictionary = custom_vars
        vars.merge(_ins2d.custom_vars)
        var scr: Script = ByNodeScript.activate_script(_ins2d.custom_script, _node, vars)
        if which_method in scr.get_script_method_list(): scr.call(which_method)
        return self






    func bind_global_transform(offset: Vector2 = Vector2.ZERO, rot: float = 0, scl: Vector2 = Vector2.ONE, skew: float = 0)->NodeCreation:
        if !_node || !_on: return self
        _node.global_rotation = _on.global_rotation + rot
        _node.global_scale = _on.global_scale * scl
        _node.global_position = _on.global_position
        _node.translate(offset)
        _node.global_skew = _on.global_skew + skew
        _node.reset_physics_interpolation()
        return self






    func create_2d(as_sibling: bool = false, ins2d: InstanceNode2D = null)->NodeCreation:
        if !_node: return self

        if as_sibling:
            _on.add_sibling(_node)
        elif Scenes.current_scene:
            Scenes.current_scene.add_child(_node)

        if ins2d:
            _ins2d = ins2d
        if !_ins2d:
            return self

        _node.global_position = _on.global_transform.translated_local(_ins2d.trans_offset).get_origin()
        _node.global_rotation = _ins2d.trans_rotation
        _node.global_scale = _ins2d.trans_scale
        _node.global_skew = _ins2d.trans_skew

        _node.z_index = _ins2d.visi_z_index
        _node.z_as_relative = _ins2d.visi_z_as_relative
        _node.y_sort_enabled = _ins2d.visi_y_sort_enabled

        if _ins2d.trans_inheritances & 1 == 1:
            _node.global_rotation += _on.global_rotation
        if _ins2d.trans_inheritances & 10 == 10:
            _node.global_scale *= _on.global_scale
        if _ins2d.trans_inheritances & 100 == 100:
            _node.global_skew += _on.global_skew

        _node.reset_physics_interpolation()

        return self
