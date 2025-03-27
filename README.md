CLI utility script for "curl" written in Lua
(seo crawler, batch ftp file modifier, rss/sitemap generator and more)
> Note: Currently written for Windows only, but includes compatibility functions for Linux and will be available on Linux systems soon

Includes recent curl binary for Windows:<br>
https://curl.se/windows/dl-8.12.1_4/curl-8.12.1_4-win64-mingw.zip

# Usage
1. [Download lua binaries for windows](https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download)
or install `lua` package on your Linux system (it will probably already be there though)
2. On Windows, unpack the Lua binaries anywhere, then open all `.lua` scripts with `lua54.exe`
3. Execute `create_dirs.lua` script
4. That's all. Just run either `recurl.lua` or `recurl.debug.lua`

# Directories
- `.netrc` FTP server login info
- `bak` FTP file backups
- `bin` curl binaries
- `files` All generated files (sitemaps, rss, crawler results)
- `tasks` FTP file modification tasks
- `tmp` Modified FTP files that are being sent to the server

# Tasks
Example task file:
```
root  /public_html/

fext	css
find	font-size: 10px
match	font[-]size:[ ]?10px
repl	font-size: 12px

fname	test.txt
find	123
match	123
repl	abc
```
Information on Lua string patterns can be found [here](https://www.lua.org/pil/20.2.html)
