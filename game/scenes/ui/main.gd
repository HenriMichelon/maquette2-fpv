class_name MainUI extends Control

@export var player:Player

@onready var label_saving:Label = $LabelSaving
@onready var time_saving:Timer = $LabelSaving/Timer
@onready var label_info:Label = $HUD/LabelInfo
@onready var panel_info:Label = $HUD/LabelInfo
@onready var focused_button:Button = $Menu/MainMenu/ButtonInventory
@onready var label_notif:Label = $HUD/LabelNotification
@onready var timer_notif:Timer = $HUD/LabelNotification/Timer
@onready var icon_menu_open = $HUD/MenuIcon
@onready var icon_menu_close = $MenuIcon
@onready var icon_use = $HUD/LabelInfo/Icon
@onready var button_iventory = $Menu/MainMenu/ButtonInventory
@onready var button_terminal = $Menu/MainMenu/ButtonTerminal
@onready var panel_item = $HUD/PanelTool
@onready var menu = $Menu
@onready var hud = $HUD
@onready var blur = $Blur

var _displayed_node:Node
var _restart_timer_notif:bool = false
var _talk_screen:Dialog
var _trade_screen:Dialog

func _ready():
	blur.visible = false
	label_saving.visible = false
	panel_info.visible = false
	menu.visible = false
	label_notif.visible = false
	icon_menu_close.visible = false
	panel_item.visible = false
	GameState.connect("saving_start", _on_saving_start)
	GameState.connect("saving_end", _on_saving_end)
	player.interactions.connect("display_info", _on_display_info)
	player.interactions.connect("hide_info", hide_info)
	Input.connect("joy_connection_changed", _on_joypad_connection_changed)
	set_shortcuts()

func set_shortcuts():
	panel_item.set_shortcuts()
	Tools.set_shortcut_icon(icon_use, Tools.SHORTCUT_USE)
	Tools.set_shortcut_icon(icon_menu_open, Tools.SHORTCUT_MENU)
	Tools.set_shortcut_icon(icon_menu_close, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_iventory, Tools.SHORTCUT_INVENTORY)
	Tools.set_shortcut_icon(button_terminal, Tools.SHORTCUT_TERMINAL)

func _on_joypad_connection_changed(_id, connected):
	GameState.use_joypad = connected
	set_shortcuts()
	Dialog.refresh_shortcuts()

func _input(event):
	if (not Dialog.dialogs_stack.is_empty()) or Dialog.ignore_input(): return
	if (label_info.visible):
		if (event is InputEventMouseMotion) or (Input.is_action_pressed("look_left") or (Input.is_action_pressed("look_right"))):
			_label_info_position()
			return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if (Input.is_action_just_released("menu") and not menu.visible):
			menu_open()
		elif (Input.is_action_just_released("cancel") and menu.visible):
			menu_close()
		elif (Input.is_action_just_released("quit")):
			_on_save_before_quit_confirm(true)
		elif Input.is_action_just_released("inventory"):
			inventory_open()
		elif  Input.is_action_just_released("terminal"):
			terminal_open()
		elif  Input.is_action_just_released("unuse"):
			GameState.item_unuse()

func pause_game():
	if (not timer_notif.is_stopped()):
		timer_notif.stop()
		_restart_timer_notif = true
	hud.visible = false
	blur.visible = true

func resume_game(_dummy=null):
	hud.visible = true
	blur.visible = false
	if( _restart_timer_notif):
		timer_notif.start()
		_restart_timer_notif = false

func menu_open():
	GameState.pause_game()
	menu.visible = true
	icon_menu_close.visible = true
	icon_menu_open.visible = false
	focused_button.grab_focus()

func menu_close(_dummy=null):
	menu.visible = false
	icon_menu_close.visible = false
	icon_menu_open.visible = true
	GameState.resume_game()
	
func npc_talk(_char:InteractiveCharacter, phrase:String, answers:Array):
	if (_talk_screen != null and _talk_screen.trading): return
	if (_talk_screen == null):
		_talk_screen = Tools.load_screen(self, Tools.SCREEN_NPC_TALK)
		_talk_screen.open(_char)
	_talk_screen.talk(phrase, answers)

func npc_end_talk():
	if (_talk_screen != null):
		_talk_screen.close()
		_talk_screen = null

func npc_trade(_char:InteractiveCharacter):
	if (_talk_screen.trading): return
	_talk_screen.trading = true
	_trade_screen = Tools.load_screen(self, Tools.SCREEN_NPC_TRADE)
	_trade_screen.open(_char, npc_trade_end)

func npc_trade_end():
	_talk_screen.trading = false
	_talk_screen.player_text_list.grab_focus()

func storage_open(node:Storage, on_storage_close:Callable):
	var dlg = Tools.load_dialog(self, Tools.DIALOG_TRANSFERT_ITEMS, resume_game)
	dlg.open(node, on_storage_close)

func inventory_open():
	var dlg = Tools.load_screen(self, Tools.SCREEN_INVENTORY, menu_close)
	dlg.open()
	
func terminal_open():
	var dlg = Tools.load_screen(self, Tools.SCREEN_TERMINAL, menu_close)
	dlg.open()
	_on_timer_notif_timeout()

func load_savegame_open():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_LOAD_SAVEGAME, menu_close)
	dlg.open(_on_load_savegame)

func settings_open():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_SETTINGS, menu_close)
	dlg.open()

func savegame_open():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_INPUT)
	dlg.open("Save game", StateSaver.get_last_savegame(), _on_savegame_input)

func display_keymaps():
	var dlg = Tools.load_screen(self, Tools.SCREEN_CONTROLLER, menu_close)
	dlg.open()

func display_notification(message:String):
	timer_notif.stop()
	label_notif.text = message
	label_notif.visible = true
	timer_notif.start()

func _on_load_savegame(savegame:String):
	menu.visible = false
	GameState.load_game(savegame)
	get_tree().reload_current_scene()
	
func _on_savegame_input(savegame):
	if (savegame != null):
		if (StateSaver.savegame_exists(savegame)):
			GameState.savegame_name = savegame
			var dlg = Tools.load_dialog(self, Tools.DIALOG_CONFIRM, menu_close)
			dlg.open("Save game", "Overwrite existing save?", _on_savegame_confirm)
		else:
			GameState.save_game(savegame)
			menu_close()

func _on_savegame_confirm(overwrite:bool):
	if (overwrite):
		GameState.save_game(GameState.savegame_name)
		menu_close()

func _on_saving_start():
	label_saving.visible = true

func _on_saving_end():
	time_saving.start()

func _on_saving_timer_timeout():
	label_saving.visible = false
	
func _label_info_position():
	var pos:Vector3 = _displayed_node.global_position
	#pos.y = player.global_position.y + 1.5
	panel_info.position = player.camera.unproject_position(pos)
	label_info.position.y = (size.y - label_info.size.y)/2
	
func _on_display_info(node:Node3D):
	_displayed_node = node
	var label:String = tr(str(_displayed_node))
	if (label.is_empty()): 
		label = str(node)
	label_info.text = label
	_label_info_position()
	panel_info.visible = true

func hide_info():
	panel_info.visible = false
	label_info.text = ''

func _on_button_quit_pressed():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_CONFIRM, menu_close)
	dlg.open("Save ?", "Save game before exiting ?", _on_save_before_quit_confirm)

func _on_save_before_quit_confirm(save:bool):
	if (save): 
		GameState.save_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().quit()

func _on_timer_notif_timeout():
	label_notif.visible = false
