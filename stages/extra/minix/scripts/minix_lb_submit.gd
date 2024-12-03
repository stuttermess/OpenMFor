extends MenuSelection

@onready var please_type: Node2D = $"../../PleaseType"
@onready var input_box: Node2D = $"../../PleaseType/InputBox"
@onready var line_edit: LineEdit = $"../../PleaseType/InputBox/LineEdit"
@onready var enter_to_preview: Label = $"../../PleaseType/EnterToPreview"

@onready var leaderboard: Node2D = $"../../../Leaderboard"
@onready var http_request: HTTPRequest = $"../../PleaseType/HTTPRequest"
@onready var url = leaderboard.url
@onready var loading: Label = $"../../PleaseType/Submitting/Loading"
@onready var congrats: Label = $"../../PleaseType/Submitting/congrats"
@onready var submitting_box: Node2D = $"../../PleaseType/Submitting"

@onready var minix_controls: MenuItemsController = $".."
@onready var starter: Node2D = $"../../../Node2D"

const SUBMITTED = preload("res://stages/extra/minix/sfx/submitted.wav")

var is_enabled: bool = true
var submitting = false
var has_errored: bool = false
var dufhdiufsfdoi: bool

func _handle_select(mouse_input: bool = false)->void :
    if !is_enabled:
        if congrats.visible && please_type.visible:
            super ()
            please_type.visible = false
            return 
        Audio.play_1d_sound(preload("res://stages/extra/minix/status/minix_coin_time.wav"))
        return 
    super (mouse_input)
    minix_controls.focused = false
    please_type.visible = true
    submitting_box.visible = false
    input_box.visible = true
    line_edit.text = ""
    line_edit.grab_focus()
    line_edit.focus_exited.connect(_on_line_edit_focus_exited, CONNECT_ONE_SHOT)

func _physics_process(delta: float)->void :
    super (delta)
    if !focused: return 

    if submitting:
        submitting_box.visible = true
        input_box.visible = false
        loading.text = "submitting your score..."
        loading.remove_theme_color_override("font_color")
        return 

    if !please_type.visible: return 

    if Input.is_action_just_pressed("ui_cancel") || (enter_to_preview.text == "press enter to continue" && Input.is_action_just_pressed("ui_accept")):
        _on_line_edit_focus_exited()
        Thunder._disconnect(line_edit.focus_exited, _on_line_edit_focus_exited)
        Audio.play_1d_sound(selected_sound, true, {ignore_pause = true})
        dufhdiufsfdoi = false

    if dufhdiufsfdoi: return 

    var can_submit: bool = false
    var regex = RegEx.new()
    regex.compile("[^A-Za-z0-9\\ _\\-.\\(\\)\\&']")
    if len(line_edit.text) > 2 && !regex.search(line_edit.text):
        can_submit = true

    enter_to_preview.visible = can_submit
    enter_to_preview.text = "Press enter to submit score!"

    if !is_enabled:
        add_theme_color_override("font_color", Color("c7aaa1"))
        return 

    if can_submit && !submitting && Input.is_action_just_pressed("ui_accept"):
        Audio.play_1d_sound(selected_sound)
        Thunder._disconnect(line_edit.focus_exited, _on_line_edit_focus_exited)
        line_edit.release_focus()

        var data = {
            "score": Data.values.score, 
            "godlikes": Data.values.godlikes, 
            "time": int(Data.values.lasted), 
            "version": 2, 
            "map": starter.map_names[starter.map_id], 
            "username": line_edit.text, 
            "game": "MINIX"
        }
        var headers = ["Content-Type: application/json"]
        http_request.request_completed.connect(_on_http_submit, CONNECT_ONE_SHOT)
        print(JSON.stringify(data))
        http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))
        submitting = true
        is_enabled = false
        line_edit.text = ""
        enter_to_preview.visible = false


func _on_http_submit(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray)->void :
    print(body.get_string_from_utf8())
    submitting = false

    dufhdiufsfdoi = true
    enter_to_preview.text = "press enter to continue"
    enter_to_preview.visible = true

    if response_code != 201:
        loading.text = "error submitting your score!"
        loading.add_theme_color_override("font_color", Color(1, 0.5649999999999999, 0.5649999999999999))
        has_errored = true

        is_enabled = true
        return 

    Audio.play_1d_sound(SUBMITTED)

    congrats.visible = true
    loading.visible = false


func _on_line_edit_focus_exited()->void :
    minix_controls.focused = true
    please_type.visible = false
    has_errored = false
