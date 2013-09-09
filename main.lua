--- Tetris by Andrey Penechko
-----
--- Boost Software License - Version 1.0 - August 17th, 2003
-----

require 'data'

io.stdout:setvbuf("no")

----------------------------------------------------------------------------------------------------
------ Callbacks
----------------------------------------------------------------------------------------------------

function love.load()
	init_audio()
	start_game()
end

function love.update(dt)
	if game.state ~= 'game_over' then
		game.timer = game.timer - dt
		if game.timer < 0 then
			if game.state == 'running' then
				game.timer = game.timer + game.fall_delay
				fall()
			elseif game.state == 'clearing' then
				local lines_removed = #game.lines_to_remove
				for i = 1, #game.lines_to_remove  do
					table.remove(field, game.lines_to_remove[i])
				end
				for i = 1, lines_removed do
					table.insert(field, 1, {}) 
					for j=1, #field[2] do
						field[1][j] = 0
					end
				end
				on_lines_removed(lines_removed)
				game.state = 'running'
				spawn_fig()
			elseif game.state == 'spawning' then
				game.state = 'running'
				spawn_fig()
			end
		end
	end
end

g = love.graphics

------------------------------------------------------------
function love.draw()
	g.setColor(255, 255, 255)
	g.print('FPS:'..love.timer.getFPS(), g.getWidth() - 110, 0)
	g.print('Score:'..game.score, g.getWidth() - 110, 12)

	g.print('Move: left, right, down', g.getWidth() - 300, 0)
	g.print('Rotate: up', g.getWidth() - 300, 12)
	g.print('Drop: space', g.getWidth() - 300, 24)
	g.print('Pause: P', g.getWidth() - 300, 36)
	g.print('Restart: R (after "Game over")', g.getWidth() - 300, 48)

	for y=1, #figure.next do
		for x=1, #figure.next[1] do
			g.print(string.sub(figure.next[y], x, x),
					g.getWidth() - 90 + (x-1)*12, 36 + (y-1)*12)
		end
	end

	draw_field()

	if game.state == 'running' or game.state == 'paused' then
		draw_figure(figure.x, figure.y, draw_block)
		if rules.shadow then draw_shadow() end
	end

	g.setColor(255, 255, 255)
	string = game.state_names[game.state]
	if string ~= nil then
		g.printf(string, field.offset.x,
				field.offset.y + (block.h + block.offset)*field.h + 4, 
				((block.w + block.offset)*field.w), 'center')
	end
	
	
end

----------------------------------------------------------------------------------------------------
------ Draw
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
function draw_shadow()
	local shadow_y = figure.y

	while true do
		if not collides_with_blocks(figure.current, field, figure.x, shadow_y + 1) then
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
				drawer_func(_x + x - 1, _y + y - 1, colors[figure.current.index])
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
	if y <1 then return end

	g.setColor(color)
	local lx = field.offset.x + (x-1)*(block.w + block.offset)
	local ly = field.offset.y + (y-1)*(block.h + block.offset)
	g.rectangle("fill", lx, ly, block.w, block.h)

	g.setColor({0,0,0})
	-- makes nice hole in the figure with any figure size
	g.rectangle("fill", lx + math.ceil(block.w/4), ly + math.ceil(block.h/4),
						math.floor(block.w/2 - 0.25), math.floor(block.h/2 - 0.25))
end

----------------------------------------------------------------------------------------------------
------ Logic
----------------------------------------------------------------------------------------------------

function start_game()
	field.init()
	game.init()
	game.state = 'running'
end

function love.keypressed( key, isrepeat )
	if game.state == 'game_over' then 
		if key == 'r' then
			start_game()
		end
		return
	end

	if key == 'p' then
		if game.state == 'paused' then
			game.state = 'running'
		elseif game.state == 'running' then
			game.state = 'paused'
		end
	elseif game.state == 'running' then
		if key == 'down' then
		fall()
		elseif key == 'left' then
			move_left()
		elseif key == 'right' then
			move_right()
		elseif key == 'up' then
			local new_fig = rotate_fig_left()
			if not collides_with_blocks(new_fig, field, figure.x, figure.y) then
				new_fig.index = figure.current.index
				figure.current = new_fig
			end
		elseif key == ' ' then
			drop()
		end 
	end
end

------------------------------------------------------------
function drop()
	while true do
		if fall() then return end
	end
end

function fall()
	if not collides_with_blocks(figure.current, field, figure.x, figure.y + 1) then
		figure.y = figure.y + 1
		game.timer = game.fall_delay
		return false
	else
		on_floor_reached()
		return true
	end
end

function move_left()
	if not collides_with_blocks(figure.current, field, figure.x - 1, figure.y) then
		figure.x = figure.x - 1
	end
end

function move_right()
	if not collides_with_blocks(figure.current, field, figure.x + 1, figure.y) then
		figure.x = figure.x + 1
	end
end

-- returns rotated figure if it can be rotated
function rotate_fig_left()
	local new_fig = {}

	for y = 1, #figure.current[1] do
		new_fig[y] = ''
		for x = #figure.current, 1, -1 do
			if string.sub(figure.current[x], y, y) == '#' then
				new_fig[y] = new_fig[y]..'#'
			else
				new_fig[y] = new_fig[y]..' '
			end
		end
	end

	return new_fig
end

------------------------------------------------------------

-- 
function on_floor_reached()
	merge_figure(figure, field)

	if collides_with_spawn_zone(figure.current, field, figure.x, figure.y) then
		game.state = 'game_over'
		on_game_over()
		return
	end

	game.lines_to_remove = test_lines()

	if #game.lines_to_remove > 0 then
		game.state = 'clearing'
		game.timer = game.clear_delay
	else
		audio.drop:play()
		game.state = 'running'
		spawn_fig()
	end
end

function on_lines_removed(num)
	if num == 0 then return end

	game.score = game.score + (2^(num-1)*100)
	audio.clear1:play()
end

function on_game_over()
	audio.gameover:play()
end

function spawn_fig()
	figure.current = figure.next
	figure.next = game.random_fig()
	figure.x = math.ceil((#field[1])/2) - math.ceil((#figure.current[1])/2) + 1
	figure.y = -1

	if collides_with_blocks(figure.current, field, figure.x, figure.y) then
		game.state = 'game_over'
		on_game_over()
	end
end

function test_lines()
	local lines_to_remove = {}

	for y = #field, 1, -1 do
		local all_filled = true
		for x = 1, #field[1] do
			if field[y][x] == 0 then
				all_filled = false
				break
			end
		end
		if all_filled then
			table.insert(lines_to_remove, y)
		end
	end
	
	return lines_to_remove
end

-- merges figure into field
function merge_figure(figure, field)
	for y = 1, #figure.current do
		for x = 1, figure.current[1]:len() do
			if string.sub(figure.current[y], x, x) == '#' then
				field[y+figure.y - 1][x+figure.x - 1] = figure.current.index
			end 
		end
	end
end

------------------------------------------------------------
--- Checks

function collides_with_spawn_zone(fig_to_test, field, test_x, test_y)
	return collision_at(fig_to_test, test_x, test_y,
		function (field_x, field_y)	
			if field_y < 1 then return true	end 
		end)
end

function collides_with_blocks(fig_to_test, field, test_x, test_y)
	return collision_at(fig_to_test, test_x, test_y,
		function (field_x, field_y)
			if field[field_y] == nil or
				field[field_y][field_x] == nil or
				field[field_y][field_x] ~= 0 then
				return true
			end
		end)
end

-- returns true if figure collides. tester_fun(field_x, field_y)
function collision_at(fig_to_test, test_x, test_y, tester_fun)
	for y = 1, #fig_to_test do
		for x = 1, fig_to_test[1]:len() do
			if string.sub(fig_to_test[y], x, x) == '#' then
				if tester_fun(x + test_x - 1, y + test_y - 1) then return true end
			end
		end
	end

	return false
end