extends Node
## Vertical-slice flow stub. Logic tables live in /logic; prototype fills this in.

enum Phase { LOOK, LISTEN, ASK, PULSE, TREAT, RESULT }

signal phase_changed(phase: Phase)

var phase: Phase = Phase.LOOK
var current_patient_id: String = ""
var completed_exams: Array[String] = []

func start_patient(patient_id: String) -> void:
	current_patient_id = patient_id
	completed_exams.clear()
	_set_phase(Phase.LOOK)

func mark_exam(exam: String) -> void:
	if exam not in completed_exams:
		completed_exams.append(exam)

func can_prescribe() -> bool:
	return current_patient_id != ""

func missing_exam_penalty() -> bool:
	return completed_exams.size() < 4

func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	phase_changed.emit(phase)
