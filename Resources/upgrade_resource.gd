extends Resource
class_name UpgradeResource

@export var upgrade_id: String
@export var upgrade_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var is_weapon: bool = true

# New field to link the actual weapon data
@export var weapon_data: WeaponResource
