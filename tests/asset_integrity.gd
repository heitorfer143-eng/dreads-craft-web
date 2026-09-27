extends SceneTree

var failures := 0
var checked_pngs := 0

func _initialize() -> void:
	call_deferred("run")

func fail(message:String) -> void:
	failures+=1
	push_error(message)

func read_u32_be(bytes:PackedByteArray,offset:int) -> int:
	return (int(bytes[offset])<<24) | (int(bytes[offset+1])<<16) | (int(bytes[offset+2])<<8) | int(bytes[offset+3])

func crc32_range(bytes:PackedByteArray,start:int,length:int) -> int:
	# GDScript integers are signed 64-bit values. Keep every intermediate value
	# explicitly inside the unsigned 32-bit CRC domain so right shifts cannot
	# sign-extend on long IDAT chunks.
	var crc:int=4294967295
	for i in range(start,start+length):
		crc=(crc^int(bytes[i]))&4294967295
		for _bit in range(8):
			if (crc & 1)!=0:
				crc=((crc>>1)^3988292384)&4294967295
			else:
				crc=(crc>>1)&4294967295
	return (crc^4294967295)&4294967295

func is_chunk(bytes:PackedByteArray,offset:int,a:int,b:int,c:int,d:int) -> bool:
	return int(bytes[offset])==a and int(bytes[offset+1])==b and int(bytes[offset+2])==c and int(bytes[offset+3])==d

func validate_png(path:String) -> void:
	checked_pngs+=1
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:
		fail("Cannot open PNG: "+path)
		return
	var bytes=file.get_buffer(file.get_length())
	file.close()
	var signature=[137,80,78,71,13,10,26,10]
	if bytes.size()<20:
		fail("PNG too small: "+path)
		return
	for i in range(signature.size()):
		if int(bytes[i])!=signature[i]:
			fail("Invalid PNG signature: "+path)
			return

	var offset:=8
	var chunk_index:=0
	var saw_iend:=false
	while offset+12<=bytes.size():
		var chunk_length=read_u32_be(bytes,offset)
		if chunk_length<0 or chunk_length>128*1024*1024:
			fail("Impossible PNG chunk length in "+path+" at "+str(offset))
			return
		var type_offset=offset+4
		var data_offset=offset+8
		var crc_offset=data_offset+chunk_length
		if crc_offset+4>bytes.size():
			fail("Truncated PNG chunk in "+path+" at "+str(offset))
			return
		var expected_crc=read_u32_be(bytes,crc_offset)
		var actual_crc=crc32_range(bytes,type_offset,4+chunk_length)
		if expected_crc!=actual_crc:
			fail("PNG CRC mismatch: "+path+" at "+str(offset))
			return
		if chunk_index==0:
			if not is_chunk(bytes,type_offset,73,72,68,82) or chunk_length!=13:
				fail("PNG does not begin with a valid IHDR: "+path)
				return
		if is_chunk(bytes,type_offset,73,69,78,68):
			if chunk_length!=0:
				fail("Invalid IEND length: "+path)
				return
			saw_iend=true
			offset=crc_offset+4
			break
		offset=crc_offset+4
		chunk_index+=1
	if not saw_iend:
		fail("PNG missing IEND: "+path)
	elif offset!=bytes.size():
		fail("Unexpected bytes after PNG IEND: "+path)

func scan_dir(path:String) -> void:
	var dir=DirAccess.open(path)
	if dir==null:
		fail("Cannot open asset directory: "+path)
		return
	dir.list_dir_begin()
	while true:
		var name=dir.get_next()
		if name=="":
			break
		if name=="." or name=="..":
			continue
		var child=path.path_join(name)
		if dir.current_is_dir():
			scan_dir(child)
		elif name.get_extension().to_lower()=="png":
			validate_png(child)
	dir.list_dir_end()

func run() -> void:
	scan_dir("res://assets")
	if checked_pngs==0:
		fail("No PNG assets were scanned")
	if failures==0:
		print("PASS asset integrity: ",checked_pngs," PNG files have valid signatures, chunks, CRCs and IEND")
	else:
		print("FAIL asset integrity: ",failures," problem(s) across ",checked_pngs," PNG files")
	quit(0 if failures==0 else 1)
