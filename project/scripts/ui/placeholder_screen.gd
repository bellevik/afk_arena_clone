extends ScrollContainer

var _metadata: Dictionary = {}

@onready var title_label: Label = %PlaceholderTitle
@onready var subtitle_label: Label = %PlaceholderSubtitle
@onready var body_label: Label = %PlaceholderBody
@onready var status_label: Label = %PlaceholderStatus
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(SceneRouter.go_to.bind("main_menu"))
	_apply_metadata()


func configure(metadata: Dictionary) -> void:
	_metadata = metadata.duplicate(true)
	if is_inside_tree():
		_apply_metadata()


func _apply_metadata() -> void:
	title_label.text = String(_metadata.get("title", "Placeholder"))
	subtitle_label.text = String(_metadata.get("subtitle", ""))
	body_label.text = String(_metadata.get("body", "This screen is reserved for a later phase."))
	status_label.text = String(_metadata.get("status", "Phase 1 placeholder"))

