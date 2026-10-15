@tool
extends RefCounted
class_name WorldAssetsExport
## Packs what the worlds share - every directory of MaszynaWorld.ASSETS_RESOURCES_DIR, a pack each
## (common_terrain, common_facades, common_biomes) - into the game directory's
## MaszynaWorld.ASSETS_DIR/<pack>.pck, which the game mounts with a world (MaszynaWorld.mount())
## and the scenery importer reads in the editor. A pack holds a directory's files under their own
## paths, an imported one (.import beside it) as Godot's export does: its .import and what the
## import made (.godot/imported/), not its source; a shader with its UID beside it (UID_EXTENSION);
## what is no resource (a licence, a glTF's buffer) is left out.

const IMPORT_EXTENSION: String = "import"
const UID_EXTENSION: String = "uid"


## Every pack exported; false when one failed
static func export_all() -> bool:
    var exported: bool = true
    for pack: String in DirAccess.get_directories_at(MaszynaWorld.ASSETS_RESOURCES_DIR):
        exported = export_pack(pack) and exported
    return exported


## The pack [param pack] exported; false on failure
static func export_pack(pack: String) -> bool:
    var files: PackedStringArray = []
    _collect(MaszynaWorld.ASSETS_RESOURCES_DIR.path_join(pack), files)
    var path: String = UserSettings.get_maszyna_game_dir().path_join(MaszynaWorld.ASSETS_DIR).path_join(
            pack + "." + MaszynaWorld.PACK_EXTENSION)
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    var packer: PCKPacker = PCKPacker.new()
    if not packer.pck_start(path) == OK:
        push_error("World assets: cannot write %s" % path)
        return false
    for file: String in files:
        packer.add_file(file, ProjectSettings.globalize_path(file))
    if not packer.flush() == OK:
        push_error("World assets: cannot write %s" % path)
        return false
    print("World assets: %s, %d files" % [path, files.size()])
    return true


## The files of the directory [param dir] that go into its pack, into [param files]
static func _collect(dir: String, files: PackedStringArray) -> void:
    for sub: String in DirAccess.get_directories_at(dir):
        _collect(dir.path_join(sub), files)
    for file: String in DirAccess.get_files_at(dir):
        var path: String = dir.path_join(file)
        if not file.get_extension() == IMPORT_EXTENSION:
            if ResourceLoader.exists(path) and not FileAccess.file_exists(path + "." + IMPORT_EXTENSION):
                files.append(path)
                if FileAccess.file_exists(path + "." + UID_EXTENSION):
                    files.append(path + "." + UID_EXTENSION)
            continue
        files.append(path)
        var import_file: ConfigFile = ConfigFile.new()
        import_file.load(path)
        for key: String in import_file.get_section_keys("remap") if import_file.has_section("remap") else PackedStringArray():
            if key.begins_with("path"):
                files.append(import_file.get_value("remap", key))
