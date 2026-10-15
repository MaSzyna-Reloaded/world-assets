# The world assets: what the worlds share (world_assets/<pack>/), edited in this Godot project and
# exported into the game directory as world_assets/<pack>.pck (Project > Tools > Export world assets)

# The checkouts linked into this project (make links) and its packs built with (make packs) are given
# explicitly - there is no default: LIBMASZYNA (libmaszyna: its addons/libmaszyna, its vendor/gnd-sfx,
# its demo's built bin/libmaszyna) and GND_BIOMES (godot-biomes: its addons/gnd_biomes), e.g.
#   make links LIBMASZYNA=<libmaszyna> GND_BIOMES=<godot-biomes>
# Terrain3D is reloaded-terrain's release (make terrain3d).
GODOT?=godot-double
# The make variable $(1) given, else make stops saying what it is ($(2)) and how to give it
require=$(if $($(1)),,$(error $(1) not given: $(2) - make $@ $(1)=<path>))

.PHONY: links editor packs terrain3d

# Terrain3D, patched and built double precision, and the worlds' terrain streamer: the release
# RELOADED_TERRAIN of reloaded-terrain (github.com/MaSzyna-Reloaded/reloaded-terrain, tags
# YYMMDDHHMM) - its reloaded-terrain-<tag>.zip, addons/terrain_3d and addons/reloaded_terrain, unzipped here
RELOADED_TERRAIN:=2610152101
RELOADED_TERRAIN_ZIP:=https://github.com/MaSzyna-Reloaded/reloaded-terrain/releases/download/$(RELOADED_TERRAIN)/reloaded-terrain-$(RELOADED_TERRAIN).zip
terrain3d:
	curl -fsSL -o .reloaded-terrain.zip $(RELOADED_TERRAIN_ZIP)
	unzip -qo .reloaded-terrain.zip
	rm .reloaded-terrain.zip


# The addons of the other repositories, linked as the scenery importer links them
links: terrain3d
	$(call require,LIBMASZYNA,the libmaszyna checkout linked into this project)
	$(call require,GND_BIOMES,the godot-biomes checkout linked into this project)
	mkdir -p addons bin
	ln -sfn $(LIBMASZYNA)/addons/libmaszyna addons/libmaszyna
	ln -sfn $(LIBMASZYNA)/vendor/gnd-sfx/addons/gnd_sfx addons/gnd_sfx
	ln -sfn $(LIBMASZYNA)/demo/bin/libmaszyna bin/libmaszyna
	ln -sfn $(GND_BIOMES)/addons/gnd_biomes addons/gnd_biomes

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
packs: terrain3d
	$(call require,GND_BIOMES,the godot-biomes checkout the packs are built with)
	mkdir -p $(PACKS_PROJECT)/addons $(PACKS_OUT)
	printf '%s\n' 'config_version=5' '' '[application]' '' 'config/name="MaSzyna World Assets packs"' \
		'config/features=PackedStringArray("4.7", "Double Precision", "Forward Plus")' '' \
		'[autoload]' '' 'BiomesServer="*res://addons/gnd_biomes/biomes_server.gd"' '' > $(PACKS_PROJECT)/project.godot
	sed -n '/^\[rendering\]/,$$p' project.godot >> $(PACKS_PROJECT)/project.godot
	ln -sfn ../world_assets $(PACKS_PROJECT)/world_assets
	ln -sfn ../preview $(PACKS_PROJECT)/preview
	ln -sfn ../../vendor/world-packer/addons/world_packer $(PACKS_PROJECT)/addons/world_packer
	ln -sfn $(GND_BIOMES)/addons/gnd_biomes $(PACKS_PROJECT)/addons/gnd_biomes
	ln -sfn ../../addons/terrain_3d $(PACKS_PROJECT)/addons/terrain_3d
	# the first run registers Terrain3D's extension, which the second one loads before importing
	$(GODOT) --headless --path $(PACKS_PROJECT) --import
	$(GODOT) --headless --path $(PACKS_PROJECT) --import
	$(GODOT) --headless --path $(PACKS_PROJECT) -s res://addons/world_packer/export_assets.gd -- $(abspath $(PACKS_OUT))
	cd $(PACKS_OUT) && rm -f world_assets.zip && zip -r world_assets.zip world_assets
