extends PanelContainer

@onready var icon: TextureRect = $Icon

func set_icon(new_texture: Texture2D) -> void:
	if new_texture:
		icon.texture = new_texture
		icon.show()
	else:
		icon.texture = null
		icon.hide()
