extends Node

signal saving_start()
signal saving_end()
signal loading_start()
signal loading_end()

var player_state:PlayerState
var inventory:ItemsCollection
var settings:SettingsState
var messages:MessagesList
var quests:QuestsManager

var player:Player
var ui:MainUI
var current_item:Item
var current_zone:Zone
var savegame_name:String
var use_joypad:bool = false
var use_joypad_ps:bool = false
var use_joypad_xbox:bool = false
var game_started:bool = false
var oxygen:float = 100.0

func _ready():
	_on_joypad_connection_changed(0, 0)
	Input.connect("joy_connection_changed", _on_joypad_connection_changed)

func new_game():
	player_state = PlayerState.new()
	inventory = ItemsCollection.new()
	settings = SettingsState.new()
	messages = MessagesList.new()
	quests = QuestsManager.new()
	StateSaver.reset_path()
	var os_lang = OS.get_locale_language()
	for lang in Settings.langs:
		if (lang == os_lang):
			GameState.settings.lang = lang
	StateSaver.loadState(settings, true)

func prepare_game(continue_last_game:bool):
	new_game()
	TranslationServer.set_locale(GameState.settings.lang)
	if (continue_last_game):
		load_game(StateSaver.get_last())

func save_game(savegame = null):
	saving_start.emit()
	StateSaver.set_path(savegame)
	player_state.position = player.position
	player_state.rotation = player.rotation
	if (current_item != null):
		player_state.current_item_type = current_item.type
		player_state.current_item_key = current_item.key
	else:
		player_state.current_item_type = Item.ItemType.ITEM_UNKNOWN
	StateSaver.saveState(player_state)
	StateSaver.saveState(InventoryState.new(inventory))
	StateSaver.saveState(settings)
	StateSaver.saveState(MessagesState.new(messages))
	StateSaver.saveState(QuestsState.new(quests))
	StateSaver.saveState(current_zone.state)
	saving_end.emit()
	
func load_game(savegame = null):
	GameState.prepare_game(false)
	loading_start.emit()
	StateSaver.set_path(savegame)
	StateSaver.loadState(player_state)
	if (player_state.current_item_type != Item.ItemType.ITEM_UNKNOWN):
		current_item = Tools.load_item(player_state.current_item_type, player_state.current_item_key)
	StateSaver.loadState(InventoryState.new(inventory))
	StateSaver.loadState(settings)
	StateSaver.loadState(MessagesState.new(messages))
	StateSaver.loadState(QuestsState.new(quests))
	loading_end.emit()

func pause_game():
	if (ui.menu.visible): return
	player.mute()
	get_tree().paused = true
	if (not use_joypad): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	ui.pause_game()

func resume_game():
	if (ui.menu.visible): return
	call_deferred("_resume_game")

func _resume_game():
	get_tree().paused = false
	if (not use_joypad): Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ui.resume_game()
	
func item_use(item:Item):
	item_unuse()
	current_item = item.dup()
	if (item is ItemMultiple):
		current_item.quantity = 1
	inventory.remove(current_item)
	ui.panel_item.use()
	player.handle_item()
	current_item.use()

func item_unuse():
	if (current_item == null): return
	player.unhandle_item()
	ui.panel_item.unuse()
	current_item.unuse()
	inventory.add(current_item.dup())
	current_item = null

func _on_joypad_connection_changed(_id, _connected):
	use_joypad = Input.get_connected_joypads().size() > 0
	if (use_joypad):
		var joyname = Input.get_joy_name(0)
		use_joypad_ps = joyname.contains("PS")
		use_joypad_xbox = joyname.contains("XBox")

class InventoryState extends State:
	var inventory:ItemsCollection
	func _init(_inventory):
		super("inventory")
		self.inventory = _inventory

class MessagesState extends State:
	var messages:MessagesList
	func _init(lessages):
		super("messages")
		self.messages = lessages

class QuestsState extends State:
	var quests:QuestsManager
	func _init(_quests):
		super("quests")
		self.quests = _quests
