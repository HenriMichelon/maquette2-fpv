class_name Usable extends StaticBody3D

signal using(is_used:bool)
signal unlock(success:bool)

@export var label:String
@export var title:String

var save:bool
var is_used:bool = false
var unlocked:bool = false
var _animation:AnimationPlayer

func _init(_save:bool = true):
	save = _save

func _ready():
	set_collision_layer_value(Consts.LAYER_USABLE, true)
	if (label == null): 
		label = get_path()
	var text = get_node("Top/Text")
	if text != null:
		text.text = title
	_animation = find_child("AnimationPlayer")
	if (_animation != null):
		_animation.connect("animation_finished", _on_animation_finished)

func _check_item_use(message_locked:String, message_unlocked:String, tools_to_use:Array) -> bool:
	if (unlocked): return true
	var check = false
	if (GameState.current_item != null):
		for tool in tools_to_use:
			if (tool[0] == GameState.current_item.type) and (tool[1] == GameState.current_item.key):
				unlocked = true
				NotificationManager.notif(message_unlocked)
				unlock.emit(true)
				return true
	NotificationManager.notif(message_locked)
	unlock.emit(false)
	return check
	
func _check_use():
	if (GameState.current_item != null):
		unlock.emit(false)
		return false
	return true

func force_use():
	is_used = true
	if (_animation != null):
		_animation.play("use")
		_animation.seek(10)
	else:
		_use()
		using.emit(is_used)

func use(_byplayer:bool=false, startup:bool=false):
	if (not is_used):
		if (not startup and not _check_use()) :
			return
	is_used = !is_used
	if (is_used):
		if (_animation != null):
			_animation.play("use")
			if (startup): 
				_animation.seek(10)
		else:
			_use()
			using.emit(is_used)
	else:
		if (_animation != null): 
			_animation.play_backwards("use")
			if (startup): 
				_animation.seek(10)
		else:
			_unuse()
			using.emit(is_used)

func _on_animation_finished(anim_name:String):
	if (anim_name == "use"):
		_use()
		using.emit(is_used)
	else:
		_unuse()
		using.emit(is_used)

func _use():
	pass

func _unuse():
	pass

func _to_string():
	return label
