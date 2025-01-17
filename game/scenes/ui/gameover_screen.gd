extends Dialog

@onready var label = $Panel/Label

func open():
	super._open()
	var ratio = size.x / size.y
	var vsize = get_viewport().size / get_viewport().content_scale_factor
	size.x = vsize.x / 1.2
	size.y = size.x / ratio
	position.x = (vsize.x - size.x) / 2
	position.y = (vsize.y - size.y) / 2
	label.text = tr(" You died !") if GameState.player_state.sex else tr("You died !")
	
func _input(event):
	if Input.is_action_just_released("cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
