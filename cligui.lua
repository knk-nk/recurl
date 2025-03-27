local function cligui(args, ...)
	local args = args or {}
	local strings, out, strlen = {...}, {}, 0
	local mt, ml, pt, pl, bt, bl
	local mx, my, px, py = 0, 0, 0, 0

	-- Parse text arguments
	for i,v in ipairs(args) do
		args[v] = true
		args[i] = nil
	end

	-- Get short IDs
	args.margin = args.margin or args.m
	args.padding = args.padding or args.p
	args.border = args.border or args.b

	-- Length of longest string
	for i,v in ipairs(strings) do
		if v:len() > strlen then
			strlen = v:len()
		end
	end

	-- Margins
	if args.margin then
		mx = args.margin[1]
		my = args.margin[2]
		mt = string.rep('\n', my)
		ml = string.rep('  ', mx)
	else
		mt = ''; ml = ''
	end

	-- Paddings
	if args.padding then
		px = args.padding[1]
		py = args.padding[2]
		pt = py
		pl = string.rep('  ', px)
	else
		pt = 0; pl = ''
	end

	-- Borders
	if args.border then
		local by, bx, space = args.border, args.border, ' '
		if type(args.border) == 'table' then
			bx = args.border[1]
			by = args.border[2]
		end
		if args.nospace then
			space = by
		end
		bt = string.rep(by..space, math.floor(strlen/2)+(px*2)+2)
		bl = bx
	else
		bt = ''; bl = ''
	end

	-- Border: top
	table.insert(out, mt..ml..bt)

	-- Inner spacing: top
	local space = ml..bl..pl..string.rep(' ', strlen+1)..pl..bl
	for i = 1, pt do
		if pt > 0 then
			table.insert(out, space)
		end
	end

	-- Input string + X Borders
	for i,v in ipairs(strings) do
		v = ml..bl..pl..v..string.rep(' ',
			(strlen + (px*2)+1) - v:len() - (px*2)
		)..pl..bl
		table.insert(out, v)
	end

	-- Inner spacing: bot
	for i = 1, pt do
		if pt > 0 then
			table.insert(out, space)
		end
	end

	-- Border: bot
	table.insert(out, ml..bt)

	print(table.concat(out, '\n'))
	return table.concat(out, '\n')
end

return cligui
