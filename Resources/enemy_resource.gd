extends Resource
class_name EnemyResource  # <--- THIS IS THE CRITICAL LINE

@export_group("Visuals")
@export var name: String = "Enemy"
@export var sprite_texture: Texture2D

@export_group("Stats")
@export var health: float = 20.0
@export var speed: float = 150.0
@export var damage: float = 5.0
@export var xp_value: int = 10
