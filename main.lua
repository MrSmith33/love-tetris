io.stdout:setvbuf("no")

-----------------------------------------------------------------------------------------------------------------------
------ Data

level = {
	running = false,
	fall_interval = 0.5,
	curr_interval = 0,

	score = 0,

	init = function()
		level.score = 0
		level.curr_interval = 0
		figure.current = figures.random_fig()
		figure.next = figures.random_fig()
	end
}

field = {
	w = 10,
	h = 20,
	offset = {x = 100, y = 100},

	init = function ()
		for y = 1, field.h do
			field[y] = {}
			for x = 1, field.w do
				field[y][x] = 1
			end
		end
	end
}

block = {
	w = 10,
	h = 10,
	offset = 1
}

colors = {
	{0, 0, 0},
	{255, 0, 0},
	{0, 0, 255},
	{255, 255, 0},
	{0, 0, 255},
	{255, 0, 255},
	{0, 255, 255},
	{255, 255, 255},
	{0, 255, 0}
}

-- color == index
figures = {
	{'    ', '####', '    ', '    '},
	{'#  ', '###', '   '},
	{'  #', '###', '   '},
	{'    ', ' ## ', ' ## ', '    '},
	{' ##', '## ', '   '},
	{'## ', ' ##', '   '},
	{' # ', '###', '   '},

	random_fig = function()
		local index = math.random(1, #figures)
		local figure = {}
		for _, line in ipairs(figures[index]) do
			table.insert(figure, line)
		end
		figure.index = index + 1
		return figure
	end
}

figure = {
	x = 4,
	y = 1,
	spawn = {x = 4, y = 1},
	current = {},
	next = {},
}

-----------------------------------------------------------------------------------------------------------------------
------ Callbacks

function love.load()
	level.init()
	field.init()
	spawn_fig()
	level.running = true
end

function love.update(dt)
	if level.running then
		level.curr_interval = level.curr_interval + dt

		if level.curr_interval > level.fall_interval then
			level.curr_interval = level.curr_interval - level.fall_interval
			fall()
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
------ Draw

g = love.graphics

------------------------------------------------------------
function love.draw()
	g.setColor(255, 255, 255)
	g.print('FPS:'..love.timer.getFPS(), g.getWidth() - 90, 0)
	g.print('Fig:'..figure.current.index, g.getWidth() - 90, 12)
	for y=1, #figure.current do
		for x=1, #figure.current[1] do
			g.print(string.sub(figure.current[y], x, x), g.getWidth() - 90 + (x-1)*12, 24 + (y-1)*12)
		end
	end
	draw_field()
	draw_figure()
end

------------------------------------------------------------
function draw_figure()
	for y = 1, #figure.current do
		for x = 1, #figure.current[1] do
			if string.sub(figure.current[y], x, x) == '#' then
				draw_block(figure.x + x, figure.y + y, colors[figure.current.index])
			end
		end
	end
end

------------------------------------------------------------
function draw_field()
	g.rectangle("line", field.offset.x - 2, field.offset.y - 2,
						(block.w + block.offset)*field.w + 4,
						(block.h + block.offset)*field.h + 4)

	for y = 1, field.h do
		for x = 1, field.w do
			draw_block(x, y, colors[field[y][x]])
		end
	end
end

------------------------------------------------------------
-- x, y [1 .. n]
function draw_block(x, y, color)
	g.setColor(color)
	g.rectangle("fill", field.offset.x + (x-1)*(block.w + block.offset),
						field.offset.y + (y-1)*(block.h + block.offset),
				 		block.w, block.h)
end

-----------------------------------------------------------------------------------------------------------------------
------ Logic

function love.keypressed( key, isrepeat )
	if key == 'down' then
		fall()
	elseif key == 'left' then
		move_left()
	elseif key == 'right' then
		move_right()
	end 
end

------------------------------------------------------------
function fall()
	if not collision_at(figure.x, figure.y + 1) then
		figure.y = figure.y + 1
	else
		on_floor_reached()
	end
end

function move_left()
	if not collision_at(figure.x - 1, figure.y) then
		figure.x = figure.x - 1
	end
end

function move_right()
	if not collision_at(figure.x + 1, figure.y) then
		figure.x = figure.x + 1
	end
end

-- returns true if was rotated
function rotate_fig(figure)
	local new_fig

	for y = 1, #figure.current[1] do
		for x = 1, #figure.current do
			if string.sub(figure.current[y], x, x) == '#' then
				if field[y + test_y] == nil or
					field[y + test_y][x + test_x] == nil or
					field[y + test_y][x + test_x] ~= 1 then
					return true
				end
			end
		end
	end
end

------------------------------------------------------------

function spawn_fig()
	figure.current = figure.next
	figure.next = figures.random_fig()
	figure.x = figure.spawn.x
	figure.y = figure.spawn.y
end

-- merges figure into field
function merge_figure()
	for y = 1, #figure.current do
		for x = 1, figure.current[1]:len() do
			if string.sub(figure.current[y], x, x) == '#' then
				field[y+figure.y][x+figure.x] = figure.current.index
			end
		end
	end
end

-- 
function on_floor_reached()
	merge_figure()
	spawn_fig()
end

------------------------------------------------------------
--- Checks

-- returns true if figure collides
function collision_at(test_x, test_y)
	local fig_height = #figure.current

	for y = 1, #figure.current do
		for x = 1, figure.current[1]:len() do
			if string.sub(figure.current[y], x, x) == '#' then
				if field[y + test_y] == nil or
					field[y + test_y][x + test_x] == nil or
					field[y + test_y][x + test_x] ~= 1 then
					return true
				end
			end
		end
	end

	return false
end