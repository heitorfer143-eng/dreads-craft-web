extends Node

var output: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var stream: AudioStreamGenerator

func _ready() -> void:
	output=AudioStreamPlayer.new()
	stream=AudioStreamGenerator.new()
	stream.mix_rate=22050.0
	stream.buffer_length=0.18
	output.stream=stream
	output.volume_db=-13.0
	add_child(output)
	output.play()
	playback=output.get_stream_playback()

func tone(freq: float, duration: float=0.045, strength: float=0.16) -> void:
	if not is_instance_valid(output):
		return
	if not output.playing:
		output.play()
		playback=output.get_stream_playback()
	if playback==null:
		return
	var frames=mini(int(stream.mix_rate*duration),playback.get_frames_available())
	for i in range(frames):
		var envelope=1.0-float(i)/maxf(1.0,float(frames))
		var sample=sin(TAU*freq*float(i)/stream.mix_rate)*strength*envelope
		playback.push_frame(Vector2(sample,sample))

func mine() -> void:
	tone(150.0,0.035,0.12)

func hit() -> void:
	tone(92.0,0.055,0.18)

func pickup() -> void:
	tone(440.0,0.035,0.10)
