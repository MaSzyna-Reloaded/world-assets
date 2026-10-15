@tool
extends EditorPlugin
## Project > Tools > "Export world assets": the packs into the game's directory (libmaszyna's
## UserSettings, the one the game and the scenery importer read)

const EXPORT_MENU: String = "Export world assets"


func _enter_tree() -> void:
    add_tool_menu_item(EXPORT_MENU, _export)


func _exit_tree() -> void:
    remove_tool_menu_item(EXPORT_MENU)


func _export() -> void:
    WorldAssetsPacker.export_all(UserSettings.get_maszyna_game_dir())
