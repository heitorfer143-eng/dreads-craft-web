extends SceneTree

const SOURCE := "res://assets/image-003.png"
const OUT_DIR := "res://assets/mobs/generated"

const FRAMES := {
	"skeleton": {
		"idle": [Rect2i(28,189,248,344)],
		"walk": [Rect2i(28,189,248,344),Rect2i(305,211,259,324)],
		"attack": [Rect2i(573,167,273,366)],
		"hurt": [Rect2i(854,225,323,309)],
		"death": [Rect2i(1154,311,269,226)]
	},
	"wolf": {
		"idle": [Rect2i(23,651,270,259)],
		"walk": [Rect2i(23,651,270,259),Rect2i(299,668,279,241)],
		"attack": [Rect2i(585,665,283,244)],
		"hurt": [Rect2i(896,679,266,231)],
		"death": [Rect2i(1178,698,225,214)]
	}
}

func _initialize() -> void:
	var source=Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source==null or source.is_empty():
		push_error("Could not load mob source sheet: "+SOURCE)
		quit(1)
		return
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)

	var abs_dir=ProjectSettings.globalize_path(OUT_DIR)
	var dir_error=DirAccess.make_dir_recursive_absolute(abs_dir)
	if dir_error!=OK:
		push_error("Could not create mob output dir")
		quit(1)
		return

	for kind in FRAMES:
		var actions:Dictionary=FRAMES[kind]
		for action in actions:
			var rects:Array=actions[action]
			for i in rects.size():
				var region:Rect2i=rects[i]
				var crop=source.get_region(region)
				var canvas=Image.create(360,360,false,source.get_format())
				canvas.fill(Color(0,0,0,0))
				var target=Vector2i((360-region.size.x)/2,360-region.size.y)
				canvas.blit_rect(crop,Rect2i(Vector2i.ZERO,region.size),target)
				var suffix="_%d" % i if rects.size()>1 else ""
				var out_path="%s/%s_%s%s.png" % [OUT_DIR,kind,action,suffix]
				var err=canvas.save_png(ProjectSettings.globalize_path(out_path))
				if err!=OK:
					push_error("Failed writing "+out_path)
					quit(1)
					return

	print("Generated mob PNG frames in ",OUT_DIR)
	quit()
