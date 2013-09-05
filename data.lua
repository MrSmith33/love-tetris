-----------------------------------------------------------------------------------------------------------------------
------ Data

settings = {
	shadow = true
}

-- block look
block = {
	w = 10,
	h = 10,
	offset = 1
}

-- tetris color scheme
colors = {
	{255, 0, 0},
	{0, 0, 255},
	{255, 255, 0},
	{0, 128, 255},
	{255, 0, 255},
	{0, 255, 255},
	{255, 255, 255},
	{0, 255, 0}
}

-- list of possible figures
-- they are colored by its index in 'colors' list
figures = {
	{y=-1, '    ', '####', '    ', '    '},
	{y= 0, '#  ', '###', '   '},
	{y= 0, '  #', '###', '   '},
	{y=-1, '    ', ' ## ', ' ## ', '    '},
	{y= 0, ' ##', '## ', '   '},
	{y= 0, '## ', ' ##', '   '},
	{y= 0, ' # ', '###', '   '},

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

-- stores level info, such as score, game speed etc.
level = {
	running = false,
	game_over = false,
	fall_interval = 1,
	curr_interval = 0,

	score = 0,

	init = function()
		level.score = 0
		level.curr_interval = 0
		figure.current = figures.random_fig()
		figure.next = figures.random_fig()
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
		for y = 1, field.h do
			field[y] = {}
			for x = 1, field.w do
				field[y][x] = 0
			end
		end
	end
}

figure = {
	x = 4,
	y = 0,
	spawn = {x = 4, y = 0},
	current = {},
	next = {},
}