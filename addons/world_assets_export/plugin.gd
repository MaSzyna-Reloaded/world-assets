@tool
extends EditorPlugin

const EXPORT_MENU: String = "Export world assets"


func _enter_tree() -> void:
    add_tool_menu_item(EXPORT_MENU, WorldAssetsExport.export_all)


func _exit_tree() -> void:
    remove_tool_menu_item(EXPORT_MENU)
