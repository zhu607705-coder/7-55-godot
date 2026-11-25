extends RefCounted
## Grid fallback for large-campus routes where a visibility graph has no
## collision corner to turn around a narrow mask-defined footpath.

const MAX_GRID_CELLS := 100000
const MAX_SEARCH_RING := 16

func plan(start: Vector2, goal: Vector2, world_size: Vector2, anchor_offset: Vector2, stand: Callable, clear: Callable) -> Array[Vector2]:
	var cell_size := 16.0
	var width := maxi(1, int(ceil(world_size.x / cell_size)))
	var height := maxi(1, int(ceil(world_size.y / cell_size)))
	if width * height > MAX_GRID_CELLS: return []
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, width, height)
	grid.cell_size = Vector2(cell_size, cell_size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if not stand.call(_anchor_for(cell, cell_size, anchor_offset)):
				grid.set_point_solid(cell, true)
	var start_cell := _nearest_open_cell(grid, _cell_for(start, anchor_offset, cell_size), start, cell_size, anchor_offset, stand, width, height)
	var goal_cell := _nearest_open_cell(grid, _cell_for(goal, anchor_offset, cell_size), goal, cell_size, anchor_offset, stand, width, height)
	if start_cell == Vector2i(-1, -1) or goal_cell == Vector2i(-1, -1): return []
	var points: PackedVector2Array = grid.get_point_path(start_cell, goal_cell, false)
	if points.is_empty(): return []
	var route: Array[Vector2] = []
	var previous := start
	for index in range(1, points.size()):
		var next := goal if index == points.size() - 1 else points[index] - anchor_offset
		if not stand.call(next) or not clear.call(previous, next): return []
		route.append(next)
		previous = next
	return route

func _anchor_for(cell: Vector2i, cell_size: float, anchor_offset: Vector2) -> Vector2:
	return Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size) - anchor_offset

func _cell_for(anchor: Vector2, anchor_offset: Vector2, cell_size: float) -> Vector2i:
	var foot := anchor + anchor_offset
	return Vector2i(int(floor(foot.x / cell_size)), int(floor(foot.y / cell_size)))

func _nearest_open_cell(grid: AStarGrid2D, requested: Vector2i, target: Vector2, cell_size: float, anchor_offset: Vector2, stand: Callable, width: int, height: int) -> Vector2i:
	var center := Vector2i(mini(maxi(requested.x, 0), width - 1), mini(maxi(requested.y, 0), height - 1))
	for ring in range(MAX_SEARCH_RING + 1):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		for y in range(center.y - ring, center.y + ring + 1):
			for x in range(center.x - ring, center.x + ring + 1):
				if max(abs(x - center.x), abs(y - center.y)) != ring: continue
				if x < 0 or y < 0 or x >= width or y >= height: continue
				var cell := Vector2i(x, y)
				if grid.is_point_solid(cell): continue
				var anchor := _anchor_for(cell, cell_size, anchor_offset)
				if not stand.call(anchor): continue
				var distance := anchor.distance_squared_to(target)
				if distance < best_distance:
					best_distance = distance
					best = cell
		if best != Vector2i(-1, -1): return best
	return Vector2i(-1, -1)
