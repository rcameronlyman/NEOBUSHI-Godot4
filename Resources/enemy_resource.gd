extends Resource
class_name EnemyResource

@export_group("Visuals")
@export var name: String = "Enemy"
@export var sprite_texture: Texture2D
@export var hit_flash_color: Color = Color.WHITE
@export var wobble_speed: float = 0.015
@export var wobble_intensity: float = 8.0

@export_group("Stats")
@export var health: float = 20.0
@export var speed: float = 150.0
@export var damage: float = 5.0
@export var xp_value: int = 10
