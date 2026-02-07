extends Node

@onready var log_timer: Timer = $LogTimer
@onready var log_label: Label = $LogLabel
@export var is_left_sided: bool = false
@export var starting_message: String = ""
@export var font_size: int = 12
@export var timer_setting: float = 4.0
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fade_out_timer: Timer = $FadeOutTimer

func _ready() -> void:
	log_label.text = starting_message
	log_label.add_theme_font_size_override("font_size", font_size)
	log_timer.wait_time = timer_setting
	if is_left_sided:
		log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func make_log_message(message: String):
	log_label.text = log_label.text + "\n" + message
	log_timer.start()
	animation_player.play("RESET")

func _on_log_timer_timeout() -> void:
	animation_player.play("fade")
	fade_out_timer.start()

func _on_fade_out_timer_timeout() -> void:
	log_label.text = ""
