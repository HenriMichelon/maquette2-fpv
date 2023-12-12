extends Control

@onready var button_quit:Button = $Menu/ButtonQuit
@onready var button_continue:Button = $Menu/ButtonContinue
@onready var button_settings:Button = $Menu/ButtonSettings
@onready var button_input:Button = $Menu/ButtonController
@onready var button_new:Button = $Menu/ButtonNew
@onready var menu = $Menu

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.game_started = false
	GameState.prepare_game(false)
	Tools.preload_zone(GameState.player_state.zone_name)
	Input.connect("joy_connection_changed", _on_joypad_connection_changed)
	if (StateSaver.get_savegames().is_empty()):
		button_continue.disabled = true
		button_new.grab_focus()
	else:
		button_continue.grab_focus()

func _on_resized():
	if (menu != null):
		var vsize = get_viewport().size / get_viewport().content_scale_factor
		menu.position.x = vsize.x - (vsize.x / 4) - menu.size.x
		menu.position.y = (vsize.y -  menu.size.y) / 2

func _on_joypad_connection_changed(_id, connected):
	Dialog.refresh_shortcuts()

func _menu_disable():
	for n in menu.get_children(): 
		n.disabled = true
		n.focus_mode = FOCUS_NONE
	
func _menu_enable():
	for n in menu.get_children(): 
		n.disabled = false
		n.focus_mode = FOCUS_ALL

func _on_button_settings_pressed():
	_menu_disable()
	var dlg = Tools.load_dialog(self, Tools.DIALOG_SETTINGS, _on_settings_closed)
	dlg.open()

func _on_settings_closed():
	button_settings.grab_focus()
	_menu_enable()

func _on_button_controller_pressed():
	_menu_disable()
	var dlg = Tools.load_screen(self, Tools.SCREEN_CONTROLLER, _on_controller_closed)
	dlg.open()

func _on_controller_closed():
	button_input.grab_focus()
	_menu_enable()

func _on_button_quit_pressed():
	get_tree().quit()

func _on_button_continue_pressed():
	GameState.prepare_game(true)
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_button_new_pressed():
	_menu_disable()
	var dlg = Tools.load_dialog(self, Tools.DIALOG_PLAYER_SETUP, _on_new_closed)
	dlg.open()

func _on_new_closed():
	button_new.grab_focus()
	_menu_enable()

func _on_button_continue_focus_entered():
	Tools.set_shortcut_icon(button_continue, Tools.SHORTCUT_ACCEPT)

func _on_button_new_focus_entered():
	Tools.set_shortcut_icon(button_new, Tools.SHORTCUT_ACCEPT)

func _on_button_settings_focus_entered():
	Tools.set_shortcut_icon(button_settings, Tools.SHORTCUT_ACCEPT)

func _on_button_quit_focus_entered():
	Tools.set_shortcut_icon(button_quit, Tools.SHORTCUT_ACCEPT)

func _on_button_quit_focus_exited():
	Tools.reset_shortcut_icon(button_quit)

func _on_button_settings_focus_exited():
	Tools.reset_shortcut_icon(button_settings)

func _on_button_new_focus_exited():
	Tools.reset_shortcut_icon(button_new)

func _on_button_continue_focus_exited():
	Tools.reset_shortcut_icon(button_continue)

func _on_button_controller_focus_entered():
	Tools.set_shortcut_icon(button_input, Tools.SHORTCUT_ACCEPT)

func _on_button_controller_focus_exited():
	Tools.reset_shortcut_icon(button_input)
