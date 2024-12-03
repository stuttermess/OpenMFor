extends Node

var current_skin: String = ""

var base_dir: String = OS.get_executable_path().get_base_dir() + "/skins"

var custom_textures: Dictionary
var custom_sprite_frames: Dictionary
var skins: Dictionary
var misc_textures: Dictionary
var misc_sounds: Dictionary
var custom_nicknames: Dictionary

@onready var base_sprite_frames: SpriteFrames = preload("res://engine/objects/players/prefabs/animations/mario/animation_mario_super.tres")
@onready var animation_list: PackedStringArray = base_sprite_frames.get_animation_names()

func _init()->void :
    var tex: Dictionary = load_external_textures()

    if tex.is_empty(): return 
    custom_textures = tex


func _ready()->void :
    current_skin = SettingsManager.settings.skin
    SettingsManager.settings_updated.connect(_update_current_skin_from_settings)







func _update_current_skin_from_settings()->void :
    current_skin = SettingsManager.settings.skin


func apply_player_skin(_suit)->SpriteFrames:
    if SkinsManager.custom_sprite_frames.has(SkinsManager.current_skin):
        return SkinsManager.get_custom_sprite_frames(_suit.animation_sprites, SkinsManager.current_skin, _suit.name)
    return _suit.animation_sprites


func load_external_textures()->Dictionary:
    print(base_dir)

    if !DirAccess.dir_exists_absolute(base_dir):
        print("Skipped loading custom textures")
        return {}

    var dir_access = DirAccess.open(base_dir)
    if !dir_access:
        return {}

    custom_sprite_frames = {}
    skins = {}
    misc_textures = {}
    misc_sounds = {}
    custom_nicknames = {}
    var loaded: Dictionary = {}
    var directories: PackedStringArray = DirAccess.get_directories_at(base_dir)

    for i in directories:
        dir_access.change_dir(base_dir + "/" + i)
        misc_textures[i] = {}
        misc_sounds[i] = {}
        custom_nicknames[i] = i.left(15)
        _load_misc_files(dir_access, i)


        var _anims: PackedStringArray = DirAccess.get_directories_at(base_dir + "/" + i)
        custom_sprite_frames[i] = {}
        skins[i] = {}
        print(i, " Anims: ", _anims)
        loaded[i] = _load_animations(dir_access, i, _anims)


        var comp_1: = PackedStringArray(skins[i].keys())
        comp_1.sort()
        var comp_2: = _anims
        comp_2.sort()
        if comp_1 != comp_2:
            print("[Skins Manager] ALERT! For ", i, ", Some animations have not been loaded properly!\n  Found: ", comp_2, "\n  Loaded without errors: ", comp_1)


    dir_access.list_dir_end()
    return loaded


func _load_misc_files(dir_access: DirAccess, i: String):
    var _misc_files: PackedStringArray = dir_access.get_files()
    for j in _misc_files:
        var file_path: String = base_dir + "/" + i + "/" + j
        var is_array: bool = j.get_basename().left(-1).ends_with("_") && j.get_basename().right(1).is_valid_int()
        var file_ext: String = j.get_extension().to_lower()
        if !file_ext in ["png", "ogg", "txt"]:
            continue

        var arrayed_filename: String = j.get_basename().left(-2)
        if is_array && !arrayed_filename in misc_textures[i]:
            misc_textures[i][arrayed_filename] = []
        if is_array && !arrayed_filename in misc_sounds[i]:
            misc_sounds[i][arrayed_filename] = []
        if file_ext == "png":
            var img: Image = Image.load_from_file(file_path)
            var file: = ImageTexture.create_from_image(img)
            if is_array:
                misc_textures[i][arrayed_filename].append(file)
            else:
                misc_textures[i][j.get_basename()] = file

        elif file_ext == "ogg":
            var file = AudioStreamOggVorbis.load_from_file(file_path)
            if is_array:
                misc_sounds[i][arrayed_filename].append(file)
            else:
                misc_sounds[i][j.get_basename()] = file

        elif file_ext == "txt" && j.get_basename().to_lower() == "name":
            var file = FileAccess.open(file_path, FileAccess.READ)
            custom_nicknames[i] = file.get_line().left(15)
            print(i, " Custom nick: ", custom_nicknames[i])
            file.close()


func _load_animations(dir_access: DirAccess, i: String, _anims: PackedStringArray):
    var loaded: Dictionary = {}
    loaded = {}
    for j in _anims:
        var file_path: String = base_dir + "/" + i + "/" + j
        dir_access.change_dir(file_path)
        dir_access.list_dir_begin()
        if !dir_access.file_exists(file_path + "/skin_settings.tres"):
            print("No skin settings found at " + file_path + ". Skipping")
            continue
        var file_name: String = dir_access.get_next()
        loaded[j] = {}

        while file_name != "":
            var file_ext: String = file_name.get_extension().to_lower()

            if !dir_access.current_is_dir() && file_ext == "png":
                var texture_name: String = file_name.trim_suffix("." + file_ext)

                var file: Image = Image.load_from_file(file_path + "/" + file_name)
                var file_texture: ImageTexture = ImageTexture.create_from_image(file)

                loaded[j][texture_name] = file_texture

            elif !dir_access.current_is_dir() && file_name == "skin_settings.tres":
                var _skin = ResourceLoader.load(file_path + "/skin_settings.tres", "Resource", ResourceLoader.CACHE_MODE_REPLACE)
                if (
                    !_skin || !"animation_regions" in _skin || 
                    !"animation_loops" in _skin || 
                    !"animation_speeds" in _skin || 
                    !"name" in _skin
                ):
                    OS.alert(file_path + "/skin_settings.tres is invalid.", "Player Skin Load Error")
                    file_name = dir_access.get_next()
                    continue

                skins[i][_skin.name] = _skin

            file_name = dir_access.get_next()
    return loaded


func get_custom_sprite_frames(old_sprites: SpriteFrames, skin_name: String, power: String)->SpriteFrames:
    var custom_tex: Dictionary = {}


    if custom_sprite_frames.has(skin_name) && custom_sprite_frames[skin_name].has(power):
        return custom_sprite_frames[skin_name][power]


    if custom_textures[skin_name].has(power):
        custom_tex = custom_textures[skin_name][power]


    var new_sprites: SpriteFrames = new_custom_sprite_frames(old_sprites, custom_tex, power)
    if !skin_name in custom_sprite_frames:
        custom_sprite_frames[skin_name] = {}
    custom_sprite_frames[skin_name][power] = new_sprites
    if new_sprites:
        return new_sprites


    push_warning("[Skins Manager] Textures for power \"%s\" do not exist." % power)
    return old_sprites







func new_custom_sprite_frames(old_sprites: SpriteFrames, textures: Dictionary, power: String)->SpriteFrames:
    if !old_sprites: return null
    if textures.is_empty(): return old_sprites
    if !current_skin in skins || !power in skins[current_skin]: return old_sprites

    var new_sprites: = SpriteFrames.new()
    var _regions: Dictionary = skins[current_skin][power].animation_regions
    for anim in old_sprites.get_animation_names():
        if anim != "default":
            new_sprites.add_animation(anim)
        new_sprites.set_animation_speed(anim, skins[current_skin][power].animation_speeds[anim])
        new_sprites.set_animation_loop(anim, skins[current_skin][power].animation_loops[anim])
        var frame_count = old_sprites.get_frame_count(anim)
        if len(_regions[anim]) > 0:
            frame_count = len(_regions[anim])

        for frame in frame_count:
            var tex = old_sprites.get_frame_texture(anim, frame)
            var new_tex: = AtlasTexture.new()
            if anim in textures:
                new_tex.atlas = textures[anim]
                var _region: Rect2 = tex.region if tex else Rect2()
                if len(_regions[anim]) > 0:
                    _region = _regions[anim][frame]

                new_tex.region = _region
            else:
                new_tex = tex
            new_sprites.add_frame(anim, new_tex)


    return new_sprites
