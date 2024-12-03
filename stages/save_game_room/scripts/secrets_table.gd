extends VBoxContainer

signal all_achievements_done

@onready var children = get_children()

func _ready()->void :
    if SecretsManager.secrets.is_empty():
        return 

    var not_done: bool = false

    for achievement in children:
        var toggler: Label
        var labels = achievement.get_children()
        for i in len(labels):
            if !labels[i] is Label:

                continue
            if i == 1:
                toggler = labels[i]
                break

        var secr = SecretsManager.secrets.get(achievement.secret_id)
        if typeof(secr) == TYPE_BOOL && secr == true:
            toggle_yes(toggler)
        elif typeof(secr) == TYPE_ARRAY && len(secr) >= achievement.progress_to:
            toggle_yes(toggler)
        else:
            not_done = true
            if typeof(secr) == TYPE_ARRAY && len(secr) > 0:
                toggler.text = "no, %d" % len(secr)

    if !not_done:
        all_achievements_done.emit()


func toggle_yes(label: Label)->void :
    label.text = "yes"
    label.add_theme_color_override("font_color", Color("a8a0f8"))
