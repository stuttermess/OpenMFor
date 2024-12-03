extends Node

@export_category("Unlock Achievement")
@export var secrets: Array[String] = [""]
@export var show_toast: bool = true
@export_category("Progress Achievement")
@export var progress_by_id: String
@export var progress_to: int

func unlock_secret(id: int = 0)->void :
    if id < len(secrets):
        if secrets[id].is_empty(): return 
        SecretsManager.set_secret(secrets[id], true, true, show_toast)


func unlock_with_kevin(id: int = 0)->void :
    if id < len(secrets):
        if secrets[id].is_empty(): return 
        if !KevinGlobal.activated:
            print("[Secrets] ID %d check failed (secret mode)" % [id])
            return 
        SecretsManager.set_secret(secrets[id], true, true, show_toast)



func unlock_if(conditions: PackedStringArray, id: int = 0)->void :
    for i in conditions:
        if ProfileManager.current_profile.data.has(i):
            print("[Secrets] ID %d check failed (contains %s)" % [id, i])
            return 
    unlock_secret(id)


func unlock_with_kevin_if(conditions: PackedStringArray, id: int = 0)->void :
    if !KevinGlobal.activated:
        print("[Secrets] ID %d check failed (secret mode and conditions)" % [id])
        return 
    unlock_if(conditions, id)


func progress_secret(id: int = 0)->void :
    var new_secret = SecretsManager.get_secret(secrets[id])
    if typeof(new_secret) == TYPE_BOOL && new_secret == true:
        print("[Secrets] ID %d has already been completed" % id)
        return 
    if new_secret == null:
        new_secret = []
    if new_secret.has(progress_by_id):
        print("[Secrets] ID %d already has %s" % [id, progress_by_id])
        return 
    new_secret.append(progress_by_id)

    if len(new_secret) >= progress_to:
        SecretsManager.set_secret(secrets[id], true, false, true)
        print("[Secrets] ID %d has been completed! total %d" % [id, progress_to])
        return 
    SecretsManager.set_secret(secrets[id], new_secret, true, false)
    print("[Secrets] ID %d progressed with %s out of total %d" % [id, progress_by_id, progress_to])


func add_shit_to_profile(data: String, value: bool = true)->void :
    ProfileManager.current_profile.data[data] = value
