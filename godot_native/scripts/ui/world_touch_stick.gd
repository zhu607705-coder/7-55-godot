extends Control
## Presentation only. World owns the finger, movement, and collision checks.
var axis:=Vector2.ZERO
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;focus_mode=Control.FOCUS_NONE;z_index=95
func sync(rect:Rect2,value:Vector2)->void:
	visible=rect.has_area();position=rect.position;size=rect.size;axis=value;queue_redraw()
func _draw()->void:
	var radius:float=size.x*.5
	var center:=size*.5
	draw_circle(center,radius,Color(.10,.14,.12,.30))
	draw_arc(center,radius-1,0,TAU,64,Color(.85,.83,.72,.48),1.5,false)
	for index in 4:
		var direction:=Vector2.from_angle(index*PI/2)
		draw_line(center+direction*radius*.78,center+direction*radius*.88,Color(.85,.83,.72,.55),2,false)
	var knob:Vector2=center+axis.limit_length()*radius*.57
	draw_circle(knob+Vector2(1,2),radius*.31,Color(0,0,0,.2))
	draw_circle(knob,radius*.31,Color(.79,.78,.67,.68))
	draw_arc(knob,radius*.31,0,TAU,32,Color(.95,.91,.77,.7),1,false)
