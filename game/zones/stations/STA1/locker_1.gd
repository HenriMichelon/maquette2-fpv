extends Storage

func _init():
	super(true)

func _check_use() -> bool:
	return super._check_item_use("Keylocked", [[Item.ItemType.ITEM_TOOLS, "crowbar_1"]])
