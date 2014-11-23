-----------------------------------------------------------------------------------------------------------------------
------ Data

-- block look
block = {
	w = 15,
	h = 15,
	offset = 1 -- space between blocks
}

-- tetris color scheme
colors = {
	{0, 255, 255},
	{32, 64, 255},
	{255, 128, 0},
	{255, 255, 16},
	{255, 16, 255},
	{0, 255, 0},
	{255, 0, 0},
	{128, 0, 128}
}

init_audio = function ()
	for i,v in pairs(audiofiles) do
		audio[v] = love.audio.newSource('res/'..v..'.ogg', 'static')
	end
end

audiofiles = {
	'clear1',
	'drop',
	'gameover',
	--[[
	'spin',
	'move',
	'clear1',
	'clear2',
	'clear3',
	'clear4'
	]]
}

audio = {
}

-- list of possible figures
-- they are colored by their index in 'colors' list
figures = {
	{'    ', '####', '    '},
	{'#  ', '###', '   '},
	{'  #', '###', '   '},
	{'##', '##'},
	{' ##', '## ', '   '},
	{'## ', ' ##', '   '},
	{' # ', '###', '   '}
}

rules = {
	fps = 60,				-- frames per second.
	shadow = true, 			-- shadow piece.
	gravity = 0,			-- 0-disabled, 1-sticky, 2-cascade (only 0 implemented).
	num_previews = 2, 		-- number of preview pieces.
	move_reset = false,		-- reset timer on horizontal moves.
	spin_reset = false,		-- reset timer on rotation.
	hard_drop_lock_delay = false, -- delay piece locking after hard drop.
	wall_kick = false, 		-- wall kicks (not implemented).

	frame_delay = 1/60, 	-- defines framerate.
	lock_delay = 30, 		-- delay before piece locks.
	spawn_delay = 1, 		-- delay before piece spawns.
	clear_delay = 10, 		-- delay after piece locks and before next piece spawns.
	autorepeat_delay = 15, 	-- initilal delay.
	autorepeat_interval = 4, -- delay between moves.

	hard_levels_treshold = 60, -- how many levels before hard levels
	max_levels = 60,		-- determines max num of falls per sec
	-- hard_levels_treshold < max_levels
	-- delay = max_levels - level
	difficulty_modifier = 4, -- [1 - 1000] higher numbers means faster gravity increase
	-- 1 - for every 1000 points another level, 1000 for each point another level
	-- recommended values are [1-10]

	playfield_width = 10,	-- width of the playfield.
	playfield_height = 20,	-- height of the playfield. 2 invisible rows will be added.

	rotation_system = 'simple', -- 'srs', 'dtet', 'tgm'. simple is only implemented.
	randomizer = 'rg',-- 'stupid'-just math.random, 'rg'-7-bag, 'tgm'(not implemented).
	-- for hardcore gameplay try 'stupid' one.

	soft_gravity = {delay = 3, distance = 1} -- G = distance / delay. Params of the soft drop.
	-- delay means what delay is between piece fall. distance - number of blocks to fall.
}

-- stores game info, such as score, game speed etc.
game = {
	state = '',--'running', 'clearing', 'game_over', 'spawning', 'paused', 'on_floor'(when lock delay>0)
	state_names = {on_floor = 'On floor', clearing = 'Clearing full lines',
					game_over = 'Game over', paused = 'Paused', in_air = 'Falling', spawning = 'Spawning'},
	last_state = '', -- stores state before pausing

	timer = 0, -- time accumulator, increases each update, in seconds
	
	frame = 1, -- frame counter, increases by 1 each frame
	autorepeat_timer = 1, -- key autorepeat timer, in frames
	hold_timer = 1, --in frames, frames since left or right is holded

	gravity = 1, -- current gravity mode. 1 - normal, 2 - soft. Used as index in gravities
	gravities = {{delay = rules.num_levels, distance = 1}, rules.soft_gravity}, -- delay with which figure fall occurs.

	hold_dir = 0, -- -1 left, 1 right, 0 none

	lines_to_remove = {},

	score = 0,
	level = 1,
	level_name = 1,

	init = function()
		math.randomseed( os.time() )

		love.window.setTitle("LÖVE Tetris")
		love.window.setMode(500, 600)

		game.score = 0
		game.level = 1
		game.curr_interval = 0
		game.frame_delay = 1/rules.fps
		game.frame_timer = 0
		game.update_difficulty()
		game.history = {}
		game.random_gen_data = {}
		figure.next = {}
		for i=1, rules.num_previews do
			table.insert(figure.next, game.random_fig())
		end
		spawn_fig()
	end,

	history = {},
	random_gen_data = {},

	random_fig = function()
		local result = randomizers[rules.randomizer](game.history, game.random_gen_data)

		local figure = {}
		for _, line in ipairs(figures[result]) do
			table.insert(figure, line)
		end
		figure.index = result
		table.remove(game.history)
		table.insert(game.history, 1, result)
		return figure
	end,

	points_for_cleared_lines = function (num_cleared_lines)
		return (2^(num_cleared_lines-1)*100)
	end,

	update_difficulty = function()
		game.level = math.floor(game.score / (1000 / rules.difficulty_modifier)) + 1

		if game.level <= rules.hard_levels_treshold then
			game.gravities[1].delay = rules.max_levels - game.level
			game.level_name = tostring(game.level)
		else
			game.gravities[1].delay = 4
			game.gravities[1].distance = game.level - rules.hard_levels_treshold
			game.level_name = "Hard " .. game.gravities[1].distance
		end
	end
}

-- field size and position
-- also stores blocks as two-dimentional array
-- '1' means no block, others are blocks and colored by the 'colors' table
field = {
	w = 0,
	h = 0,
	offset = {x = 20, y = 100},

	init = function ()
		field.w = rules.playfield_width
		field.h = rules.playfield_height
		for y = -1, field.h do
			field[y] = {}
			for x = 1, field.w do
				field[y][x] = 0
			end
		end
	end
}

figure = {
	x = 0,
	y = 0,
	current = {},
	next = {}, -- array of figures
}

randomizers = {
	stupid = function(history, data)
		local index = math.random(1, #figures)
		return index
	end,
	rg = function(history, bag)
		if #bag == 0 then
			for i=1, #figures do
				bag[i] = i
			end
			shuffle_array(bag)
		end
		result = bag[1]
		table.remove(bag, 1)
		
		return result
	end
}

function shuffle_array(array)
	local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        array[counter], array[index] = array[index], array[counter]
        counter = counter - 1
    end
end