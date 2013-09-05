--- Tetris by Andrey Penechko
-----
--- Boost Software License - Version 1.0 - August 17th, 2003
-----

require 'data'

io.stdout:setvbuf("no")

-----------------------------------------------------------------------------------------------------------------------
------ Callbacks

function love.load()
	start_game()
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
	g.print('FPS:'..love.timer.getFPS(), g.getWidth() - 110, 0)
	g.print('Score:'..level.score, g.getWidth() - 110, 12)
	for y=1, #figure.next do
		for x=1, #figure.next[1] do
			g.print(string.sub(figure.next[y], x, x), g.getWidth() - 90 + (x-1)*12, 36 + (y-1)*12)
		end
	end
	draw_field()
	if not level.game_over then
		draw_figure(figure.x, figure.y, draw_block)
		if settings.shadow then draw_shadow() end
	else
		g.setColor(255, 255, 255)
		g.printf('Game over', field.offset.x, field.offset.y + (block.h + block.offset)*field.h + 4, 
					((block.w + block.offset)*field.w), 'center')
	end
	
end

------------------------------------------------------------
function draw_shadow()
	local shadow_y = figure.y
	while true do
		if not collision_at(figure.current, figure.x, shadow_y + 1) then
			shadow_y = shadow_y + 1
		else
			break
		end
	end

	draw_figure(figure.x, shadow_y, function (x, y, color)
		draw_block(x, y, {color[1], color[2], color[3], 64})
	end)
end

------------------------------------------------------------
function draw_figure(_x, _y, drawer_func)
	for y = 1, #figure.current do
		for x = 1, #figure.current[1] do
			if string.sub(figure.current[y], x, x) == '#' then
				drawer_func(_x + x, _y + y, colors[figure.current.index])
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
			if field[y][x] ~= 0 then
				draw_block(x, y, colors[field[y][x]])
			end
		end
	end
end

------------------------------------------------------------
-- x, y [1 .. n]
function draw_block(x, y, color)
	g.setColor(color)
	local lx = field.offset.x + (x-1)*(block.w + block.offset)
	local ly = field.offset.y + (y-1)*(block.h + block.offset)
	g.rectangle("fill", lx, ly, block.w, block.h)
	g.setColor({0,0,0})
	g.rectangle("fill", lx + block.w/2 - 2, ly + block.h/2 - 2, 4, 4)
end

-----------------------------------------------------------------------------------------------------------------------
------ Logic

function start_game()
	level.init()
	field.init()
	level.running = true
	level.game_over = false
end

function love.keypressed( key, isrepeat )
	if level.game_over then 
		if key == 'r' then
			start_game()
		end
		return
	end

	if key == 'down' then
		fall()
	elseif key == 'left' then
		move_left()
	elseif key == 'right' then
		move_right()
	elseif key == 'up' then
		local new_fig = rotate_fig_left()
		if new_fig ~= nil then figure.current = new_fig end
	elseif key == ' ' then
		drop()
	end 
end

------------------------------------------------------------
function drop()
	while true do
		if fall() then return end
	end
end

function fall()
	if not collision_at(figure.current, figure.x, figure.y + 1) then
		figure.y = figure.y + 1
		return false
	else
		on_floor_reached()
		return true
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
	level.score = level.score + (2^(num-1)*100)
end

function spawn_fig()
	figure.current = figure.next
	figure.next = figures.random_fig()
	figure.x = figure.spawn.x
	figure.y = figure.spawn.y + figures[figure.current.index].y
	if collision_at(figure.current, figure.x, figure.y) then
		level.game_over = true
		level.running = false
	end
end

function test_lines()
	local lines_removed = 0

	for y = #field, 1, -1 do
		local all_filled = true
		for x = 1, #field[1] do
			if field[y][x] == 0 then
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
			field[1][i] = 0
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
					field[y + test_y][x + test_x] ~= 0 then
					return true
				end
			end
		end
	end

	return false
end