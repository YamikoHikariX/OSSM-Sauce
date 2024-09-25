extends Panel

func select():
	$Label.self_modulate = Color.SANDY_BROWN
	self_modulate = Color.SLATE_GRAY

func deselect():
	$Label.self_modulate = Color.WHITE
	$Label.self_modulate.a = 0.765
	self_modulate.a = 0.7
	self_modulate = Color.WHITE
