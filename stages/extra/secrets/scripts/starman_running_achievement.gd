extends Node

func check_secret()->void :
    if floor(Data.values.time) >= 70000:
        get_parent().unlock_secret()
