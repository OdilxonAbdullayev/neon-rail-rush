extends Node3D
## NEON RAIL RUSH — original 3D arcade runner, Godot 4.4.1
## No external assets, plugins, accounts or servers required.

const LANES := [-3.15, 0.0, 3.15]
const PLAYER_Z := 3.0
const START_SPEED := 17.0
const MAX_SPEED := 34.0
const PLAYER_Y := 0.16
const SAVE_PATH := "user://neon_rail_rush.cfg"
const CYAN := Color("29f2e9")
const PINK := Color("ff4f9f")
const GOLD := Color("ffdd66")
const INK := Color("10172d")
const SLATE := Color("1d2944")
const TEXT := Color("f6f6ff")
const SUBTEXT := Color("a4b9d5")

var rng := RandomNumberGenerator.new()
var materials: Dictionary = {}
var running := false
var paused := false
var ended := false
var speed := START_SPEED
var elapsed := 0.0
var meters := 0.0
var bonus_score := 0
var coins := 0
var lifetime_coins := 0
var best_score := 0
var score := 0
var lane := 1
var jump_height := 0.0
var jump_velocity := 0.0
var slide_left := 0.0
var magnet_left := 0.0
var shield_left := 0.0
var spawn_left := 0.9
var run_anim := 0.0
var screen_touch := Vector2.ZERO
var screen_pressed := false
var cam_shake := 0.0
var muted := false
var spawned_waves := 0

var world: Node3D
var player: Node3D
var avatar: Node3D
var shadow: MeshInstance3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var camera: Camera3D
var tiles: Array[Node3D] = []
var objects: Array[Dictionary] = []
var scenery: Array[Node3D] = []
var canvas: CanvasLayer
var hud: Control
var menu: Control
var pause_ui: Control
var game_over_ui: Control
var score_label: Label
var coin_label: Label
var speed_label: Label
var magnet_label: Label
var shield_label: Label
var menu_best_label: Label
var final_score_label: Label
var final_detail_label: Label
var music: AudioStreamPlayer
var sound: AudioStreamPlayer

func _ready() -> void:
	rng.randomize()
	_load_save()
	_build_materials()
	_build_world()
	_build_player()
	_build_sound()
	_build_ui()
	_show_menu()

func _process(delta: float) -> void:
	if not running or paused or ended:
		_update_idle(delta)
		return
	elapsed += delta
	speed = minf(MAX_SPEED, START_SPEED + elapsed * 0.19)
	meters += speed * delta
	score = int(meters * 3.2) + bonus_score
	run_anim += delta * speed * 0.83
	_update_player(delta)
	_update_world(delta)
	_update_obstacles(delta)
	_update_camera(delta)
	magnet_left = maxf(magnet_left - delta, 0.0)
	shield_left = maxf(shield_left - delta, 0.0)
	spawn_left -= delta
	if spawn_left <= 0.0:
		_spawn_wave()
		spawn_left = clampf(1.55 - elapsed * 0.004, 0.95, 1.55)
	_update_hud()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_progress()
		if what == NOTIFICATION_APPLICATION_PAUSED and running and not paused:
			_pause_game()

func _make_mat(key: String, color: Color, metallic: float = 0.0, emission: float = 0.0) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.metallic = metallic
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	materials[key] = mat

func _build_materials() -> void:
	_make_mat("road", Color("151c32"))
	_make_mat("rail", Color("9bb9d5"), 0.85)
	_make_mat("tie", Color("2d3854"), 0.2)
	_make_mat("lane", Color("283454"))
	_make_mat("pavement", Color("26314b"))
	_make_mat("rail_glow", CYAN, 0.1, 1.2)
	_make_mat("pink", PINK, 0.0, 1.6)
	_make_mat("cyan", CYAN, 0.0, 1.6)
	_make_mat("gold", GOLD, 0.22, 1.6)
	_make_mat("blue", Color("4276ff"), 0.22, 0.65)
	_make_mat("white", Color("edf5ff"), 0.07)
	_make_mat("dark", Color("0a1025"), 0.15)
	_make_mat("train_a", Color("4055e7"), 0.25)
	_make_mat("train_b", Color("f44995"), 0.25)
	_make_mat("train_c", Color("1fa9a8"), 0.25)
	_make_mat("glass", Color("122346"), 0.25, 0.22)
	_make_mat("warning", Color("ff944d"), 0.0, 0.55)
	_make_mat("skin", Color("eec4a6"))
	_make_mat("hoodie", Color("6b54ef"), 0.07)
	_make_mat("pants", Color("263754"))
	_make_mat("cap", Color("12172d"))
	_make_mat("building_a", Color("243353"))
	_make_mat("building_b", Color("33325c"))
	_make_mat("building_c", Color("19374a"))
	_make_mat("window", Color("6cc8e8"), 0.0, 0.7)
	_make_mat("window_pink", Color("dc5cac"), 0.0, 0.6)
	_make_mat("shield", Color("78e6f7"), 0.1, 1.4)

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: String, name: String = "Box") -> MeshInstance3D:
	var obj := MeshInstance3D.new()
	obj.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	obj.mesh = mesh
	obj.material_override = materials[mat]
	obj.position = pos
	parent.add_child(obj)
	return obj

func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: String, name: String = "Ball") -> MeshInstance3D:
	var obj := MeshInstance3D.new()
	obj.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	obj.mesh = mesh
	obj.material_override = materials[mat]
	obj.position = pos
	parent.add_child(obj)
	return obj

func _cylinder(parent: Node3D, rad: float, length: float, pos: Vector3, mat: String) -> MeshInstance3D:
	var obj := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = rad
	mesh.bottom_radius = rad
	mesh.height = length
	mesh.radial_segments = 9
	obj.mesh = mesh
	obj.material_override = materials[mat]
	obj.position = pos
	parent.add_child(obj)
	return obj

func _build_world() -> void:
	world = Node3D.new()
	world.name = "MovingCity"
	add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("090c2c")
	sky_mat.sky_horizon_color = Color("3e3370")
	sky_mat.ground_bottom_color = Color("10162c")
	sky_mat.ground_horizon_color = Color("50446e")
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9cbbff")
	env.ambient_light_energy = 0.77
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -20, -10)
	sun.light_color = Color("d1dcff")
	sun.light_energy = 0.8
	add_child(sun)
	var neon := OmniLight3D.new()
	neon.position = Vector3(-5, 5, 8)
	neon.light_color = PINK
	neon.light_energy = 1.4
	neon.omni_range = 17.0
	add_child(neon)
	var neon_2 := OmniLight3D.new()
	neon_2.position = Vector3(6, 6, -17)
	neon_2.light_color = CYAN
	neon_2.light_energy = 1.4
	neon_2.omni_range = 20.0
	add_child(neon_2)
	camera = Camera3D.new()
	camera.position = Vector3(0, 7.2, 16.5)
	camera.fov = 62.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0, 1.3, -18), Vector3.UP)
	for i in range(13):
		var part := _make_tile(i)
		part.position.z = float(10 - i * 10)
		world.add_child(part)
		tiles.append(part)
	for i in range(20):
		var item := _make_city_block(i)
		item.position.z = 9.0 - float(i) * 7.8
		world.add_child(item)
		scenery.append(item)

func _make_tile(index: int) -> Node3D:
	var tile := Node3D.new()
	tile.name = "Track_%02d" % index
	_box(tile, Vector3(24, 0.25, 10.2), Vector3(0, -0.26, 0), "road")
	for lane_index in range(3):
		var x: float = LANES[lane_index]
		_box(tile, Vector3(2.9, 0.08, 10.0), Vector3(x, -0.1, 0), "lane")
		for rail_side in [-0.95, 0.95]:
			_box(tile, Vector3(0.14, 0.12, 10.0), Vector3(x + rail_side, 0.005, 0), "rail")
		for j in range(4):
			_box(tile, Vector3(2.46, 0.10, 0.34), Vector3(x, -0.07, -3.6 + float(j) * 2.4), "tie")
		_box(tile, Vector3(0.045, 0.025, 9.9), Vector3(x, -0.024, 0), "rail_glow")
	for side in [-1, 1]:
		_box(tile, Vector3(2.2, 0.26, 10.15), Vector3(float(side) * 6.7, -0.1, 0), "pavement")
		_box(tile, Vector3(0.13, 0.16, 10.0), Vector3(float(side) * 5.56, 0.08, 0), "pink" if side < 0 else "cyan")
	return tile

func _make_city_block(index: int) -> Node3D:
	var block := Node3D.new()
	block.name = "City_Block_%d" % index
	for side in [-1, 1]:
		if index % 3 == 0:
			var lamp_x := float(side) * 8.4
			_cylinder(block, 0.09, 5.3, Vector3(lamp_x, 2.65, 0), "rail")
			_box(block, Vector3(1.5, 0.21, 0.34), Vector3(lamp_x - float(side) * 0.75, 5.2, 0), "cyan" if side > 0 else "pink")
		var h := 8.0 + float((index * 7 + (1 if side == 1 else 4)) % 13)
		var x := float(side) * (12.8 + float(index % 3))
		var mat := "building_a" if (index + side) % 3 == 0 else ("building_b" if index % 2 == 0 else "building_c")
		_box(block, Vector3(5.2, h, 6.7), Vector3(x, h * 0.5 - 0.17, 0), mat)
		var face_x := x - float(side) * 2.65
		for floor_id in range(2, int(h) - 1, 4):
			for z_cell in [-1.7, 1.7]:
				if (floor_id + index + int(z_cell) * side) % 5 != 0:
					_box(block, Vector3(0.10, 0.9, 1.0), Vector3(face_x, float(floor_id), z_cell), "window" if (floor_id + index) % 4 else "window_pink")
		if index % 4 == 1:
			_box(block, Vector3(0.25, 1.15, 3.8), Vector3(face_x - float(side) * 0.14, 4.1, 0), "pink" if side < 0 else "cyan")
	return block

func _build_player() -> void:
	player = Node3D.new()
	player.name = "Runner"
	player.position = Vector3(0, PLAYER_Y, PLAYER_Z)
	add_child(player)
	shadow = _sphere(player, 0.58, Vector3(0, -0.13, 0), "dark", "Shadow")
	shadow.scale = Vector3(1.55, 0.075, 0.85)
	avatar = Node3D.new()
	avatar.name = "HeroMesh"
	player.add_child(avatar)
	# Hoodie, face, cap, small backpack and sneakers — all original meshes.
	_box(avatar, Vector3(0.88, 1.13, 0.53), Vector3(0, 1.65, 0), "hoodie", "Hoodie")
	_box(avatar, Vector3(0.94, 0.22, 0.55), Vector3(0, 1.02, 0), "dark", "Belt")
	_sphere(avatar, 0.40, Vector3(0, 2.46, -0.02), "skin", "Head")
	_box(avatar, Vector3(0.84, 0.22, 0.70), Vector3(0, 2.76, -0.02), "cap", "Cap")
	_box(avatar, Vector3(0.78, 0.07, 0.35), Vector3(0, 2.69, -0.37), "pink", "CapBill")
	_box(avatar, Vector3(0.56, 0.70, 0.28), Vector3(0, 1.73, 0.37), "blue", "Backpack")
	for eye_x in [-0.15, 0.15]:
		_sphere(avatar, 0.045, Vector3(eye_x, 2.47, -0.40), "dark")
	left_leg = Node3D.new()
	right_leg = Node3D.new()
	left_arm = Node3D.new()
	right_arm = Node3D.new()
	avatar.add_child(left_leg)
	avatar.add_child(right_leg)
	avatar.add_child(left_arm)
	avatar.add_child(right_arm)
	for d in [-1, 1]:
		var limb: Node3D = left_leg if d < 0 else right_leg
		limb.position = Vector3(float(d) * 0.25, 1.0, 0)
		_box(limb, Vector3(0.31, 0.8, 0.33), Vector3(0, -0.37, 0), "pants")
		_box(limb, Vector3(0.37, 0.18, 0.62), Vector3(0, -0.78, -0.13), "white")
		_box(limb, Vector3(0.38, 0.07, 0.65), Vector3(0, -0.87, -0.13), "cyan")
		var arm: Node3D = left_arm if d < 0 else right_arm
		arm.position = Vector3(float(d) * 0.58, 2.07, 0)
		_box(arm, Vector3(0.25, 0.67, 0.28), Vector3(0, -0.35, 0), "hoodie")
		_sphere(arm, 0.15, Vector3(0, -0.74, 0), "skin")

func _build_sound() -> void:
	music = AudioStreamPlayer.new()
	music.name = "OriginalMusic"
	music.stream = load("res://audio/neon_loop.wav")
	music.volume_db = -12.0
	if music.stream is AudioStreamWAV:
		(music.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	add_child(music)
	sound = AudioStreamPlayer.new()
	sound.volume_db = -6.0
	add_child(sound)

func _play_sfx(id: String) -> void:
	if muted:
		return
	var path := "res://audio/%s.wav" % id
	if ResourceLoader.exists(path):
		sound.stream = load(path)
		sound.play()

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "GameUI"
	add_child(canvas)
	var layer := Control.new()
	layer.name = "Root"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(layer)
	_build_hud(layer)
	menu = _build_modal(layer, "menu")
	_build_menu_content(menu)
	pause_ui = _build_modal(layer, "pause")
	_build_pause_content(pause_ui)
	game_over_ui = _build_modal(layer, "over")
	_build_over_content(game_over_ui)

func _style_panel(bg: Color, radius: int = 28, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2 if border.a > 0.0 else 0)
	style.border_color = border
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

func _label(text_value: String, font_size: int, color: Color = TEXT, center: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text_value: String, accent: Color, pressed: Callable, min_height: float = 86.0) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(0, min_height)
	b.add_theme_font_size_override("font_size", 25)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", _style_panel(accent, 22))
	b.add_theme_stylebox_override("hover", _style_panel(accent.lightened(0.14), 22))
	b.add_theme_stylebox_override("pressed", _style_panel(accent.darkened(0.18), 22))
	b.pressed.connect(pressed)
	return b

func _build_hud(root: Control) -> void:
	hud = Control.new()
	hud.name = "HUD"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := HBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 22
	top.offset_top = 45
	top.offset_right = -22
	top.offset_bottom = 155
	top.add_theme_constant_override("separation", 12)
	hud.add_child(top)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_label("NEON RAIL RUSH", 18, CYAN))
	score_label = _label("000000", 47)
	left.add_child(score_label)
	top.add_child(left)
	var right := VBoxContainer.new()
	right.add_child(_label("TANGALAR", 18, SUBTEXT, true))
	coin_label = _label("◆ 0", 33, GOLD, true)
	right.add_child(coin_label)
	top.add_child(right)
	var pb := _button("Ⅱ", Color("c0c7e9"), func() -> void: _pause_game(), 73)
	pb.custom_minimum_size.x = 74
	top.add_child(pb)
	var perks := HBoxContainer.new()
	perks.anchor_right = 1.0
	perks.offset_left = 26
	perks.offset_top = 158
	perks.offset_right = -26
	perks.offset_bottom = 208
	perks.add_theme_constant_override("separation", 15)
	hud.add_child(perks)
	speed_label = _label("17 km/s", 19, SUBTEXT)
	speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perks.add_child(speed_label)
	magnet_label = _label("", 19, PINK)
	perks.add_child(magnet_label)
	shield_label = _label("", 19, CYAN)
	perks.add_child(shield_label)
	var controls := HBoxContainer.new()
	controls.anchor_left = 0.0
	controls.anchor_right = 1.0
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_left = 21
	controls.offset_right = -21
	controls.offset_top = -147
	controls.offset_bottom = -29
	controls.add_theme_constant_override("separation", 12)
	hud.add_child(controls)
	var entries := [
		["◀", Color("90a7dc"), func() -> void: _change_lane(-1)],
		["▶", Color("90a7dc"), func() -> void: _change_lane(1)],
		["▲", CYAN, func() -> void: _jump()],
		["▼", PINK, func() -> void: _slide()]
	]
	for entry in entries:
		var button := _button(entry[0], entry[1], entry[2], 95)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.add_child(button)

func _build_modal(root: Control, screen_name: String) -> Control:
	var modal := Control.new()
	modal.name = screen_name
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(modal)
	var tint := ColorRect.new()
	tint.name = "Tint"
	tint.color = Color(0.035, 0.055, 0.14, 0.80)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(tint)
	var centering := CenterContainer.new()
	centering.name = "Center"
	centering.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centering.offset_left = 35
	centering.offset_right = -35
	modal.add_child(centering)
	var container := PanelContainer.new()
	container.name = "Card"
	container.custom_minimum_size = Vector2(0, 620)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_stylebox_override("panel", _style_panel(Color("131c38"), 32, Color("37557d")))
	centering.add_child(container)
	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 21)
	container.add_child(stack)
	return modal

func _modal_stack(modal: Control) -> VBoxContainer:
	return modal.get_node("Center/Card/Stack") as VBoxContainer

func _build_menu_content(modal: Control) -> void:
	var stack := _modal_stack(modal)
	stack.add_child(_label("✦  NEON CITY  ✦", 22, CYAN, true))
	stack.add_child(_label("RAIL\nRUSH", 91, TEXT, true))
	stack.add_child(_label("Yugur. Qoch. Rekordni yangila.", 26, SUBTEXT, true))
	stack.add_child(_label("3D METRO RUNNER   •   1.0", 18, PINK, true))
	menu_best_label = _label("ENG YAXSHI: 0", 25, GOLD, true)
	stack.add_child(menu_best_label)
	stack.add_child(_button("▶   O‘YINNI BOSHLASH", CYAN, func() -> void: _start_game()))
	stack.add_child(_label("◀ ▶  yo‘lakni almashtirish\n▲  sakrash    ▼  sirpanish\nEkranni surish ham mumkin", 21, SUBTEXT, true))
	stack.add_child(_button("♪   OVOZ YOQ / O‘CHIR", Color("9ca9d2"), func() -> void: _toggle_audio(), 65))

func _build_pause_content(modal: Control) -> void:
	var stack := _modal_stack(modal)
	stack.add_child(_label("Ⅱ", 100, CYAN, true))
	stack.add_child(_label("PAUZA", 65, TEXT, true))
	stack.add_child(_label("Qaytishga tayyormisan?", 25, SUBTEXT, true))
	stack.add_child(_button("▶   DAVOM ETISH", CYAN, func() -> void: _resume_game()))
	stack.add_child(_button("↻   QAYTADAN BOSHLASH", GOLD, func() -> void: _start_game()))
	stack.add_child(_button("⌂   BOSH MENYU", Color("a6b5d8"), func() -> void: _show_menu()))

func _build_over_content(modal: Control) -> void:
	var stack := _modal_stack(modal)
	stack.add_child(_label("✦   O‘YIN TUGADI   ✦", 27, PINK, true))
	stack.add_child(_label("YAXSHI\nURINISH!", 56, TEXT, true))
	final_score_label = _label("000000", 84, CYAN, true)
	stack.add_child(final_score_label)
	final_detail_label = _label("0 m  •  0 tanga", 22, SUBTEXT, true)
	stack.add_child(final_detail_label)
	stack.add_child(_button("↻   YANA O‘YNASH", CYAN, func() -> void: _start_game()))
	stack.add_child(_button("⌂   BOSH MENYU", Color("a6b5d8"), func() -> void: _show_menu()))

func _show_menu() -> void:
	running = false
	paused = false
	ended = false
	menu.visible = true
	pause_ui.visible = false
	game_over_ui.visible = false
	hud.visible = false
	menu_best_label.text = "ENG YAXSHI REKORD: %d" % best_score
	music.stream_paused = false
	_clear_obstacles()
	if not muted and not music.playing:
		music.play()

func _start_game() -> void:
	_clear_obstacles()
	running = true
	paused = false
	ended = false
	elapsed = 0.0
	meters = 0.0
	bonus_score = 0
	coins = 0
	score = 0
	speed = START_SPEED
	lane = 1
	jump_height = 0.0
	jump_velocity = 0.0
	slide_left = 0.0
	magnet_left = 0.0
	shield_left = 0.0
	spawn_left = 0.70
	spawned_waves = 0
	run_anim = 0.0
	avatar.scale = Vector3.ONE
	avatar.position = Vector3.ZERO
	player.position = Vector3(LANES[lane], PLAYER_Y, PLAYER_Z)
	menu.visible = false
	pause_ui.visible = false
	game_over_ui.visible = false
	hud.visible = true
	music.stream_paused = false
	if not muted and not music.playing:
		music.play()
	_play_sfx("start")
	_update_hud()

func _clear_obstacles() -> void:
	for object in objects:
		if is_instance_valid(object["node"]):
			(object["node"] as Node3D).queue_free()
	objects.clear()

func _pause_game() -> void:
	if not running or ended:
		return
	paused = true
	hud.visible = false
	pause_ui.visible = true
	music.stream_paused = true

func _resume_game() -> void:
	paused = false
	pause_ui.visible = false
	hud.visible = true
	music.stream_paused = false

func _end_game() -> void:
	if ended:
		return
	ended = true
	running = false
	_play_sfx("hit")
	cam_shake = 0.3
	lifetime_coins += coins
	best_score = maxi(best_score, score)
	_save_progress()
	final_score_label.text = "%06d" % score
	final_detail_label.text = "%d metr   ◆ %d tanga\nREKORD: %d" % [int(meters), coins, best_score]
	game_over_ui.visible = true
	hud.visible = false

func _update_player(delta: float) -> void:
	player.position.x = lerpf(player.position.x, LANES[lane], 1.0 - exp(-13.0 * delta))
	if jump_height > 0.0 or jump_velocity > 0.0:
		jump_velocity -= 26.0 * delta
		jump_height = maxf(0.0, jump_height + jump_velocity * delta)
		if jump_height <= 0.0:
			jump_velocity = 0.0
			jump_height = 0.0
	slide_left = maxf(0.0, slide_left - delta)
	player.position.y = PLAYER_Y + jump_height
	avatar.scale.y = lerpf(avatar.scale.y, 0.50 if slide_left > 0.0 else 1.0, minf(1.0, delta * 18.0))
	avatar.position.y = 0.0 if slide_left <= 0.0 else -0.06
	if jump_height < 0.08 and slide_left <= 0.0:
		left_leg.rotation.x = sin(run_anim) * 0.70
		right_leg.rotation.x = -sin(run_anim) * 0.70
		left_arm.rotation.x = -sin(run_anim) * 0.50
		right_arm.rotation.x = sin(run_anim) * 0.50
		avatar.rotation.z = sin(run_anim * 0.5) * 0.035
	else:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.3, delta * 10.0)
		right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.3, delta * 10.0)
		left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.20, delta * 10.0)
		right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.20, delta * 10.0)
		avatar.rotation.z = lerpf(avatar.rotation.z, 0.0, delta * 8.0)
	shadow.scale.x = 1.55 + jump_height * 0.3
	shadow.transparency = clampf(jump_height * 0.16, 0.0, 0.65)

func _update_idle(delta: float) -> void:
	if not paused:
		run_anim += delta
		if is_instance_valid(avatar):
			avatar.rotation.y = sin(run_anim * 0.45) * 0.06

func _update_world(delta: float) -> void:
	var dz := speed * delta
	for tile in tiles:
		tile.position.z += dz
		if tile.position.z > 19.9:
			tile.position.z -= float(tiles.size()) * 10.0
	for block in scenery:
		block.position.z += dz
		if block.position.z > 20.0:
			block.position.z -= float(scenery.size()) * 7.8

func _update_camera(delta: float) -> void:
	var target_x := player.position.x * 0.27
	camera.position.x = lerpf(camera.position.x, target_x, 1.0 - exp(-4.0 * delta))
	camera.fov = lerpf(camera.fov, 62.0 + (speed - START_SPEED) * 0.45, delta * 1.6)
	if cam_shake > 0.0:
		cam_shake = maxf(0.0, cam_shake - delta)
		camera.position.x += rng.randf_range(-cam_shake, cam_shake) * 0.06
	camera.look_at(Vector3(camera.position.x * 0.4, 1.2, -18), Vector3.UP)

func _spawn_wave() -> void:
	spawned_waves += 1
	var pattern := rng.randi_range(0, 5)
	var safe_lane := rng.randi_range(0, 2)
	var z := -79.0
	if pattern == 0:
		_spawn_obstacle("train", (safe_lane + 1) % 3, z)
	elif pattern == 1:
		_spawn_obstacle("barrier", (safe_lane + 1) % 3, z)
		_spawn_obstacle("barrier", (safe_lane + 2) % 3, z)
	elif pattern == 2:
		_spawn_obstacle("gate", (safe_lane + 1) % 3, z)
		_spawn_obstacle("train", (safe_lane + 2) % 3, z)
	elif pattern == 3:
		_spawn_obstacle("train", (safe_lane + 1) % 3, z)
		_spawn_obstacle("barrier", (safe_lane + 2) % 3, z)
	elif pattern == 4:
		_spawn_obstacle("gate", (safe_lane + 1) % 3, z)
		_spawn_obstacle("gate", (safe_lane + 2) % 3, z)
	else:
		_spawn_obstacle("barrier", (safe_lane + 1) % 3, z)
	# A safe lane is always available for every obstacle wave.
	for offset in range(4):
		_spawn_obstacle("coin", safe_lane, z - 5.0 - float(offset) * 3.0)
	if spawned_waves > 2 and rng.randf() < 0.15:
		_spawn_obstacle("magnet" if rng.randf() < 0.5 else "shield", safe_lane, z - 21.0)

func _spawn_obstacle(kind: String, lane_number: int, z: float) -> void:
	var root := Node3D.new()
	root.name = "%s_l%d" % [kind, lane_number]
	root.position = Vector3(LANES[lane_number], 0, z)
	world.add_child(root)
	match kind:
		"train":
			var color_id: String = ["train_a", "train_b", "train_c"][rng.randi_range(0, 2)]
			_box(root, Vector3(2.75, 3.15, 8.0), Vector3(0, 1.64, 0), color_id, "TrainBody")
			_box(root, Vector3(2.40, 1.25, 0.15), Vector3(0, 2.05, 4.09), "glass", "Windshield")
			_box(root, Vector3(2.6, 0.16, 0.17), Vector3(0, 0.8, 4.12), "white")
			for side in [-0.8, 0.8]:
				_box(root, Vector3(0.35, 0.20, 0.12), Vector3(side, 1.04, 4.20), "gold")
			for j in range(4):
				_box(root, Vector3(2.84, 0.85, 0.13), Vector3(0, 2.09, -3.1 + float(j) * 2.0), "glass")
			_box(root, Vector3(2.50, 0.12, 7.9), Vector3(0, 3.27, 0), "cyan")
		"barrier":
			_box(root, Vector3(2.5, 1.14, 0.55), Vector3(0, 0.56, 0), "warning")
			for j in range(3):
				_box(root, Vector3(0.54, 0.19, 0.59), Vector3(-0.74 + float(j) * 0.74, 0.71, 0), "white")
			_box(root, Vector3(2.6, 0.18, 0.60), Vector3(0, 1.19, 0), "pink")
		"gate":
			for side in [-1.15, 1.15]:
				_box(root, Vector3(0.23, 2.5, 0.33), Vector3(side, 1.25, 0), "blue")
			_box(root, Vector3(2.5, 0.57, 0.44), Vector3(0, 2.02, 0), "pink")
			_box(root, Vector3(2.18, 0.11, 0.47), Vector3(0, 1.65, 0), "white")
		"coin":
			var coin := _cylinder(root, 0.48, 0.10, Vector3(0, 1.42, 0), "gold")
			coin.rotation_degrees.x = 90.0
			_sphere(root, 0.14, Vector3(0, 1.43, 0.07), "white")
		"magnet":
			_box(root, Vector3(1.1, 1.1, 0.32), Vector3(0, 1.45, 0), "pink")
			_box(root, Vector3(0.65, 0.62, 0.36), Vector3(0, 1.45, -0.02), "white")
		"shield":
			_sphere(root, 0.74, Vector3(0, 1.35, 0), "shield")
			_box(root, Vector3(0.14, 0.80, 0.14), Vector3(0, 1.35, -0.66), "white")
	objects.append({"node": root, "kind": kind, "lane": lane_number, "z": z})

func _update_obstacles(delta: float) -> void:
	for i in range(objects.size() - 1, -1, -1):
		var item: Dictionary = objects[i]
		var obj: Node3D = item["node"]
		if not is_instance_valid(obj):
			objects.remove_at(i)
			continue
		var z: float = float(item["z"]) + speed * delta
		item["z"] = z
		obj.position.z = z
		var kind: String = item["kind"]
		if kind == "coin":
			obj.rotation.y += delta * 3.2
			obj.position.y = 0.12 * sin(elapsed * 5.0 + float(i))
		elif kind == "magnet" or kind == "shield":
			obj.rotation.y += delta * 2.2
			obj.position.y = 0.19 * sin(elapsed * 3.0 + float(i))
		if z > 16.0:
			obj.queue_free()
			objects.remove_at(i)
			continue
		var distance := absf(z - PLAYER_Z)
		var same_lane := absf(obj.position.x - player.position.x) < 1.08
		var has_magnet := magnet_left > 0.0 and kind == "coin" and absf(obj.position.x - player.position.x) < 4.4
		if (kind == "coin" or kind == "magnet" or kind == "shield") and distance < (6.0 if has_magnet else 1.25) and (same_lane or has_magnet):
			if kind == "coin":
				coins += 1
				bonus_score += 50
				_play_sfx("coin")
			elif kind == "magnet":
				magnet_left = 9.0
				_play_sfx("power")
			else:
				shield_left = 9.0
				_play_sfx("power")
			obj.queue_free()
			objects.remove_at(i)
			continue
		if (kind == "train" or kind == "barrier" or kind == "gate") and same_lane:
			var limit := 4.80 if kind == "train" else 0.80
			if distance < limit:
				var escaped := (kind == "barrier" and jump_height > 0.85) or (kind == "gate" and slide_left > 0.05)
				if not escaped:
					if shield_left > 0.0:
						shield_left = 0.0
						cam_shake = 0.34
						obj.queue_free()
						objects.remove_at(i)
						_play_sfx("power")
						continue
					_end_game()
					return

func _update_hud() -> void:
	score_label.text = "%06d" % score
	coin_label.text = "◆ %d" % coins
	speed_label.text = "TEZLIK  %d" % int(speed * 2.9)
	magnet_label.text = "MAGNIT  %.0fs" % magnet_left if magnet_left > 0.0 else ""
	shield_label.text = "HIMOYA  %.0fs" % shield_left if shield_left > 0.0 else ""

func _change_lane(direction: int) -> void:
	if not running or paused or ended:
		return
	lane = clampi(lane + direction, 0, 2)

func _jump() -> void:
	if not running or paused or ended:
		return
	if jump_height < 0.01 and slide_left <= 0.0:
		jump_velocity = 10.7
		jump_height = 0.03
		_play_sfx("jump")

func _slide() -> void:
	if not running or paused or ended:
		return
	if jump_height < 0.18:
		slide_left = 0.95
		_play_sfx("slide")

func _toggle_audio() -> void:
	muted = not muted
	music.volume_db = -80.0 if muted else -12.0
	if muted:
		music.stop()
	elif not music.playing:
		music.play()
	_save_progress()

func _unhandled_input(event: InputEvent) -> void:
	if not running or paused or ended:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			screen_pressed = true
			screen_touch = t.position
		elif screen_pressed:
			screen_pressed = false
			_handle_swipe(t.position - screen_touch)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_A, KEY_LEFT:
				_change_lane(-1)
			KEY_D, KEY_RIGHT:
				_change_lane(1)
			KEY_W, KEY_UP, KEY_SPACE:
				_jump()
			KEY_S, KEY_DOWN:
				_slide()
			KEY_ESCAPE, KEY_P:
				_pause_game()

func _handle_swipe(motion: Vector2) -> void:
	if motion.length() < 35.0:
		return
	if absf(motion.x) > absf(motion.y):
		_change_lane(1 if motion.x > 0 else -1)
	else:
		if motion.y < 0:
			_jump()
		else:
			_slide()

func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("stats", "best", 0))
		lifetime_coins = int(config.get_value("stats", "coins", 0))
		muted = bool(config.get_value("settings", "mute", false))

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("stats", "best", best_score)
	config.set_value("stats", "coins", lifetime_coins)
	config.set_value("settings", "mute", muted)
	config.save(SAVE_PATH)
