extends CanvasLayer

# Root Node: CanvasLayer
# Path: /UI/mission_intro_ui.gd

@onready var objective_label = %ObjectiveLabel
@onready var instruction_label = %InstructionLabel

var level_resource: LevelResource

func _ready() -> void:
	# 1. Essential: Allow this UI to work while the engine is frozen
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. Pause the game logic immediately
	get_tree().paused = true
	
	# 3. Pull the data from the resource passed by the Director
	if level_resource:
		objective_label.text = level_resource.intro_objective_title
	else:
		objective_label.text = "THIN OUT THE ENEMY FORCES"
		
	# 4. Set styling and instructions
	objective_label.modulate = Color.RED
	instruction_label.text = "HIT SPACE TO CONTINUE"

func _input(event: InputEvent) -> void:
	# 5. Resume on "Space" (ui_accept)
	if event.is_action_pressed("ui_accept"):
		resume_game()

func resume_game() -> void:
	get_tree().paused = false
	queue_free()
