extends Node2D

# ──────────────────────────────────────────────────────────────────
# GYM HUD POSITIONING
# The score readout is laid out in Scenes/gym.tscn under UI/ScoreLabel.
# It is hidden while the puzzle is open (see _open_malware_puzzle) so
# it doesn't overlap the puzzle's own score label inside the monitor.
# To move/resize the gym HUD, edit UI/ScoreLabel in gym.tscn.
# To move the puzzle's HUD, edit malware.tscn (see MalwarePuzzle docs).
#
# CHARACTER PORTRAITS
# Portraits show inside the dialog textbox (not full-screen). To tune:
#   - Per-portrait scale: edit `"scale"` in characters/MC.dch and
#     characters/HG.dch (current default: 4.0). .dch files are JSON-
#     style Godot resources and do NOT accept inline comments.
#   - Textbox box size + which side the portrait sits on:
#     edit Resource_textbox in dialogic customs/bwuh.tres
#       box_size              → textbox width × height
#       portrait_stretch_factor → fraction of width used by portrait
#       portrait_position     → 0 = LEFT, 1 = RIGHT
#       box_modulate_custom_color → textbox tint
# To swap which sprite a portrait points to, change the `image` path
# in the matching `&"portraits"` entry of the .dch.
# ──────────────────────────────────────────────────────────────────

const MALWARE_PUZZLE := preload("res://Scenes/puzzle/malware_puzzle/malware.tscn")

const TIMELINE_HG_WEEK1 := "highschooler_week1"
const TIMELINE_HG_WEEK1_POST := "highschooler_week1_post"

@onready var start_button: Button = $UI/StartButton
@onready var score_label: Label = $UI/ScoreLabel

var current_puzzle: MalwarePuzzle = null
var pending_post_timeline: String = ""

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Global.day_score_changed.connect(_on_score_changed)
	Global.day_failed.connect(_on_day_failed)
	_refresh_score()

func _on_button_pressed() -> void:
	_start_day_one()

func _start_day_one() -> void:
	if Dialogic.current_timeline != null:
		return
	if current_puzzle != null:
		return

	Global.reset_day()
	_refresh_score()
	if start_button:
		start_button.visible = false
	Dialogic.start(TIMELINE_HG_WEEK1)
	get_viewport().set_input_as_handled()

func _on_dialogic_signal(arg: Variant) -> void:
	match str(arg):
		"wrong_diagnosis":
			_refresh_score()
		"start_malware_puzzle":
			pending_post_timeline = TIMELINE_HG_WEEK1_POST
			Dialogic.end_timeline()
			_open_malware_puzzle()
		"day_failed":
			Dialogic.end_timeline()
			_finish_day(false)
		"day_complete":
			Dialogic.end_timeline()
			Global.award_week1_payment()
			_finish_day(true)

func _open_malware_puzzle() -> void:
	if current_puzzle != null:
		return
	current_puzzle = MALWARE_PUZZLE.instantiate() as MalwarePuzzle
	if current_puzzle == null:
		return
	current_puzzle.puzzle_complete.connect(_on_puzzle_complete)
	add_child(current_puzzle)
	if score_label:
		score_label.visible = false

func _on_puzzle_complete() -> void:
	if current_puzzle:
		current_puzzle.queue_free()
		current_puzzle = null
	if score_label:
		score_label.visible = true

	if pending_post_timeline.is_empty():
		_finish_day(true)
		return

	var to_start := pending_post_timeline
	pending_post_timeline = ""
	Dialogic.start(to_start)

func _finish_day(success: bool) -> void:
	if start_button:
		start_button.text = "Start Day 1" if success else "Retry Day 1"
		start_button.visible = true
	_refresh_score()

func _refresh_score() -> void:
	if score_label:
		score_label.text = "Score: %d   Week 1: %d / %d" % [
			Global.current_day_score,
			Global.week1_payment,
			Global.week1_quota,
		]

func _on_score_changed(_new_score: int) -> void:
	_refresh_score()

func _on_day_failed() -> void:
	if current_puzzle:
		current_puzzle.queue_free()
		current_puzzle = null
		pending_post_timeline = ""
		if score_label:
			score_label.visible = true
		_finish_day(false)
