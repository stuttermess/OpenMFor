class_name Command

enum Error{
    OK = -1, 
    Unknown = 0, 
    Param = 1, 
    Wrong = 2, 
}

class ExecuteResult:
    var msg: Variant
    var err: Error
    @warning_ignore("shadowed_variable", "shadowed_variable")
    func _init(msg, err = Error.OK):
        self.msg = msg
        self.err = err


const messages: Dictionary = {
    Error.Unknown: "[color=red]Unknown Error[/color]", 
    Error.Param: "[color=red]Invalid Arguments[/color]", 
    Error.Wrong: "[color=red]Something Went Wrong[/color]"
}

const NIY: String = "Not Implemented Yet"


var name: StringName = "null"
var params: Dictionary = {}
var description: String = NIY
var debug_only: bool



func try_execute(args: Array)->Variant:
    var arg_count: int = 0
    for k in params.keys():
        if !params[k].optional:
            arg_count += 1

    if args.size() < arg_count:
        return messages[Error.Param]





    var res: ExecuteResult = execute(args)

    if res.err != Error.OK:
        return messages[res.err]

    return res.msg


func get_help()->String:
    var result: String = ":"

    if params.is_empty():
        result = ""
    else:
        for k in params.keys():
            var opt: bool = params[k].optional
            var opening: String = "aqua][" if opt else "deep_sky_blue]<"
            var closing: String = "]" if opt else ">"
            result += " [color=%s%s: %s%s[/color]" % [
                opening, k, type_string(params[k].type), closing
            ]

    result += " - %s" % description

    return result


static func register()->Command:
    return null


func execute(args: Array)->ExecuteResult:
    return ExecuteResult.new(NIY)

func set_description(desc: String)->Command:
    description = desc
    return self

func add_param(key: String, val: int, _optional: bool = false)->Command:
    params[key] = {
        type = val, 
        optional = _optional
    }
    return self

@warning_ignore("shadowed_variable")
func set_name(name: String)->Command:
    self.name = name
    return self

func set_debug()->Command:
    if OS.has_feature("template"):
        debug_only = true
    return self
