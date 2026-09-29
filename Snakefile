# lua-path

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "lua-path"
	include: "../DMC-Lua-Library/snakemake/Snakefile"

module_config = {
	"name": "lua-path",
	"module": {
		"dir": "dmc_lua",
		"files": [
			"lua_path.lua"
		],
		"requires": []
	},
	"tests": {
		"dir": "spec",
		"files": [],
		"requires": []
	}
}

register( "lua-path", module_config )


