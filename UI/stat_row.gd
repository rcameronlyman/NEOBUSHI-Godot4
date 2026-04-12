extends HBoxContainer

# This signal tells the Hangar exactly what was clicked and how much it costs
signal purchase_requested(stat_name: String, cost: int)

@onready var name_label = $StatNameLabel
@onready var level_label = $LevelLabel
@onready var purchase_btn = $PurchaseButton

var current_stat_name: String = ""
var current_cost: int = 0

func init_row(stat_name: String, current_lvl: int, max_lvl: int, cost: int, total_bank: int) -> void:
	current_stat_name = stat_name
	current_cost = cost
	
	name_label.text = stat_name
	level_label.text = str(current_lvl) + " / " + str(max_lvl)
	
	# Logic to handle maxed out stats vs affordable stats
	if current_lvl >= max_lvl:
		purchase_btn.text = "MAXED"
		purchase_btn.disabled = true
	else:
		purchase_btn.text = str(cost) + " XP"
		# Disable the button if the player is too broke to afford it
		purchase_btn.disabled = total_bank < cost

func _on_purchase_button_pressed() -> void:
	# Yell up to the Hangar that this specific upgrade wants to be bought
	purchase_requested.emit(current_stat_name, current_cost)
