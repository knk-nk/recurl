require 'shell'

local rss_core = [[<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:yandex="http://news.yandex.ru" xmlns:media="http://search.yahoo.com/mrss/" xmlns:turbo="http://turbo.yandex.ru" version="2.0">
	<channel>
		<title>{TITLE}</title>
		<description>{DESC}</description>
		<link>{RSS_URL}</link>
		<pubDate>{DATE}</pubDate>
		<turbo:analytics type="Yandex" id="{COUNTER}"></turbo:analytics>
		<image>
			<url>{URL}{LOGO}</url>
			<link>{URL}</link>
			<title>{HEADING}</title>
		</image>

]]

local rss_item = [[
		<item turbo="true">
			<title>{TITLE}</title>
			<description>{DESC}</description>
			<pubDate>{DATE}</pubDate>
			<link>{LINK}</link>
			<turbo:content>
			<![CDATA[
				<header>
					<h1>{TITLE}</h1>
				</header>
				<h2>{TITLE}</h2>
				{CONTENT}
			/]/]>
			</turbo:content>
		</item>
]]

local function rss(src_url, rss_url, _dir, _timezone)
	local index, domain, page, items, sorted =
		src_url:match('(http[s]?://.-)/') or 'https://'..src_url,
		src_url:match('http[s]?://(.-)/'),
		curl(src_url), {}, {}

	-- Format {rss_url} string
	if not rss_url:match('^http') then
		rss_url = index..'/'..rss_url:gsub('^/', '')
	end

	-- Format {_dir} string, create directory
	if _dir then
		_dir = _dir:gsub('^/', '')
		if not _dir:match('/$') then
			_dir = _dir..'/'
		end
		mkdir(_dir)
	end

	-- Extract variables from curl output
	local var = {
		URL = index,
		RSS_URL = rss_url,
		TITLE = page:match('<title>(.-)</title>'),
		DESC =
			page:match('<meta[ 	]name=["\']description["\'][ 	]content="(.-)"')
			or page:match('<meta[ 	]content=["\'](.-)["\'][ 	]name=["\']description["\'][ ]?/>')
			or '',
		DATE = os.date('%a, %d %b %Y %H:%M:%S '..(_timezone or '+0000')),
		LOGO = page:match('src="([_%a%d/]+logo[.][%a]+)"') or '',
		COUNTER = page:match('ym[(]([%d]+),'),
		HEADING = page:match('<h1.->(.-)</h1>'),
	}
	var.HEADING = var.HEADING or var.TITLE

	-- Get the last word from the {src_url} path
	local last = src_url:gsub('/$', ''):gsub('.+/', '')

	-- Trial task: Get <a> tags and sort them into [link]{text,image} arrays
	for a in page:gmatch('<a .->.-</a>') do
		local link, img, txt =
			a:match('href="(.-)"'),
			a:match('<img.->'), nil

		if img then
			img = img:gsub('[	]', ''):gsub('\n', ' '):gsub('  ', '')
		end
		for t in a:gmatch('>(.-)<') do
			if utf8.len(t) > 35 then
				txt = t
			end
		end

		-- Create and merge arrays with identical links
		if link and (link:match(last) or (link:len() > 40)) then
			if not sorted[link] then
				sorted[link] = {
					txt = txt,
					img = img
				}
			else
				if not sorted[link].txt then
					sorted[link].txt = txt
				end
				if not sorted[link].img then
					sorted[link].img = img
				end
			end
		end
	end

	-- Apply {rss_item} mask to the resulting arrays and store them as strings
	for link, v in pairs(sorted) do
		if v.txt then
			local val = {
				TITLE = v.txt,
				DESC = v.desc or '',
				LINK = index..link,
				DATE = v.date or var.DATE,
				CONTENT = v.img
			}
			local str = rss_item:gsub('/%]/%]', ']]')
			for id in str:gmatch('{([%a]+)}') do
				local _v = (val[id] or ''):gsub('%%', '')
				str = str:gsub('{'..id..'}', _v)
			end
			table.insert(items, str)
		end
	end

	-- Construct and write XML file based on generated data
	local core = rss_core
	for v in core:gmatch('{[%a_]+}') do
		local id = v:match('{([%a_]+)}')
		if var[id] then
			core = core:gsub(v, var[id])
		end
	end

	local rss_fname = rss_url:gsub(index:gsub('[-]', '[-]')..'[/]?', ''):gsub('[%p]', '.')
	local f = io.open((_dir or '')..rss_fname, 'w')
	f:write(core .. table.concat(items, '\n') .. '\n	</channel>\n</rss>\n')
	f:close()
end

return rss
