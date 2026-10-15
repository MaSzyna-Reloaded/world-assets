# The world assets: what the worlds share (world_assets/<pack>/), edited in this Godot project and
# exported into the game directory as world_assets/<pack>.pck (Project > Tools > Export world assets)

LIBMASZYNA?=$(abspath ../libmaszyna)
GAME?=$(abspath ../maszyna-reloaded)
# the Terrain3D the scenery importer builds (its `make terrain3d`): the same patched build
IMPORTER?=$(abspath ../scenery-importer)
GODOT?=godot-double

.PHONY: links editor packs

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

# The packs and world_assets.zip (world_assets/<pack>.pck, unzipped into the game directory) built
# headless in a project of their own, PACKS_PROJECT: no libmaszyna, only what the packs' files need
# (gnd_biomes, whose scripts name its BiomesServer, and Terrain3D - the game's double precision
# build, its `make terrain3d`), this project's world_assets/ and preview/ linked, its rendering and
# shader globals (the import's settings) taken from project.godot; the export is world-packer's
# (vendor/world-packer, WorldAssetsPacker). Hidden (a dot), this project's
# editor does not see it. The CI's release (.github/workflows/release.yml) is this.
PACKS_PROJECT:=.packs
PACKS_OUT?=$(PACKS_PROJECT)/out
TERRAIN3D_ADDON?=$(GAME)/vendor/terrain3d/project/addons/terrain_3d
packs:
	mkdir -p $(PACKS_PROJECT)/addons $(PACKS_OUT)
	printf '%s\n' 'config_version=5' '' '[application]' '' 'config/name="MaSzyna World Assets packs"' \
		'config/features=PackedStringArray("4.7", "Double Precision", "Forward Plus")' '' \
		'[autoload]' '' 'BiomesServer="*res://addons/gnd_biomes/biomes_server.gd"' '' > $(PACKS_PROJECT)/project.godot
	sed -n '/^\[rendering\]/,$$p' project.godot >> $(PACKS_PROJECT)/project.godot
	ln -sfn ../world_assets $(PACKS_PROJECT)/world_assets
	ln -sfn ../preview $(PACKS_PROJECT)/preview
	ln -sfn ../../vendor/world-packer/addons/world_packer $(PACKS_PROJECT)/addons/world_packer
	ln -sfn $(GAME)/vendor/gnd-biomes/addons/gnd_biomes $(PACKS_PROJECT)/addons/gnd_biomes
	ln -sfn $(TERRAIN3D_ADDON) $(PACKS_PROJECT)/addons/terrain_3d
	# the first run registers Terrain3D's extension, which the second one loads before importing
	$(GODOT) --headless --path $(PACKS_PROJECT) --import
	$(GODOT) --headless --path $(PACKS_PROJECT) --import
	$(GODOT) --headless --path $(PACKS_PROJECT) -s res://addons/world_packer/export_assets.gd -- $(abspath $(PACKS_OUT))
	cd $(PACKS_OUT) && rm -f world_assets.zip && zip -r world_assets.zip world_assets
