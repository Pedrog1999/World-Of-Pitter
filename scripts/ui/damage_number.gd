class_name DamageNumber
extends Label3D
## Número de daño (o texto corto) flotante que sube y se desvanece.


static func spawn(parent: Node, pos: Vector3, amount: int, color: Color = Color(1.0, 0.88, 0.55)) -> void:
	spawn_text(parent, pos, str(amount), color)


static func spawn_text(parent: Node, pos: Vector3, text: String, color: Color) -> void:
	var label := DamageNumber.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0.05, 0.03, 0.02)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 72
	label.outline_size = 14
	label.pixel_size = 0.008
	parent.add_child(label)
	label.global_position = pos

	var end := pos + Vector3(randf_range(-0.4, 0.4), 1.1, 0.0)
	var tween := label.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel()
	tween.tween_property(label, "global_position", end, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tween.chain().tween_callback(label.queue_free)
