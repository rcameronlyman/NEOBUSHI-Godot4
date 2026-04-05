extends Button

@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/UpgradeName
@onready var description_label: Label = $VBoxContainer/Description

var current_upgrade: UpgradeResource

func _ready() -> void:
	# Connect the button's own pressed signal to our function
	self.pressed.connect(_on_pressed)

func set_upgrade(upgrade: UpgradeResource) -> void:
	current_upgrade = upgrade
	
	# Update the visuals on the button
	if icon_rect:
		icon_rect.texture = upgrade.icon
	if name_label:
		name_label.text = upgrade.upgrade_name
	
	# Set the hover tooltip
	tooltip_text = upgrade.description
	
	# Hide the static description label since we use tooltips
	if description_label:
		description_label.hide()

func _on_pressed() -> void:
	if current_upgrade:
		# Add the upgrade to your lists in the ProgressionManager singleton [cite: 105]
		ProgressionManager.add_upgrade(current_upgrade)
		
		# Find the UI and hide only the selection panels, keeping the HUD visible
		var menu = get_tree().root.find_child("UpgradeMenu", true, false)
		if menu:
			var menu_root = menu.get_node_or_null("MenuRoot")
			var choice_box = menu.get_node_or_null("VBoxContainer")
			if menu_root:
				menu_root.hide()
			if choice_box:
				choice_box.hide()
		
		# Unpause the game [cite: 105]
		get_tree().paused = false
