extends Node

signal saving_start()
signal saving_end()
signal loading_start()
signal loading_end()

var player_state:PlayerState = PlayerState.new()
var inventory = ItemsCollection.new()
var settings = SettingsState.new()

var player:Player
var ui:MainUI
var current_tool:ItemTool
var current_zone:Zone
var savegame_name:String

func _ready():
	load_game(StateSaver.get_last())

func save_game(savegame = null):
	saving_start.emit()
	StateSaver.set_path(savegame)
	player_state.position = player.position
	player_state.rotation = player.rotation
	StateSaver.saveState(player_state)
	StateSaver.saveState(InventoryState.new(inventory))
	StateSaver.saveState(settings)
	saving_end.emit()
	
func load_game(savegame = null):
	loading_start.emit()
	StateSaver.set_path(savegame)
	StateSaver.loadState(player_state)
	StateSaver.loadState(InventoryState.new(inventory))
	StateSaver.loadState(settings)
	loading_end.emit()

func pause_game():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	ui.pause_game()

func resume_game(_dummy=null):
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ui.resume_game()

class InventoryState extends State:
	var inventory:ItemsCollection
	func _init(inventory):
		super("inventory")
		self.inventory = inventory
