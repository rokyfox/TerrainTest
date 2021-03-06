extends Camera

onready var hud = get_node("../../HUD")
onready var terrain = get_node("../../Terrain")

var dist = 10  # Camera distance
var dir = deg2rad(180)  # y-rotation
var ang = 0  # Altitude angle

var rotating = false
var last_mouse = Vector2(0,0)
var last_p = Vector2(0,0) # Last mouse position on map, in pixels
var mouse_down = false # True if mouse was already down last frame

var rad = 10
var brush_spacing = 5
var dist_since_last_brush = 0.0

func mouse_move():
	var mouse = get_viewport().get_mouse_position()
	var from = project_ray_origin(mouse)
	var to = from + project_ray_normal(mouse) * 300
	var mouse_hit = get_world().get_direct_space_state().intersect_ray(from, to, [game.player], 1)
	
	if not mouse_hit.empty():
		var m_p = mouse_hit.position
		var p = Vector2(m_p.x/terrain.SCALE, m_p.z/terrain.SCALE)
		terrain.TOOL_SHADER.set_shader_param("pos", p)
		
		if hud.mode == 0 and Input.is_mouse_button_pressed(BUTTON_LEFT):
			if not mouse_down:
				terrain.save_img_hist()
			else:
				dist_since_last_brush += (p-last_p).length()
			if not mouse_down or dist_since_last_brush >= brush_spacing:
				dist_since_last_brush = 0.0
				hud.alter_zone_height(p, rad)
				terrain.update_rect(Rect2(p-Vector2(rad,rad), Vector2(rad*2,rad*2)))
			mouse_down = true
		else:
			mouse_down = false
		
		last_p = p

func _process(delta):
	if rotating:
		var mouse = get_viewport().get_mouse_position()
		var diff = mouse - last_mouse
		dir -= diff.x/100
		ang -= diff.y/100
		last_mouse = mouse
	
	set_translation(Vector3(0, 2, 0))
	set_rotation(Vector3(ang, dir, 0))
	translate_object_local(Vector3(0, 0, dist))

func _unhandled_input(event):
	if event is InputEventMouseButton:
		last_mouse = get_viewport().get_mouse_position()
		
		if event.button_index == BUTTON_RIGHT:
			if not event.pressed:
				rotating = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		var scroll = float(event.button_index == BUTTON_WHEEL_DOWN)-float(event.button_index == BUTTON_WHEEL_UP)
		
		if Input.is_key_pressed(KEY_SHIFT):
			rad -= scroll
			terrain.TOOL_SHADER.set_shader_param("rad", rad)
		else:
			dist += scroll
		
		if event.button_index == BUTTON_LEFT and event.pressed:
			mouse_move()
	
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_RIGHT) and (last_mouse-get_viewport().get_mouse_position()).length()>20:
			rotating = true
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			mouse_move()
