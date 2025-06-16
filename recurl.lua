local ver = '0.1.0402.1805'
require 'shell'
local ftp = require 'ftp'
local cligui = require 'cligui'
local rss = require 'rss'
local html = {}
local allowed_ext = {'php', 'html'}
local domain, domain_match, pass, exclude, overall,
	  meta, totalPages, bkup, temp, links
local tdate = os.date('%Y-%m-%d_%H-%M-%S')

-- Change array to enum
for i,v in ipairs(allowed_ext) do
	allowed_ext[v] = i
end

-- Sitemap templates
local sitemap_temp =
[[<?xml version="1.0" encoding="utf-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">]]
local url_temp =
[[	<url>
		<loc>{URL}</loc>
		<lastmod>{DATE}</lastmod>
		<changefreq>monthly</changefreq>
		<priority>{DEPTH}</priority>
	</url>]]

-- Scan page for string patterns (expressions)
function html.gmatch(page, str)
	local found = {}
	print('EXPR: '..str)
	if str:len() > 2 then
		for x in page:gmatch(str) do
			if x then
				found.match = x
				table.insert(found, x)
				overall = overall + 1
			end
		end
	end
	print('EXPR match: '..(found.match or ''))
	print('EXPR found: '..#found)
end

-- Get page metadata
function html.meta(url, page)
	local url = url:gsub('^"', ''):gsub('"$', '')
	if url:match('[&?!#+;:]') then return end
	local metadata = {
		title = '<title>(.-)</title>',
		description = 'name=["\']description["\'] content=["\'](.-)["\']',
		--description_match2 = 'content=["\'](.-)["\'] name=["\']description["\']',
	}
	for i,v in pairs(metadata) do
		local dt = page:match(v)
		if dt and (dt ~= '') then
			if not meta[i][dt] then
				meta[i][dt] = {url}
			else
				table.insert(meta[i][dt], url)
			end
		else
			table.insert(meta[i]['(NOT_FOUND)'], url)
		end
	end
end

-- URL crawling recursive loop
local function crawl(url, expr)
	local url = url:gsub('^"', ''):gsub('"$', '')
	print('\nURL: '..url)
	local page = curl(url)

	-- Search for patterns
	if expr then html.gmatch(page, expr) end

	-- Get page metadata
	html.meta(url, page)

	-- Scan all href links
	for href in page:gmatch('href=["\'](.-)["\']') do
		local a = href:gsub('http[s]?://'..domain_match, ''):gsub(domain_match, '')
		local excluded = false

		-- Check if external
		if href:match('^http') and not href:match(domain_match) then
			if not links.external[href] then
				links.external[href] = 1
			end
		end

		-- Filter out excluded patterns
		for _,v in ipairs(exclude) do
			if a:match(v) then
				excluded = true
			end
		end

		-- Filter out unallowed extensions
		local ext = a:match('[.]([%a%d]+)$')
		if ext and (not allowed_ext[ext]) then
			excluded = true
		end

		-- Crawl internal link
		if (not excluded)
		and a:match('^[/]?[%a]')
		and (not a:match('^http[s]://'))
		and (not a:match('[.].-/'))
		and (not a:match('[/]?wp[-]'))
		and (not a:match('[&!#;:]')) then
			local slash = '/'
			if a:match('^/') then
				slash = ''
			end
			local root = domain
			local link = '"'..root..slash..a..'"'
			if not pass[link] then
				pass[link] = 1
				totalPages = totalPages + 1
				crawl(link, expr)
			end
			if not links.internal[slash..a] then
				links.internal[slash..a] = 1
			end
		end
	end
end

--[[ URL crawling main loop  | args:
	expr (str) - Match the following Lua pattern on each page
	excl (str) - Exclude pages that contains the following Lua patterns (one per whitespace)
	err_only (bool) - Display missing/duplicated metadata only
]]
local function run_crawl(url, args)
	local args = args or {}
	local expr = args.expr
	if expr == '' then expr = nil end
	local excl = args.excl or ''

	-- (Re-)Set variables
	exclude = {}
	overall = 0
	meta = {
		title={ ['(NOT_FOUND)']={} },
		description={ ['(NOT_FOUND)']={} },
		--description_match2={ ['(NOT_FOUND)']={} }
	}
	totalPages = 1
	links = { internal={}, external={} }

	-- Create directory
	local path = 'files/'..domain..'/'..tdate..'/'
	mkdir(path)

	-- Exclude URL patterns, if any set
	if excl ~= ' ' then
		for ref in excl:gmatch('(.-)[ ]') do
			table.insert(exclude, ref)
		end
	end

	-- Run crawler, print summary info
	local _, ERR = pcall(crawl, url, expr)
	if type(ERR) == 'string' then
		print(ERR)
	else
		print('\nEXPR overall count: '..overall)
		print('Inner links scanned: '..totalPages)
	end

	-- Write metadata
	local f = io.open(path..'meta.txt', 'w')
	local data_blocks = { 'Inner links scanned: '..totalPages }
	for i,v in pairs(meta) do
		table.insert(data_blocks, 'Meta: '..i)
		for text,links in pairs(v) do
			if not (args.err_only and (#links < 2)) then
				table.insert(data_blocks, string.format('	%s\n		%s\n',
					text, table.concat(links, '\n		')))
			end
		end
	end
	f:write(table.concat(data_blocks, '\n'))
	f:close()

	-- Write links
	local f = io.open(path..'links.txt', 'w')
	table.sort(links)
	for i,v in pairs(links) do
		f:write(i..':\n')
		for link in pairs(v) do
			f:write('	'..link..'\n')
		end
		f:write('\n')
	end
	f:close()

	-- Write sitemap
	local sitemap = {sitemap_temp}
	local DATE = os.date('%Y-%m-%d')
	local f = io.open(path..'sitemap.xml', 'w')
	for v in pairs(links.internal) do
		if not v:match('[&?!#+;:]') then
			local URL = 'https://'..domain..v:gsub('%%', '{PCNT}')
			local _,lvl = v:gsub('/', '')
			local DEPTH = 1.1 - tonumber('0.'..lvl)
			local entry = url_temp
				:gsub('{URL}', URL)
				:gsub('{DATE}', DATE)
				:gsub('{DEPTH}', DEPTH)
				:gsub('{PCNT}', '%%')
			table.insert(sitemap, entry)
		end
	end
	f:write(table.concat(sitemap, '\n')..'\n</urlset>')
	f:close()

	print '\nPress Enter to close'
	io.read()
end

-- FTP data manipulation loop
local function run_ftp(url)
	-- Check for .netrc
	local netrc = '.netrc/'..domain..'.netrc'
	local netrc_f = io.open(netrc, 'r')
	if netrc_f then
		print '[.netrc] Found'
		netrc_f:close()
	else
		print '[.netrc] File not found, requesting credentials...'
		io.write 'Hostname: '
		local hostname = io.read()
		io.write 'Login: '
		local usr = io.read()
		io.write 'Password: '
		local pwd = io.read()
		io.write 'Is SFTP? (y/N): '
		local sftp = io.read()
		if sftp ~= 'y' then
			sftp = nil
		end

		io.write 'Write this data to .netrc file? (Y/n):'
		local _write = io.read()
		if _write ~= 'n' then 
			local netrc_f = io.open(netrc, 'w')
			netrc_f:write('machine		'..hostname)
			netrc_f:write('\nlogin		'..usr)
			netrc_f:write('\npassword	'..pwd)
			if sftp then
				netrc_f:write('\nsftp		1')
			end
			netrc_f:close()
		end
	end

	-- Get website root directory
	local tasks, rootdir, tasklist = {}, nil, nil
	local f_tasks = io.open('tasks/'..domain..'.txt', 'r')
	if f_tasks then
		tasklist = f_tasks:read('*a')
		f_tasks:close()
		rootdir = tasklist:match('root[ 	](.-)[\n$]')
	else
		print 'Please specify the root directory path of the website:'
		rootdir = io.read()
	end
	if not rootdir:match('/$') then
		rootdir = rootdir..'/'
	end

	-- Check for grep.php
	local grep_php = curl(domain..'/grep.php')
	if grep_php:match('^<form action') then
		print '[grep.php] Found'
	else
		print('Sending [grep.php] to <FTP>'..rootdir..' ...')
		ftp:send(netrc, 'grep.php', rootdir)
	end

	-- Collect grep.php args/tasks
	if tasklist then
		local ind = 0
		for batch in tasklist:gmatch('\n([%a].-repl.-)\n') do
			-- Get file extension...
			local fext = batch:match('fext[ 	](.-)[\n]')
			-- ...Or filename
			local fname = batch:match('fname[ 	](.-)[\n]')

			if fname then fext = fname end
			if not tasks[fext] then
				tasks[fext] = {}
			end

			-- Get replace patterns
			local repl = batch:match('repl[ 	](.-)$')
			if not tasks[fext][repl] then
				tasks[fext][repl] = { M = {}, excl = {}, fname = fname }
			end
			pass[repl] = {}

			-- Get find_by_text
			local _find = batch:match('find[ 	](.-)[\n]')
			if not tasks[fext]._find then
				tasks[fext][repl]._find = _find
			end

			-- Get excluded patterns
			for exclude in batch:gmatch('excl[ 	](.-)[\n]') do
				table.insert(tasks[fext][repl].excl, exclude)
			end

			-- Get match patterns (Lua string.match)
			for _match in batch:gmatch('match[ 	](.-)[\n]') do
				table.insert(tasks[fext][repl].M, _match)
			end
		end
	else
		io.write 'File extension (optional) (default: php): '
		local fext = io.read()
		io.write 'Filename (optional): '
		local fname = io.read()
		io.write '[Lua] Exclude filepath by pattern (optional): '
		local excl = io.read()
		io.write '[Text] File contains: '
		local _find = io.read()
		io.write '[Lua] Pattern matches: '
		local _match = io.read()
		io.write '[Text] Replace pattern to: '
		local repl = io.read()

		if excl == '' then excl = nil end
		if fext == '' then fext = 'php' end
		if fname == '' then
			fname = nil
		else
			fext = fname
		end

		pass[repl] = {}
		tasks[fext] = {
			[repl] = {
				M = {_match},
				excl = {excl},
				fname = fname,
				_find = _find
			}
		}

		io.write 'Save this task? (y/N): '
		local save = io.read()
		if save == 'y' then
			local f = io.open('tasks/'..domain..'.txt', 'w')
			local fname_or_fext = 'fext	'
			if fname then
				fname_or_fext = 'fname	'
			end
			local lines = {
				'root	'..rootdir,
				'\n\n'..fname_or_fext..fext,
				'',
				'\nfind	'.._find,
				'\nmatch	'.._match,
				'\nrepl	'..repl..'\n'
			}
			if excl then
				lines[3] = '\nexcl	'..excl
			end
			f:write(table.concat(lines, ''))
			f:close()
		end
	end

	-- Run FTP server operations
	for fext, data in pairs(tasks) do
		if type(data) == 'table' then
			for repl, rules in pairs(data) do
				local fname = rules.fname
				for i, _match in pairs(rules.M) do
					local _find = rules._find or ''

					-- Obtain task info and send it to grep.php
					print('\n< File type:        '..fext)
					print('< Find by text:     '.._find)
					print('< Match pattern:    '.._match)
					print('< Replace pattern:  '..repl)
					local args = { grep = _find, ext = '.'..fext }
					if fname then
						args = { ['find'] = fname }
						print('< Find by name:     '..fname)
					end
					local found = curl('https://'..domain..'/grep.php', args)
					found = found:gsub('<pre>Code found[:]<br><br>', '<pre>Code found:<br><br>\n')

					-- File processing
					for fpath in found:gmatch('\n[.]/(.-)[:][%d]+[:]') do
						-- Check for excluded patterns in filepath
						local excluded
						for _,v in ipairs(rules.excl) do
							if fpath:match(v) then
								excluded = 1
							end
						end

						-- Get and modify file by filepath on the server
						if (not pass[repl][fpath]) and (not excluded) then
							-- Receive file
							pass[repl][fpath] = 1
							print('\n< Filepath queued:  '..fpath)
							local path_dir = domain..'/'..tdate..'/'..(fpath:match('.+/') or '')
							local path_doc = domain..'/'..tdate..'/'..fpath
							local file = ftp:get(netrc, rootdir..fpath)

							-- Backup received file
							if not bkup['bak/'..path_dir] then
								mkdir('bak/'..path_dir)
								bkup['bak/'..path_dir] = 1
							end
							if not bkup['bak/'..path_doc] then
								bkup['bak/'..path_doc] = 1
								local f_bak = io.open('bak/'..path_doc, 'w')
								if f_bak then
									f_bak:write(file)
									f_bak:close()
								else
									print('I/O Error: Incorrect path: bak/'..path_doc)
								end
							end

							-- Modify file
							if not file then
								print('Error: File not found: '..rootdir..fpath); return
							else
								local repl = repl:gsub('\\n', '\n'):gsub('[ ]+$', '')
								file = file:gsub(_match, repl)
							end

							-- Save modified version of the file and send it to the server
							if not temp['tmp/'..path_dir] then
								mkdir('tmp/'..path_dir)
								bkup['tmp/'..path_dir] = 1
							end
							if not temp['tmp/'..path_doc] then
								temp['tmp/'..path_doc] = 1
								local f_temp = io.open('tmp/'..path_doc, 'w')
								if f_temp then
									f_temp:write(file)
									f_temp:close()
									print('> send:  tmp/'..path_doc)
									print('> to:    <FTP>'..rootdir..(fpath:match('.+/') or ''))
									ftp:send(netrc, 'tmp/'..path_doc, rootdir..(fpath:match('.+/') or ''))
								else
									print('I/O Error: Incorrect path: tmp/'..path_doc)
								end
							end
						end
					end
				end
			end
		else
			print('The following file name/type is not found: '..fext)
		end
	end

	-- Run cleanup
	print 'Press Enter to run cleanup and close'
	io.read(); rmdir('tmp/'..domain)
end

-- Main loop
local function run(url)
	local url = url

	-- "Initial menu"
	if not url then
		cligui({ m={3,2}, p={2,2}, b='.' },
			'Recursive "curl"  v'..ver, '', 'Please specify website URL or domain')
		io.write '\n      > '
		url = io.read()
		clear()
	end

	-- (Re-)Set variables
	domain = url:gsub('http[s]:', ''):gsub('/', '')
	domain_match = url:gsub('[-]', '[-]'):gsub('[+]', '[+]'):gsub('[.]', '[.]')
	bkup = {}; temp = {}; pass = {}

	-- "Main menu"
	cligui({ m={3,1}, p={1,0}, b={'|', '-'}, 'nospace' }, 'Current domain: '..domain, 'Session date: '..tdate)
	cligui({ m={3,0}, p={2,2}, b='.' }, 'Recursive "curl"  v'..ver, '',
		'See the list below for available options.', 'Type preferred number and hit Enter.')
	cligui({ m={3,1} }, '1. Run website crawler')
	cligui({ m={3,0} }, '2. Modify data over FTP')
	cligui({ m={3,0} }, '3. Generate Turbo RSS (experimental)')
	cligui({ m={3,0} }, '0. Exit the program')
	cligui({ m={3,0} }, '(If none specified, go to previous menu)')
	io.write '\n      > '
	local sel = io.read()
	clear()

	if sel == '' then run() end
	if sel == '0' then os.exit() end
	if sel == '1' then
		local args = {}
		io.write 'Show missing/duplicated meta only? (Y/n): '
		local err_only = io.read()
		args.err_only = (err_only ~= 'n')
		io.write 'Search pattern [LUA_EXPR] (skip if none): '
		args.expr = io.read()
		print 'Exclude URL patterns (separated with whitespaces):'
		args.excl = io.read()..' '
		run_crawl(url, args)
	end
	if sel == '2' then run_ftp(url) end
	if sel == '3' then
		print 'Paste URL where the Blog page is located on the website:'
		local src_url = io.read()
		local dir = 'files/'..domain..'/'..tdate
		rss(src_url, 'rss.xml', dir, '+0300')
		print('Done. File location: '..dir..'\n\nPress Enter to close')
		io.read()
	end

	clear(); run(url)
end

_ENV.bin.curl = '.\\bin\\curl.exe'
run()
