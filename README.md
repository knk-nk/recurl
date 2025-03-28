CLI utility script for "curl" written in Lua
(SEO crawler, batch FTP file modifier, RSS/sitemap generator and more)
> [!NOTE]
> Currently written for Windows only, but includes compatibility functions for Linux, and will be available on Linux systems soon

Includes recent curl binary for Windows:<br>
https://curl.se/windows/dl-8.12.1_4/curl-8.12.1_4-win64-mingw.zip

# Usage
1. [Download lua binaries for windows](https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download)
or install `lua` package on your Linux system (it will probably already be there though)
2. On Windows, unpack the Lua binaries anywhere, then set `lua54.exe` as a default program for all `.lua` files
3. Run `create_dirs.lua` script
4. That's all. Just run either `recurl.lua` or `recurl.debug.lua`
<br>

# Functions
### Website crawling
> Scans HTML contents of the website and writes recorded data in `files`, including `sitemap.xml`

### FTP file data replacement
> Connects to FTP server and replaces provided data

### RSS feeds generation
> Generates RSS feeds based on the content from the specified webpage

> [!WARNING]
> Experimental feature
<br>

# Directories
- `.netrc` FTP server login info
- `bak` FTP file backups
- `bin` curl binaries
- `files` All generated files (sitemaps, RSS, crawler results)
- `tasks` FTP file modification tasks
- `tmp` Modified FTP files that are being sent to the server
<br>

# Tasks
> [!NOTE]
> Information on Lua string patterns can be found [here](https://www.lua.org/pil/20.2.html)

> [!TIP]
> \* = Can be declared more than once

## Task values
- `root` Root directory of the website
- `fext` File extension (type)
- `fname` File name (you must choose either `fext` or `fname`)
- `excl` * Exclude paths containing the specified patterns
- `find` Find files containing the specified plain text
- `match` * Match strings in the file containing the specified pattern
- `repl` Replace matched strings with the specified plain text

## Example task file
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
