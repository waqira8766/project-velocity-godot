extends Node3D

const AUDIO := {
	"step": preload("res://assets/audio/step.wav"), "land": preload("res://assets/audio/land.wav"),
	"jump": preload("res://assets/audio/jump.wav"), "impact": preload("res://assets/audio/hit.wav"),
	"damage": preload("res://assets/audio/damage.wav"), "boost": preload("res://assets/audio/boost.wav"),
	"lightning": preload("res://assets/audio/lightning.wav"), "slide": preload("res://assets/audio/slide.wav"),
	"rewind": preload("res://assets/audio/rewind.wav"), "phase": preload("res://assets/audio/phase.wav"),
	"shockwave": preload("res://assets/audio/shockwave.wav"), "portal": preload("res://assets/audio/portal.wav"),
	"goal": preload("res://assets/audio/goal.wav"), "cache": preload("res://assets/audio/goal.wav")
}
const SCORE = preload("res://assets/audio/score.wav")
const ATMOSPHERE = preload("res://assets/audio/atmosphere.wav")
const WIND = preload("res://assets/audio/wind.wav")
const COLORS := {
	"boost": Color(1.0,.42,.07), "goal": Color(.42,.95,1.0), "cache": Color(1.0,.66,.27),
	"damage": Color(1.0,.15,.10), "impact": Color(1.0,.27,.13), "rewind": Color(.37,.77,1.0),
	"lightning": Color(1.0,.61,.16), "slide": Color(1.0,.5,.25), "phase": Color(.33,.93,1.0),
	"shockwave": Color(1.0,.48,.2), "portal": Color(.85,.53,1.0), "land": Color(.77,.69,.53)
}
const DURATIONS := {"boost":.35, "goal":.72, "cache":.56, "rewind":.95, "portal":.7, "shockwave":.53}
const COMBAT_CUES := {
	"hit":"impact","counter":"goal","block":"phase","miss":"slide",
	"boss":"goal","rush":"boost","tornado":"shockwave"
}

var game
var sound_pool: Array[AudioStreamPlayer3D] = []
var ring_pool: Array[Dictionary] = []
var trail_points: Array[Vector3] = []
var trail := ImmediateMesh.new()
var trail_material := StandardMaterial3D.new()
var sound_cursor := 0
var ring_cursor := 0
var stride_timer := 0.0
var score: AudioStreamPlayer
var ambience: AudioStreamPlayer
var wind: AudioStreamPlayer
var last_paused := false


func setup(owner) -> void:
	game = owner
	for channel: String in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(channel) < 0:
			AudioServer.add_bus()
			var bus := AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus, channel)
			AudioServer.set_bus_send(bus,"Master")
	for _slot in range(7):
		var player := AudioStreamPlayer3D.new()
		player.bus = "SFX"
		player.max_distance = 44.0
		player.unit_size = 5.5
		add_child(player)
		sound_pool.append(player)
	if DisplayServer.get_name() != "headless":
		score = _loop(SCORE,"Music",-18.5)
		ambience = _loop(ATMOSPHERE,"SFX",-34.0)
		wind = _loop(WIND,"SFX",-69.0)
	for key in game.progress.settings:
		setting(str(key),game.progress.settings[key])

	var view := MeshInstance3D.new()
	view.mesh = trail
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.vertex_color_use_as_albedo = true
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	view.material_override = trail_material
	add_child(view)
	var ring := TorusMesh.new()
	ring.inner_radius = .865
	ring.outer_radius = 1.0
	ring.rings = 24
	ring.ring_segments = 6
	for _slot in range(12):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = false
		var node := MeshInstance3D.new()
		node.mesh = ring
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visible = false
		add_child(node)
		ring_pool.append({"node":node, "mat":mat, "age":1.0, "limit":0.0,"radius":1.0,"color":Color.WHITE})


func setting(key: String, value: Variant) -> void:
	var channels := {"master_volume":"Master","music_volume":"Music","sfx_volume":"SFX","voice_volume":"Voice"}
	if not channels.has(key):
		return
	var index := AudioServer.get_bus_index(channels[key])
	if index >= 0:
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.0001,float(value))))


func pulse(key: String, location: Vector3, strength: float = 1.0) -> void:
	key = COMBAT_CUES.get(key,key)
	if AUDIO.has(key):
		_sound(key, -5.0 if key != "step" else -15.0, strength, location)
	if not game.effects or not COLORS.has(key) or game.progress.settings.get("reduced_flash",false):
		return
	if game.quality == 0 and key in ["slide","land"]:
		return
	var effect := ring_pool[ring_cursor]
	ring_cursor = (ring_cursor+1)%ring_pool.size()
	effect["age"] = 0.0
	effect["limit"] = DURATIONS.get(key,.32)
	effect["radius"] = (11.0 if key == "shockwave" else 3.9 if key == "boost" else 2.8) * clampf(strength,.5,2.0)
	effect["color"] = COLORS[key]
	var node: MeshInstance3D = effect["node"]
	node.position = location + Vector3.UP*.095
	node.scale = Vector3(.15,.32,.15)
	node.visible = true


func notify(key: String, data: Dictionary) -> void:
	var cues := {"ability_cast":"phase", "lightning_hit":"lightning", "shockwave_hit":"shockwave",
		"projectile_redirected":"lightning", "portal_entered":"portal","portal_returned":"portal"}
	if not cues.has(key):
		return
	var sound: String = cues[key]
	if key == "ability_cast":
		var move: String = str(data.get("id",""))
		sound = {"slow":"rewind","tornado":"shockwave","mirage":"phase","phase":"phase","lightning":"lightning",
			"shockwave":"shockwave","portal":"portal","redirect":"phase"}.get(move,"phase")
	pulse(sound,data.get("position",game.runner.position),1.0)


func _loop(clip: AudioStreamWAV, bus: String, db: float) -> AudioStreamPlayer:
	var track: AudioStreamWAV = clip.duplicate()
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_end = roundi(track.get_length()*track.mix_rate)
	var channel := AudioStreamPlayer.new()
	channel.bus = bus
	channel.volume_db = db
	channel.stream = track
	add_child(channel)
	channel.play()
	return channel


func _sound(key: String, db: float, energy: float, location: Vector3) -> void:
	if score == null:
		return
	var player := sound_pool[sound_cursor]
	sound_cursor = (sound_cursor+1)%sound_pool.size()
	player.position = location
	player.stream = AUDIO[key]
	player.volume_db = db
	player.pitch_scale = clampf(.90 + energy*.10,.80,1.27)
	player.play()


func _exit_tree() -> void:
	for player in [score,ambience,wind] + sound_pool:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func clear_trail() -> void:
	trail_points.clear()
	trail.clear_surfaces()


func step(dt: float) -> void:
	if game.paused != last_paused:
		last_paused = game.paused
		for channel in [score,ambience,wind]:
			if is_instance_valid(channel):
				channel.stream_paused = last_paused
		if last_paused:
			for player in sound_pool:
				player.stop()
	if game.paused:
		return
	if score != null:
		var wind_speed := clampf(float(game.speed)/85.0,0.0,1.0)
		wind.volume_db = lerpf(wind.volume_db,lerpf(-68.0,-21.0,pow(wind_speed,.4)),dt*6.0)
		ambience.volume_db = -44.0 if game.realm == "rift" else -33.0
		score.volume_db = lerpf(score.volume_db,-13.0 if not game.boss_status.is_empty() else -19.0,dt*2.0)
	for effect in ring_pool:
		var node: MeshInstance3D = effect["node"]
		if not node.visible:
			continue
		effect["age"] += dt
		var t := clampf(effect["age"]/effect["limit"],0.0,1.0)
		if t >= 1.0:
			node.visible = false
			continue
		var radius: float = lerpf(.18,effect["radius"],ease(t,.33))
		node.scale = Vector3(radius,maxf(.025,.32*(1.0-t)),radius)
		var color: Color = effect["color"]
		color.a = .60*pow(1.0-t,1.85)
		effect["mat"].albedo_color = color
	_update_steps(dt)
	_update_trails()


func _update_steps(dt: float) -> void:
	if not game.runner.is_on_floor() or game.speed < 2.0 or game.history.active:
		stride_timer = 0.0
		return
	stride_timer -= dt
	if stride_timer <= 0.0:
		stride_timer = lerpf(.48,.16,clampf(game.speed/38.0,0.0,1.0))
		_sound("step",-24.0 + minf(game.speed,35.0)*.18,.75,game.runner.position)


func _update_trails() -> void:
	var visible_effects: bool = game.effects and not game.progress.settings.get("reduced_motion",false)
	var active: bool = visible_effects and game.speed > 16.0 and not game.history.active
	if active:
		var at: Vector3 = game.runner.position + Vector3.UP*.96
		if trail_points.is_empty() or trail_points.back().distance_to(at) > .36:
			trail_points.append(at)
	elif not trail_points.is_empty():
		trail_points.pop_front()
	var cap: int = [7,12,18,26][game.quality]
	if trail_points.size() > cap:
		trail_points.pop_front()
	trail.clear_surfaces()
	if trail_points.size() < 2:
		return
	trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var view: Vector3 = game.camera.global_basis.x
	for index in range(trail_points.size()):
		var t := float(index)/float(trail_points.size()-1)
		var center := trail_points[index]
		var width := (.025+.14*t)*clampf(game.speed/37.0,.34,1.4)
		var tint: Color = game.progress.trail_color()
		var color := Color(tint.darkened(.40*(1.0-t)),.83*t*t)
		trail.surface_set_color(color)
		trail.surface_add_vertex(center-view*width)
		trail.surface_set_color(color)
		trail.surface_add_vertex(center+view*width)
	trail.surface_end()
