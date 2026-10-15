# The world assets: what the worlds share (world_assets/<pack>/), edited in this Godot project and
# exported into the game directory as world_assets/<pack>.pck (Project > Tools > Export world assets)

LIBMASZYNA?=$(abspath ../libmaszyna)
GAME?=$(abspath ../maszyna-reloaded)
# the Terrain3D the scenery importer builds (its `make terrain3d`): the same patched build
IMPORTER?=$(abspath ../scenery-importer)
GODOT?=godot-double

.PHONY: links editor

# The addons of the other repositories, linked as the scenery importer links them
links:
	mkdir -p addons bin
	ln -sfn $(LIBMASZYNA)/addons/libmaszyna addons/libmaszyna
	ln -sfn $(LIBMASZYNA)/vendor/gnd-sfx/addons/gnd_sfx addons/gnd_sfx
	ln -sfn $(LIBMASZYNA)/demo/bin/libmaszyna bin/libmaszyna
	ln -sfn $(GAME)/vendor/gnd-biomes/addons/gnd_biomes addons/gnd_biomes
	ln -sfn $(IMPORTER)/addons/terrain_3d addons/terrain_3d

editor: links
	$(GODOT) --path . --editor
