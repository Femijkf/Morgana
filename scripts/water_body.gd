## This is the script that contains the water body
##it contains all the springs of our water
extends Node2D

#spring factor, dampening factor and spread factor
#spread factor dictacts how much the waves will spread to their neighbors
@export var k = 0.015
@export var d = 0.03
@export var spread = 0.0002

#the spring array
var springs = []
var passes = 8

#distance in pixels between each spring
@export var distance_between_springs = 32
#number of springs in a scene
@export var spring_number = 6

#total water body length
var water_length = distance_between_springs * spring_number

#spring scene reference
@onready var water_spring = preload("res://scenes/water_spring.tscn")

#the body of the water depth
@export var depth = 1000
var target_height = global_position.y
@onready var bottom = target_height + depth

#reference to our Polygon2D
@onready var water_polygon = $Water_Polygon

#reference to our water border
@onready var water_border = $Water_Border
@export var border_thickness = 0.5

@onready var collision_shape = $Water_Body_Area/CollisionShape2D
@onready var water_body_area = $Water_Body_Area

#initializes the spring array and all the springs
func _ready():
	water_border.width = border_thickness
	
	spread = spread / 1000
	#loops through all the springs
	#makes an array with all the springs
	#initializes each spring
	for i in range(spring_number):
		#the spring x position
		#they are generated from left to right ---> 0, 32, 64, 96...
		var x_position = distance_between_springs * i
		var w = water_spring.instantiate()
		
		add_child(w)
		springs.append(w)
		w.initialize(x_position, i)
		w.set_collision_width(distance_between_springs)
		w.connect("splash", splash)
	
	#calculates the total length of the water body
	var total_length = distance_between_springs * (spring_number - 1)
	
	#creates a new rectangle shape 2D
	var rectangle = RectangleShape2D.new().duplicate()
	
	#area position stays in the middle of the water body
	#the extents of the rectangle are half of the size of the water body
	var rect_position = Vector2(total_length/2, depth/2)
	var rect_extents = Vector2(total_length/2, depth/2)
	
	water_body_area.position = rect_position
	rectangle.set_size(rect_extents)
	collision_shape.set_shape(rectangle)

func _physics_process(delta):
	
	#moves all the springs accordingly
	for i in springs:
		i.water_update(k,d)
	
	#represents the movement of the left and right neighbors of the springs
	
	var left_deltas = []
	var right_deltas = []
	
	#initialize the values with the array of zeros
	for i in range (springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)
		pass
	
	for j in range(passes):
		#loops through each spring of our array
		for i in range(springs.size()):
			#adds velocity to the spring to the LEFT of the current spring
			if i > 0:
				left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
			#adds velocity to the spring to the RIGHT of the current spring
			if i < springs.size()-1:
				right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i]
	new_border()
	draw_water_body()
#this function adds a speed to a spring with this index

func draw_water_body():
	#gets the curve of the border
	var curve = water_border.curve
	
	#makes an array of the points in the curve
	var points = Array(curve.get_baked_points())
	
	#the water polygon will contain all the points of the surface
	var water_polygon_points = points
	
	#gets the first and last indexes of our surface array
	var first_index = 0
	var last_index = points.size()-1
	
	#add other two points at the bottom of the polygon, to close the water body
	water_polygon_points.append(Vector2(points[last_index].x, bottom))
	water_polygon_points.append(Vector2(points[first_index].x, bottom))
	
	#transforms our normal array into a packedvector2array
	#the polygon draw function uses packedvector2arrays to draw the polygon, so we converted it
	water_polygon_points = PackedVector2Array(water_polygon_points)
	
	water_polygon.set_polygon(water_polygon_points)
	pass

func new_border():
	#DRAW A NEW BORDER TO THE WATER
	
	#creates a new curve 2D
	var curve = Curve2D.new().duplicate()
	
	#creates a new array, that holds the positions of the surface points!!
	#we'll use those points to draw our border
	var surface_points = []
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
		
	#adds the points to the curve
	for i in range(surface_points.size()):
		curve.add_point(surface_points[i])
	
	water_border.curve = curve
	water_border.smooth(true)
	water_border.queue_redraw()
	
	pass

func splash(index, speed):
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
	pass


func _on_water_body_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
