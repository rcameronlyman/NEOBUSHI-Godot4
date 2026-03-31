extends Resource
class_name PlayerResource

@export_group("Visuals")
@export var character_name: String = "Hero"
@export var sprite_frames: SpriteFrames # Changed to SpriteFrames for multiple animations

@export_group("Stats")
@export var max_health: float = 100.0
@export var movement_speed: float = 300.0
@export var acceleration: float = 800.0
@export var friction: float = 4000.0
