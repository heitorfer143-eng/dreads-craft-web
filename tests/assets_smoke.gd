extends SceneTree

var checked_files:=0

func _initialize() -> void:
	call_deferred("run")

func check(value:bool,message:String) -> void:
	if value:
		return
	push_error(message)
	quit(1)
	assert(value,message)

func scan_assets(path:String) -> void:
	var dir=DirAccess.open(path)
	check(dir!=null,"Could not open asset directory: "+path)
	dir.list_dir_begin()
	var name=dir.get_next()
	while name!="":
		if name.begins_with("."):
			name=dir.get_next()
			continue
		var full=path+"/"+name
		if dir.current_is_dir():
			scan_assets(full)
		else:
			var ext=name.get_extension().to_lower()
			if ext in ["png","jpg","jpeg","webp"]:
				var image=Image.new()
				var err=image.load(full)
				check(err==OK,"Broken raster asset: "+full+" (error "+str(err)+")")
				check(image.get_width()>0 and image.get_height()>0,"Empty raster asset: "+full)
				checked_files+=1
			elif ext=="svg":
				check(ResourceLoader.exists(full),"SVG is not importable: "+full)
				check(load(full)!=null,"SVG failed to load: "+full)
				checked_files+=1
		name=dir.get_next()
	dir.list_dir_end()

func run() -> void:
	scan_assets("res://assets")
	var items=load("res://scripts/items.gd")
	for raw_id in items.ICONS:
		var id=int(raw_id)
		var path=str(items.ICONS[raw_id])
		check(ResourceLoader.exists(path),"Missing inventory icon for item "+str(id)+": "+path)
		check(load(path)!=null,"Inventory icon failed to load for item "+str(id)+": "+path)
	for raw_id in items.CRAFT_ICONS:
		var id=int(raw_id)
		var path=str(items.CRAFT_ICONS[raw_id])
		check(ResourceLoader.exists(path),"Missing craft icon for item "+str(id)+": "+path)
		check(load(path)!=null,"Craft icon failed to load for item "+str(id)+": "+path)
	for raw_id in items.TILE_TEXTURES:
		var id=int(raw_id)
		var path=str(items.TILE_TEXTURES[raw_id])
		check(ResourceLoader.exists(path),"Missing tile texture for block "+str(id)+": "+path)
		check(load(path)!=null,"Tile texture failed to load for block "+str(id)+": "+path)
	check(load("res://assets/armor/avarita_helmet.png")!=null,"Repaired Avarita helmet PNG must load")
	print("PASS assets: ",checked_files," raster/SVG files + item/tile references")
	quit()
