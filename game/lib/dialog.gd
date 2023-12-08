class_name Dialog extends Control

var _on_close = null

static var dialogs_stack:Array[Dialog] = []
static var _ignore_input:bool = false

func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED

func _open(blur_screen:bool=true):
	if (dialogs_stack.is_empty()):
		GameState.pause_game(blur_screen)
	else:
		dialogs_stack.back().process_mode = PROCESS_MODE_DISABLED
	dialogs_stack.push_back(self)

func close():
	dialogs_stack.pop_back()
	if (dialogs_stack.is_empty()):
		GameState.resume_game()
	else:
		dialogs_stack.back().process_mode = PROCESS_MODE_WHEN_PAUSED
	_ignore_input = true
	queue_free()
	if (_on_close != null):
		_on_close.call()

func ignore_input() -> bool:
	var ignore = _ignore_input
	_ignore_input = false
	return ignore
