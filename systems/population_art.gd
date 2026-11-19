extends RefCounted

const COATS := [Color("#677173"), Color("#985045"), Color("#3c605e"), Color("#586176"), Color("#7b6b44"), Color("#536857")]
const SKIN := [Color("#603e2f"), Color("#a87654"), Color("#bd8b67"), Color("#73513f"), Color("#c79d82")]
const CARS := [Color("#354759"), Color("#5b4a51"), Color("#42676b"), Color("#a0a6a6"), Color("#6d5746")]
var _materials: Dictionary = {}
var _vehicle_models: Dictionary = {}
var _siren: AudioStreamWAV
var _engine: AudioStreamWAV

func material(color: Color, roughness: float = 0.75, metalness: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var key := [color, roughness, metalness, glow]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metalness
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	_materials[key] = mat
	return mat

func _part(mesh: Mesh, position: Vector3, mat: Material, scaling: Vector3 = Vector3.ONE, rotation: Vector3 = Vector3.ZERO) -> Dictionary:
	return {"mesh":mesh,"transform":Transform3D(Basis.from_euler(rotation).scaled(scaling),position),"material":mat}

func _sphere(position: Vector3, scale: Vector3, mat: Material) -> Dictionary:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere.radius = 0.5
	sphere.height = 1.0
	return _part(sphere, position, mat, scale)

func _box(position: Vector3, size: Vector3, mat: Material) -> Dictionary:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _part(mesh, position, mat)

func _rod(position: Vector3, height: float, top: float, bottom: float, mat: Material) -> Dictionary:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 1
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	return _part(mesh, position, mat)

func _compile(group: Array[Dictionary]) -> ArrayMesh:
	var by_material: Dictionary = {}
	for part in group:
		var mesh: Mesh = part.mesh
		var mat: Material = part.material
		if not by_material.has(mat):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface.set_material(mat)
			by_material[mat] = surface
		for i in mesh.get_surface_count():
			by_material[mat].append_from(mesh, i, part.transform)
	var result := ArrayMesh.new()
	for mat in by_material:
		by_material[mat].commit(result)
	return result

func _mesh(parent: Node3D, geometry: Mesh, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = geometry
	item.position = at
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item

func _bodywork(rows: Array[Vector4]) -> ArrayMesh:
	# Each transverse ring gives longitudinal Z, half-width, bottom and crown.
	var verts := PackedVector3Array()
	for row in rows:
		var w := row.y
		var lo := row.z
		var hi := row.w
		var z := row.x
		verts.append_array([
			Vector3(-w*0.82,lo,z), Vector3(w*0.82,lo,z), Vector3(w,lo+0.12,z),
			Vector3(w,hi-0.10,z), Vector3(w*0.83,hi,z), Vector3(-w*0.83,hi,z),
			Vector3(-w,hi-0.10,z), Vector3(-w,lo+0.12,z)
		])
	var surf := SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rows.size()-1):
		for j in range(8):
			var a := i*8+j
			var b := i*8+((j+1)%8)
			for idx in [a,a+8,b,b,a+8,b+8]:
				surf.add_vertex(verts[idx])
	var far := (rows.size()-1)*8
	for j in range(1,7):
		for idx in [0,j,j+1,far,far+j+1,far+j]:
			surf.add_vertex(verts[idx])
	surf.generate_normals()
	return surf.commit()

func _coach(kind: String, variant: int) -> ArrayMesh:
	var key := [kind, variant]
	if _vehicle_models.has(key):
		return _vehicle_models[key]
	var paint := material(CARS[posmod(variant,CARS.size())],0.43,0.43)
	if kind == "police":
		paint = material(Color("#2c3d49"),0.42,0.35)
	elif kind == "van":
		paint = material(Color("#82766a"),0.63,0.18)
	elif kind == "suspect":
		paint = material(Color("#7e4541"),0.48,0.23)
	var rubber := material(Color("#1e2326"),0.94)
	var alloy := material(Color("#73808a"),0.52,0.40)
	var glass := material(Color("#314d5b"),0.34,0.57)
	var headlight := material(Color("#ffe2b7"),0.47,0.1,1.27)
	var taillight := material(Color("#de5350"),0.50,0.1,0.90)
	var panels: Array[Dictionary] = []
	var body_rows: Array[Vector4] = [
		Vector4(-2.12,0.80,0.37,0.66),Vector4(-1.93,0.97,0.34,0.82),
		Vector4(-1.07,1.00,0.27,0.92),Vector4(0.79,1.01,0.27,0.96),
		Vector4(1.68,0.99,0.32,0.86),Vector4(1.99,0.86,0.36,0.71)]
	var cab_rows: Array[Vector4] = [
		Vector4(-1.04,0.82,0.83,0.98),Vector4(-0.52,0.76,0.88,1.38),
		Vector4(0.66,0.77,0.87,1.40),Vector4(1.19,0.83,0.86,0.99)]
	if kind == "van":
		body_rows = [
			Vector4(-2.48,0.90,0.39,0.78),Vector4(-2.02,1.04,0.38,1.01),
			Vector4(-1.22,1.06,0.28,1.54),Vector4(2.06,1.06,0.29,1.62),
			Vector4(2.32,0.97,0.39,1.49)]
		cab_rows = [
			Vector4(-1.93,0.84,0.84,1.05),Vector4(-1.40,0.93,0.96,1.91),
			Vector4(1.94,0.94,1.47,1.98),Vector4(2.10,0.88,1.44,1.79)]
	panels.append(_part(_bodywork(body_rows),Vector3.ZERO,paint))
	panels.append(_part(_bodywork(cab_rows),Vector3.ZERO,glass))
	# Exterior trim underneath the glazing, independent brake and headlight materials.
	panels.append(_box(Vector3(0.0,0.50,-2.05 if kind != "van" else -2.33),Vector3(1.64,0.12,0.14),rubber))
	panels.append(_box(Vector3(0.0,0.47,1.94 if kind != "van" else 2.29),Vector3(1.66,0.11,0.12),rubber))
	for side in [-1.0,1.0]:
		panels.append(_box(Vector3(side*0.67,0.64,-2.07 if kind != "van" else -2.36),Vector3(0.43,0.12,0.08),headlight))
		panels.append(_box(Vector3(side*0.69,0.67,1.96 if kind != "van" else 2.31),Vector3(0.38,0.10,0.05),taillight))
		for axle in [-1.31,1.28]:
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.34
			wheel.bottom_radius = 0.34
			wheel.height = 0.23
			wheel.radial_segments = 11
			wheel.rings = 1
			panels.append(_part(wheel,Vector3(side*0.91,0.35,axle),rubber,Vector3.ONE,Vector3(0.0,0.0,PI/2.0)))
			var rim := CylinderMesh.new()
			rim.top_radius = 0.18
			rim.bottom_radius = 0.18
			rim.height = 0.035
			rim.radial_segments = 8
			rim.rings = 1
			panels.append(_part(rim,Vector3(side*1.034,0.35,axle),alloy,Vector3.ONE,Vector3(0.0,0.0,PI/2.0)))
	if kind == "police":
		var stripe := material(Color("#d7dddb"),0.69)
		for side in [-1.0,1.0]:
			panels.append(_box(Vector3(side*1.004,0.67,0.25),Vector3(0.025,0.21,1.07),stripe))
		panels.append(_box(Vector3(0,1.42,0.10),Vector3(0.92,0.07,0.26),rubber))
	_vehicle_models[key] = _compile(panels)
	return _vehicle_models[key]

func vehicle(parent: Node3D, kind: String, variant: int) -> Dictionary:
	_mesh(parent,_coach(kind,variant))
	var brake_glow := material(Color("#ff3732"),0.48,0.10,2.6)
	var brake_parts: Array[Dictionary] = []
	var rear := 2.339 if kind=="van" else 1.994
	for side in [-1.0,1.0]:
		brake_parts.append(_box(Vector3(side*0.691,0.67,rear),Vector3(0.35,0.073,0.022),brake_glow))
	var result := {"brake_lamps":_mesh(parent,_compile(brake_parts))}
	if kind == "police":
		var beacon_red: Array[Dictionary] = [_box(Vector3(0.23,1.49,0.10),Vector3(0.40,0.12,0.26),material(Color("#ff4842"),0.45,0.0,1.7))]
		var beacon_blue: Array[Dictionary] = [_box(Vector3(-0.23,1.49,0.10),Vector3(0.40,0.12,0.26),material(Color("#39aaff"),0.45,0.0,1.8))]
		result.red = _mesh(parent,_compile(beacon_red))
		result.blue = _mesh(parent,_compile(beacon_blue))
		var sound := AudioStreamPlayer3D.new()
		sound.name = "PursuitTone"
		sound.stream = _siren_asset()
		sound.position.y = 1.48
		sound.volume_db = -17.0
		sound.unit_size = 4.0
		sound.max_distance = 48.0
		if AudioServer.get_bus_index("SFX") >= 0:
			sound.bus = &"SFX"
		parent.add_child(sound)
		result.siren = sound
	else:
		var motor := AudioStreamPlayer3D.new()
		motor.name = &"EngineIdle"
		motor.stream = _engine_asset()
		motor.position = Vector3(0.0,0.56,-1.1)
		motor.volume_db = -23.0
		motor.unit_size = 0.8
		motor.max_distance = 23.0
		if AudioServer.get_bus_index("SFX") >= 0:
			motor.bus = &"SFX"
		parent.add_child(motor)
		result.motor = motor
	return result

func human(parent: Node3D, variant: int, suspect: bool) -> Dictionary:
	var coat := material(COATS[posmod(variant,COATS.size())] if not suspect else Color("#725044"))
	var pants := material(Color("#29353c"))
	var sole := material(Color("#27282a"))
	var skin := material(SKIN[posmod(variant,SKIN.size())])
	var hair := material(Color("#282325"))
	var undershirt := material(Color("#c1b4a2") if variant%3 == 0 else Color("#383730"))
	var body: Array[Dictionary] = [
		_sphere(Vector3(0,1.14,0),Vector3(0.52,0.56,0.33),coat),
		_sphere(Vector3(0,0.99,0.006),Vector3(0.47,0.31,0.35),coat),
		_sphere(Vector3(0,1.40,-0.01),Vector3(0.16,0.19,0.15),skin),
		_sphere(Vector3(0,1.36,-0.163),Vector3(0.14,0.08,0.01),undershirt),
		_sphere(Vector3(0,1.57,0.0),Vector3(0.25,0.31,0.23),skin),
		_sphere(Vector3(0,1.66,0.018),Vector3(0.26,0.16,0.24),hair),
		_sphere(Vector3(0,1.57,-0.101),Vector3(0.079,0.087,0.073),skin)
	]
	var legs: Array[Node3D] = []
	var arms: Array[Node3D] = []
	_mesh(parent,_compile(body))
	for side in [-1.0,1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.127,0.89,0.014)
		parent.add_child(leg)
		var shoe: Array[Dictionary] = [
			_sphere(Vector3(0.0,-0.42,0.02),Vector3(0.211,0.87,0.228),pants),
			_sphere(Vector3(0.0,-0.84,-0.085),Vector3(0.211,0.12,0.33),sole)
		]
		_mesh(leg,_compile(shoe))
		legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side*0.236,1.28,0.015)
		arm.rotation.z = side*0.13
		parent.add_child(arm)
		var sleeve: Array[Dictionary] = [
			_sphere(Vector3(0,-0.25,0.006),Vector3(0.19,0.57,0.207),coat),
			_sphere(Vector3(0,-0.52,-0.015),Vector3(0.142,0.17,0.16),skin)
		]
		_mesh(arm,_compile(sleeve))
		arms.append(arm)
	parent.scale = Vector3(1.0 + 0.05 * float(variant % 4),0.95 + 0.026 * float(variant % 5),1.0 + 0.04 * float(variant % 4))
	return {"legs":legs,"arms":arms}

func prop(parent: Node3D, variant: int) -> Dictionary:
	var paint := material(Color("#c76b32")) if variant%2 == 0 else material(Color("#606970"))
	var steel := material(Color("#455663"),0.64,0.29)
	var marker := material(Color("#efd6a0"),0.61,0.0,0.35)
	var parts: Array[Dictionary] = [
		_rod(Vector3(0,0.37,0),0.72,0.31,0.33,paint),
		_rod(Vector3(0,0.16,0),0.083,0.34,0.34,steel),
		_rod(Vector3(0,0.58,0),0.084,0.327,0.327,marker),
		_rod(Vector3(0,0.71,0),0.095,0.335,0.337,steel)
	]
	_mesh(parent,_compile(parts))
	return {}

func signal_head(parent: Node3D) -> Dictionary:
	var post := material(Color("#333e47"),0.66,0.33)
	var housing := material(Color("#252f38"))
	var metal: Array[Dictionary] = [
		_rod(Vector3(0,2.2,0),4.4,0.08,0.13,post),
		_box(Vector3(0,4.07,0),Vector3(0.39,1.16,0.29),housing)
	]
	_mesh(parent,_compile(metal))
	var bulbs: Array[MeshInstance3D] = []
	for index in range(3):
		var colors := [Color("#ff4c3f"),Color("#ffcc3b"),Color("#63eda5")]
		var bulb: Array[Dictionary] = [_sphere(Vector3(0,4.42-0.34*index,-0.155),Vector3(0.23,0.23,0.095),material(colors[index],0.65,0,2.1))]
		bulbs.append(_mesh(parent,_compile(bulb)))
	return {"bulbs":bulbs}

func _siren_asset() -> AudioStreamWAV:
	if _siren != null:
		return _siren
	const RATE := 16000
	var waveform := PackedByteArray()
	waveform.resize(RATE * 4)
	var phase := 0.0
	for index in range(RATE*2):
		var seconds := float(index)/RATE
		var sweep := 0.5-0.5*cos(TAU*seconds/2.0)
		phase += TAU*(420.0+382.0*sweep)/RATE
		var value := int((sin(phase) + 0.17*sin(2.0*phase)) * 13400.0)
		waveform.encode_s16(index*2,value)
	_siren = AudioStreamWAV.new()
	_siren.format = AudioStreamWAV.FORMAT_16_BITS
	_siren.mix_rate = RATE
	_siren.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_siren.loop_end = RATE * 2
	_siren.data = waveform
	return _siren

func _engine_asset() -> AudioStreamWAV:
	if _engine != null:
		return _engine
	const RATE := 12000
	var waveform := PackedByteArray()
	waveform.resize(RATE * 2)
	for index in range(RATE):
		var elapsed := float(index)/RATE
		var low := sin(TAU * elapsed * 48.0)
		var rough := 0.40*sin(TAU * elapsed * 96.0)+0.18*sin(TAU * elapsed * 144.0)
		var idle_variation := 0.82+0.18*sin(TAU*elapsed*8.0)
		waveform.encode_s16(index*2,int((low+rough)*idle_variation*12600.0))
	_engine = AudioStreamWAV.new()
	_engine.format = AudioStreamWAV.FORMAT_16_BITS
	_engine.mix_rate = RATE
	_engine.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_engine.loop_end = RATE
	_engine.data = waveform
	return _engine
