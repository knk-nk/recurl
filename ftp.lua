-- FTP connection using curl
require 'shell'
local ftp = {}

function ftp:transfer(netrc_filepath, args)
	local args, s = (args or {}), ''
	if args.sftp then s = 's' end

	local path = args.path
	if netrc_filepath and not path then
		print('Please specify FTP directory/filename path')
		return 0
	end

	local file = args.file or ''
	if file ~= '' then
		file = '-T '..file..' '
	end

	local output
	if netrc_filepath then
		-- Will use the provided netrc file for credentials
		local host
		local netrc = io.open(netrc_filepath, 'r')
		for ln in netrc:lines() do
			if ln:match('machine') then
				host = ln:match('[ 	]+(.+)$')
			end
			if ln:match('sftp') then
				s = 's'
			end
		end
		netrc:close()
		local _args = string.format(
			'%s--netrc-file %s %sftp://%s%s',
			file, netrc_filepath, s, host, path
		)
		output = curl(_args)
	else
		-- Will prompt you for credentials
		io.write('Hostname: ')
		local host = io.read()
		io.write('Username: ')
		local usr = io.read()
		io.write('Password: ')
		local pwd = io.read()
		if not path then
			io.write('Transfer (FTP directory/filename) path: ')
			path = io.read()
		end
		local _args = string.format(
			'%s-u "%s:%s" %sftp://%s%s',
			file, usr, pwd, s, host, path
		)
		output = curl(_args)
	end

	return output
end

function ftp:get(netrc, path, is_sftp)
	return ftp:transfer(netrc, {path=path, sftp=is_sftp})
end

function ftp:send(netrc, file, path, is_sftp)
	return ftp:transfer(netrc, {file=file, path=path, sftp=is_sftp})
end

function ftp:help()
	local text = {
		'Quick tip: For directories, put "/" at the end of the path\n',
		'Basic syntax is:',
		"	ftp:get('my_netrc_file', '/some/path/on/ftp/server/file.ext')",
		"	ftp:send('my_netrc_file', 'file_to_send.ext', '/some/path/on/ftp/server/')",
		'\nBelow is the format of the netrc file:',
		'	machine <hostname_here>',
		'	login <username_here>',
		'	password <password_here>\n'
	}
	print(table.concat(text, '\n'))
end

return ftp
