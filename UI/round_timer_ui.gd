extends CanvasLayer

# Path: /UI/round_timer_ui.gd

# This assumes the Label node has "Access as Unique Name" (%) enabled.
@onready var label = %Label 

func _ready() -> void:
	# Modular Check: Ensure label starts visible even without a signal
	label.text = "15:00"
	
	# Connect to the global event bus
	if GameEvents.has_signal("time_updated"):
		GameEvents.time_updated.connect(_on_time_updated)

func _on_time_updated(seconds_left: float) -> void:
	# 1. Format the raw seconds into a clean MM:SS string
	var minutes = int(seconds_left) / 60
	var seconds = int(seconds_left) % 60
	
	# %02d ensures leading zeros (e.g., 14:05)
	label.text = "%02d:%02d" % [minutes, seconds]
	
	# 2. Dynamic Color Modulation
	if seconds_left <= 60.0:
		label.modulate = Color.RED
	else:
		label.modulate = Color.WHITE
