class_name ShowOnStart extends Node3D

@export var delay: float = 2.0
var delay_timer: float
var started: bool

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)

func _on_game_ended() -> void:
	started = false
	hide()

func _on_game_started() -> void:
	started = true
	hide()

func _physics_process(delta: float) -> void:
	if visible || !started: return
	
	delay_timer += delta
	if delay_timer >= delay:
		show()
