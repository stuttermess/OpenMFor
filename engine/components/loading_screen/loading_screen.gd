extends Control

@export var scene: String

var loading_status: int
var progress: Array[float]

@onready var progress_bar: ProgressBar = $ProgressBar

func _ready()->void :

    ResourceLoader.load_threaded_request(scene)

func _process(_delta: float)->void :

    loading_status = ResourceLoader.load_threaded_get_status(scene, progress)


    match loading_status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            progress_bar.value = progress[0] * 100.0
        ResourceLoader.THREAD_LOAD_LOADED:


            Scenes.load_scene_from_packed.call_deferred(ResourceLoader.load_threaded_get(scene))
        ResourceLoader.THREAD_LOAD_FAILED:

            print("Error. Could not load Resource")
