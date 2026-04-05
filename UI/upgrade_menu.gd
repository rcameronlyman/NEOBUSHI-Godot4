extends CanvasLayer

@onready var menu_root: Control = $MenuRoot
@onready var choice_container: VBoxContainer = $VBoxContainer
const UPGRADE_OPTION_SCENE = preload("res://UI/upgrade_option.tscn")

func _ready() -> void:
	# Connect to the signal that tells the menu which choices to show
	GameEvents.display_upgrade_choices.connect(_on_display_upgrade_choices)
	
	# Hide only the selection background and buttons so the HUD stays visible
	menu_root.hide()
	choice_container.hide()

func _on_display_upgrade_choices(choices: Array[UpgradeResource]) -> void:
	# Show the selection UI when a level-up occurs
	menu_root.show()
	choice_container.show()
	
	# Clear out any old buttons from the previous level-up
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()
		
		# Create a new button for each choice offered
		for upgrade in choices:
			var option = UPGRADE_OPTION_SCENE.instantiate()
			choice_container.add_child(option)
			option.set_upgrade(upgrade)
