extends Usable

func _init():
	super._init(false)

func _check_use() -> bool:
	var check = GameState.inventory.have_or_using(Item.ItemType.ITEM_QUEST, "access_card_1")
	if not check: 
		NotificationManager.notif(tr("You need an access card"))
		GameState.quests.advpoint("lvl0_door_to_restricted_area_access_card")
	return check

func _use():
	$"../..".change_zone.emit("stations/STA1/level_0", "level1")
