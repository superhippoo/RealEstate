extends Node
## 실제 메인 씬을 띄워 시간대별 스크린샷 캡처 (사용자 요청 검증용)
## godot --path . res://tools/capture_main.tscn

var main_scene: Node
var shots := [3.0, 9.0, 16.0]
var idx := 0
var elapsed := 0.0


func _ready() -> void:
	main_scene = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_scene)


func _process(delta: float) -> void:
	elapsed += delta
	if idx < shots.size() and elapsed >= shots[idx]:
		var img := get_viewport().get_texture().get_image()
		var out := "user://main_%d.png" % int(shots[idx])
		img.save_png(out)
		print("CAPTURED ", ProjectSettings.globalize_path(out))
		idx += 1
	elif idx >= shots.size():
		get_tree().quit()
