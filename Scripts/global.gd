extends Node

const DAY_MAX_SCORE := 100
const WRONG_DIAGNOSIS_PENALTY := 20

var week1_payment := 0
var week2_payment := 0

var week1_quota := 50000
var week2_quota := 200000

var current_day_score := DAY_MAX_SCORE
var current_day_failed := false

signal day_score_changed(new_score: int)
signal day_failed()

func reset_day() -> void:
	current_day_score = DAY_MAX_SCORE
	current_day_failed = false
	day_score_changed.emit(current_day_score)

func deduct_score(amount: int) -> void:
	current_day_score = maxi(0, current_day_score - amount)
	day_score_changed.emit(current_day_score)
	if current_day_score <= 0 and not current_day_failed:
		current_day_failed = true
		day_failed.emit()

func award_week1_payment() -> void:
	week1_payment += current_day_score
