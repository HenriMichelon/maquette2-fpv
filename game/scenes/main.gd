extends Node3D

@onready var player:Player = $Player
@onready var ui:MainUI = $MainUI

var _previous_zone:Zone
var _last_spawnpoint:String

func _ready():
	GameState.player = player
	GameState.ui = ui
	if get_viewport().size.x <= 1280:
		get_viewport().content_scale_factor = 0.6
	elif get_viewport().size.x <= 1680:
		get_viewport().content_scale_factor = 0.8
	if get_viewport().size.x > 1920:
		get_viewport().content_scale_factor = 2.2
	elif get_viewport().size.x >= 7680 :
		get_viewport().content_scale_factor = 3
	NotificationManager.connect("new_notification", GameState.ui.display_notification)
	GameState.messages.connect("new_message", _on_new_message)
	TranslationServer.set_locale(GameState.settings.lang)
	if (GameState.current_item != null):
		var item = GameState.current_item
		GameState.current_item = null
		GameState.item_use(item)
	GameState.quests.start("main")
	_change_zone(GameState.player_state.zone_name)
	if (GameState.player_state.position != Vector3.ZERO):
		player.move(GameState.player_state.position, GameState.player_state.rotation)

func _change_zone(zone_name:String, spawnpoint_key:String="default"):
	if (GameState.current_zone != null) and (zone_name == GameState.current_zone.zone_name): 
		return
	var new_zone:Zone
	if (_previous_zone != null) and (_previous_zone.zone_name == zone_name):
		new_zone = _previous_zone
	else:
		if (_previous_zone != null): 
			_previous_zone.queue_free()
		new_zone = Tools.load_zone(zone_name).instantiate()
		new_zone.zone_name = zone_name
	if (GameState.current_zone != null): 
		GameState.player.interactions.disconnect("item_collected", GameState.current_zone.on_item_collected)
		GameState.current_zone.disconnect("change_zone", _change_zone)
		for node in GameState.current_zone.find_children("*", "Storage", true, true):
			node.disconnect("open", _on_storage_open)
		for node in GameState.current_zone.find_children("*", "Usable", true, true):
			node.disconnect("unlock", _on_usable_unlock)
		for node in GameState.current_zone.find_children("*", "InteractiveCharacter", true, true):
			node.disconnect("trade", GameState.ui.npc_trade)
			node.disconnect("talk", GameState.ui.npc_talk)
			node.disconnect("end_talk", GameState.ui.npc_end_talk)
		remove_child(GameState.current_zone)
	_previous_zone = GameState.current_zone
	GameState.current_zone = new_zone
	GameState.player_state.zone_name = zone_name
	GameState.current_zone.connect("change_zone", _change_zone)
	GameState.player.interactions.connect("item_collected", GameState.current_zone.on_item_collected)
	add_child(GameState.current_zone)
	_spawn_player(spawnpoint_key)
	for node in GameState.current_zone.find_children("*", "Storage", true, true):
		node.connect("open", _on_storage_open)
	for node in GameState.current_zone.find_children("*", "Usable", true, true):
		node.connect("unlock", _on_usable_unlock)
	for node in GameState.current_zone.find_children("*", "InteractiveCharacter", true, true):
		node.connect("trade", GameState.ui.npc_trade)
		node.connect("talk", GameState.ui.npc_talk)
		node.connect("end_talk", GameState.ui.npc_end_talk)
	GameState.current_zone.visible = true
	if (GameState.messages.have_unread()):
		_on_new_message()
	GameState.current_zone.zone_post_start()

func _spawn_player(spawnpoint_key:String):
	for node in GameState.current_zone.find_children("*", "SpawnPoint", false, true):
		if (node.key == spawnpoint_key):
			player.move(node.global_position, node.global_rotation)
			node.spawn()
			break
	_last_spawnpoint = spawnpoint_key

func _on_new_message():
	NotificationManager.notif("You have unread messages !")

func _on_storage_open(node:Storage):
	GameState.ui.storage_open(node, _on_storage_close)

func _on_storage_close(node:Storage):
	node.use()

func _on_usable_unlock(success:bool):
	if (success):
		GameState.item_unuse()
	elif (GameState.current_item != null):
		NotificationManager.notif(tr("Nothing happens with '%s'") % tr(str(GameState.current_item)))

func _quit():
	get_tree().quit()
