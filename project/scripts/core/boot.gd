extends Control

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	ThemeManager.apply_theme(self)
	AppState.register_boot()
	status_label.text = "Preparing portrait app shell..."
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	SceneRouter.open_app_shell()

