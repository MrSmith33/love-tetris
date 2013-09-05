--- Tetris by Andrey Penechko
-----
--- Boost Software License - Version 1.0 - August 17th, 2003
-----

require 'data'

io.stdout:setvbuf("no")

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
	g.print('Score:'..level.score, g.getWidth() - 110, 24)
	for y=1, #figure.current do
		for x=1, #figure.current[1] do
			g.print(string.sub(figure.current[y], x, x), g.getWidth() - 90 + (x-1)*12, 36 + (y-1)*12)
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
	elseif key == 'up' then
		local new_fig = rotate_fig_left()
		if new_fig ~= nil then figure.current = new_fig end
	end 
end

------------------------------------------------------------
function fall()
	if not collision_at(figure.current, figure.x, figure.y + 1) then
		figure.y = figure.y + 1
	else
		on_floor_reached()
	end
end

function move_left()
	if not collision_at(figure.current, figure.x - 1, figure.y) then
		figure.x = figure.x - 1
	end
end

function move_right()
	if not collision_at(figure.current, figure.x + 1, figure.y) then
		figure.x = figure.x + 1
	end
end

-- returns rotated figure if it can be rotated
function rotate_fig_left()
	local new_fig = {}

	for x = 1, #figure.current do
		new_fig[x] = ''
		for y = #figure.current[1], 1, -1 do
			if string.sub(figure.current[y], x, x) == '#' then
				new_fig[x] = new_fig[x]..'#'
			else
				new_fig[x] = new_fig[x]..' '
			end
		end
	end

	if not collision_at(new_fig, figure.x, figure.y) then
		new_fig.index = figure.current.index
		return new_fig
	end
end

------------------------------------------------------------

-- 
function on_floor_reached()
	merge_figure()
	local lines_removed = test_lines()
	on_lines_removed(lines_removed)
	spawn_fig()
end

function on_lines_removed(num)
	if num == 0 then return end
	level.score = level.score + (2^(num-1)*100
end

function spawn_fig()
	figure.current = figure.next
	figure.next = figures.random_fig()
	figure.x = figure.spawn.x
	figure.y = figure.spawn.y
end

function test_lines()
	local lines_removed = 0

	for y = #field, 1, -1 do
		local all_filled = true
		for x = 1, #field[1] do
			if field[y][x] == 1 then
				all_filled = false
				break
			end
		end
		if all_filled then
			lines_removed = lines_removed + 1
			table.remove(field, y)
		end
	end
	for i = 1, lines_removed do
		table.insert(field, 1, {}) 
		for i=1, field.w do
			field[1][i] = 1
		end
	end
	return lines_removed
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

------------------------------------------------------------
--- Checks

-- returns true if figure collides
function collision_at(fig_to_test, test_x, test_y)
	local fig_height = #fig_to_test

	for y = 1, #fig_to_test do
		for x = 1, fig_to_test[1]:len() do
			if string.sub(fig_to_test[y], x, x) == '#' then
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