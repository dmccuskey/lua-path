# lua-path

Break file paths and `require` strings into their parts, and build them back, in plain Lua.

```lua
local Path = require 'lua_path'

local info = Path.parse( 'lib/dmc_ui/theme.lua' )
-- info.path = { 'lib', 'dmc_ui' }, info.name = 'theme', info.ext = 'lua'

print( Path.buildRequire( info ) )  -- lib.dmc_ui.theme
print( Path.buildPath( info ) )     -- lib/dmc_ui/theme.lua
```

## Features

- `parse()`: a path's folders, file name, name and extension, and whether it's absolute; a `require` string too, with separator `.`
- `buildPath()` and `buildRequire()`: a file path or a `require` string from those parts
- `getPath()`: a file's path inside a parsed folder
- `/` and `\` paths: the separator is guessed from the path and kept when it's built again
- Pure Lua 5.1, one file, no dependencies; MIT licensed

It works on strings only: it never looks at the file system. See [Known Issues](#known-issues).

## Quick Start

The following steps will get you up and running in about 5 minutes with Lua 5.1 on macOS or Linux. You will take a file path apart, turn it into a `require` string, and place files in a folder.

Prerequisites: Lua 5.1 (`lua -v` shows `Lua 5.1.x`) and git.

### 1. Get the Code

In an empty folder:

```sh
git clone https://github.com/dmccuskey/lua-path.git
```

`lua-path/dmc_lua/lua_path.lua` is the whole library.

### 2. Take Paths Apart and Build Them

Create `main.lua` in the same folder:

```lua
package.path = './lua-path/dmc_lua/?.lua;' .. package.path
local Path = require 'lua_path'

-- a file path: its parts, and the require string for it
local info = Path.parse( 'lib/dmc_ui/theme.lua' )
print( info.name, info.ext, #info.path )
print( Path.buildRequire( info ) )

-- a require string (separator '.') back to a file path
local mod = Path.parse( 'lib.dmc_ui.theme', '.' )
print( Path.buildPath( mod ) .. '.lua' )

-- files inside a folder; a Windows folder keeps its separator
local assets = Path.parse( '/app/assets/' )
print( assets:getPath( 'images/ship.png' ) )
print( Path.parse( 'C:\\game\\assets\\' ):getPath( 'ship.png' ) )
```

Run it:

```sh
lua main.lua
```

```text
theme	lua	2
lib.dmc_ui.theme
lib/dmc_ui/theme.lua
/app/assets/images/ship.png
C:\game\assets\ship.png
```

If it shows `module 'lua_path' not found`, run it from the folder that holds `lua-path/`.

`parse()` returns a table: `path` (the folders, a list), `filename`, `name`, `ext`, `isAbs`, `sep` (the separator it used), `original`, and `dir`, an empty list that `buildPath()` and `buildRequire()` put before `path`. Fill `dir` to put a path inside another folder. `buildPath()` and `buildRequire()` take a separator as a second argument to override the default: `\` for a path parsed with `\`, `/` otherwise, and `.` for a `require` string.

To update, pull the repository again (`git -C lua-path pull`), or replace `lua_path.lua` with the newer one.

## In Solar2D

The DMC Solar2D libraries carry a copy in their `dmc_corona/lib/dmc_lua/` folder, as part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library). [dmc-path](https://github.com/dmccuskey/dmc-path) is the Solar2D version: it loads this module from there.

## Known Issues

- **Only the last part of a path can be a file, and any dot makes it one.** `app/v1.2` is the folder `app` and a file named `v1` with extension `2`; `app/v1.2/` (with the slash) is two folders. `.hidden` is a file with no `name`, so `buildRequire()` leaves it out.
- **`buildRequire()` doesn't check that the result is a valid `require` string.** An absolute path starts it with a `.` (`/usr/x.lua` gives `.usr.x`), and `..` stays in (`../a.lua` gives `...a`).
- **Windows drive letters aren't recognized.** `C:\game\a.lua` isn't absolute, and `C:` is its first folder.
- The separator is one character: `split()` treats a longer one as a set of characters.

## Development

Only `dmc_lua/lua_path.lua` is written here. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies it into its `dmc_lua/` with its Snakemake build (the `Snakefile` here registers it), and the DMC Solar2D libraries copy it from there into `dmc_corona/lib/dmc_lua/`.

The code started as `dmc_corona/dmc_path.lua` in [dmc-path](https://github.com/dmccuskey/dmc-path) (version 0.1.0); it moved here because none of it needs Solar2D.

The tests are in `spec/lua_path_spec.lua`, for [busted](https://lunarmodules.github.io/busted/) under Lua 5.1. From the repository's root folder:

```sh
busted spec
```

```text
++++++++++++++++++++++++
24 successes / 0 failures / 0 errors / 0 pending : 0.002839 seconds
```

The tests cover each function, with `/` and `\` paths and `require` strings.

## License

lua-path is released under the [MIT License](LICENSE).
