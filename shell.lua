if not _ENV.bin then _ENV.bin = {} end

-- Get system OS
local OS = 'Unix'
local OS_mobile = false
if os.getenv('PATH'):match(':\\') then
	OS = 'Windows'
elseif os.getenv('PATH'):match('/data/com.') then
	OS_mobile = true
end

-- Set global environment variables from commands
local GENV = {
	Unix = {
		CWD = 'pwd',
	},
	Windows = {
		CWD = 'echo %cd%',
	}
}
for v, cmd in pairs(GENV[OS]) do
	local p = io.popen(cmd)
	_ENV[v] = p:read('*a'):gsub('[\n].+', '')
	p:close()
end

-- Unix command: mkdir
function mkdir(...)
	local args = '-p '
	local paths = {...}
	for _,path in ipairs(paths) do
		if OS == 'Windows' then
			path = path:gsub('/', '\\')
			args = ''
		end
		local p = io.popen('mkdir '..args..path)
		p:close()
	end
end

-- Command: remove directory
function rmdir(path)
	if OS == 'Windows' then
		os.execute('rd /s /q "'..path..'"')
	else
		os.execute('rm -rf '..path)
	end
end

-- Unix command: curl
function curl(url, _form)
	local _curl = _ENV.bin.curl or 'curl'
	local form, formdata = {}, ' '
	if _form then
		for i,v in pairs(_form) do
			table.insert(form, i..'='..v)
		end
		formdata = 'd "'..table.concat(form, '&')..'" '
	end

	local p = io.popen(_curl..' -sL'..formdata..url)
	local content = p:read('*a')
	p:close()
	return content
end

-- Clear console
function clear()
	if OS == 'Windows' then
		os.execute 'cls'
	else
		os.execute 'clear'
	end
end
