extends SceneTree
## The packs exported into the directory given after "--" (WorldAssetsExport), headless - the
## Makefile's `packs`, in its project of no libmaszyna:
##   godot-double --headless --path .packs -s res://addons/world_assets_export/export_packs.gd -- <dir>


func _initialize() -> void:
    # after the autoloads (BiomesServer, which the biomes' scripts name) are in the tree
    await process_frame
    var dir: String = OS.get_cmdline_user_args()[0]
    var exported: bool = (load("res://addons/world_assets_export/world_assets_export.gd") as GDScript).export_all(dir)
    print("World assets: ", "exported into " + dir if exported else "FAILED")
    quit(0 if exported else 1)
