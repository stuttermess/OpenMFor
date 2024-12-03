extends MenuSelection

func _handle_select(mouse_input: bool = false)->void :



    super (mouse_input)
    GlobalViewport.vp.get_camera_2d().position.x += 640
    GlobalViewport.vp.get_camera_2d().reset_physics_interpolation()
    await get_tree().physics_frame
    Scenes.current_scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
    Scenes.current_scene.get_node("Controls/Options").focused = true
