-----------------------------------------------------------------------------------------------------------------------
------ Data

settings = {
	
}

-- block look
block = {
	w = 11,
	h = 11,
	offset = 1 -- space between blocks
}

-- tetris color scheme
colors = {
	{255, 0, 0},
	{128, 0, 255},
	{255, 255, 0},
	{0, 128, 255},
	{255, 0, 255},
	{0, 255, 255},
	{255, 255, 255},
	{0, 255, 0}
}

init_audio = function ()
	for i,v in pairs(audiofiles) do
		audio[v] = love.audio.newSource(v..'.ogg', 'static')
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
	{' # ', '###', '   '},

	random_fig = function()
		local index = math.random(1, #figures)
		local figure = {}
		for _, line in ipairs(figures[index]) do
			table.insert(figure, line)
		end
		figure.index = index
		return figure
	end
}

rules = {
	shadow = true,
	gravity = 0, -- 0-disabled, 1-sticky, 2
	move_reset = false,
	spin_reset = false,
	hard_drop_lock_delay = false,
	rotation_system = 'simple', -- 'srs', 'dtet', 'tgm'. simple is only implemented
	wall_kick = false,

}

-- stores game info, such as score, game speed etc.
game = {
	state = '',--'running', 'clearing', 'game_over', 'spawning', 'paused'
	state_names = {running = 'Running', clearing = 'Clearing some mess',
					game_over = 'Game is over', paused = 'Paused'},
	fall_delay = 0.7,
	timer = 0,
	clear_delay = 0.5,
	lines_to_remove = {},

	score = 0,
	level = 1,

	init = function()
		game.score = 0
		game.level = 1
		game.curr_interval = 0
		figure.next = figures.random_fig()
		spawn_fig()
	end
}

-- field size and position
-- also stores blocks as two-dimentional array
-- '1' means no block, others are blocks and colored by the 'colors' table
field = {
	w = 10,
	h = 20,
	offset = {x = 100, y = 100},

	init = function ()
		for y = -1, field.h do
			field[y] = {}
			for x = 1, field.w do
				field[y][x] = 0
			end
		end
	end
}

figure = {
	x = 4,
	y = -1,
	current = {},
	next = {},
}