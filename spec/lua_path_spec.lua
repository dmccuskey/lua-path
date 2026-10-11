--====================================================================--
-- spec/lua_path_spec.lua
--
-- Testing for lua-path using Busted
--====================================================================--


package.path = './dmc_lua/?.lua;' .. package.path


--====================================================================--
--== Test: Lua Path
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports


local Path = require('lua_path')



--====================================================================--
--== Testing Setup
--====================================================================--


describe( "Module Test: lua_path.lua", function()


	it( "exports its version", function()
		assert.is.equal( '0.3.0', Path.__version )
	end)


	describe( "Tests for split()", function()

		it( "splits on a separator, dropping empty parts", function()
			assert.are.same( { 'a', 'b', 'c' }, Path.split( '/a//b/c/', '/' ) )
		end)

		it( "splits on whitespace by default", function()
			assert.are.same( { 'one', 'two' }, Path.split( ' one  two ' ) )
		end)

		it( "treats a separator as plain text, not a pattern", function()
			assert.are.same( { 'a', 'b' }, Path.split( 'a%b', '%' ) )
			assert.are.same( { 'a', 'b' }, Path.split( 'a]b', ']' ) )
			assert.are.same( { 'a', 'b' }, Path.split( 'a.b', '.' ) )
		end)

	end)


	describe( "Tests for guessPathPlatform()", function()

		it( "picks the separator used most", function()
			assert.is.equal( '/', Path.guessPathPlatform( 'lib/dmc_ui/theme.lua' ) )
			assert.is.equal( '\\', Path.guessPathPlatform( 'lib\\ui\\a.png' ) )
			assert.is.equal( '/', Path.guessPathPlatform( 'theme.lua' ) )
		end)

	end)


	describe( "Tests for parse()", function()

		it( "parses a relative file path", function()
			local info = Path.parse( 'lib/dmc_ui/theme.lua' )
			assert.is_false( info.isAbs )
			assert.are.same( { 'lib', 'dmc_ui' }, info.path )
			assert.are.same( {}, info.dir )
			assert.is.equal( 'theme.lua', info.filename )
			assert.is.equal( 'theme', info.name )
			assert.is.equal( 'lua', info.ext )
			assert.is.equal( '/', info.sep )
			assert.is.equal( 'lib/dmc_ui/theme.lua', info.original )
		end)

		it( "parses an absolute file path", function()
			local info = Path.parse( '/usr/local/x.lua' )
			assert.is_true( info.isAbs )
			assert.are.same( { 'usr', 'local' }, info.path )
		end)

		it( "parses a folder, with no file", function()
			local info = Path.parse( 'lib/dmc_ui/' )
			assert.are.same( { 'lib', 'dmc_ui' }, info.path )
			assert.is_nil( info.filename )
			assert.is_nil( info.name )
		end)

		it( "takes a last part with a dot as a folder when the path ends with the separator", function()
			local info = Path.parse( 'app/v1.2/' )
			assert.are.same( { 'app', 'v1.2' }, info.path )
			assert.is_nil( info.filename )
			info = Path.parse( 'app\\v1.2\\' )
			assert.are.same( { 'app', 'v1.2' }, info.path )
			assert.is_nil( info.filename )
		end)

		it( "takes a last part with a dot as a file otherwise", function()
			local info = Path.parse( 'app/v1.2' )
			assert.are.same( { 'app' }, info.path )
			assert.is.equal( 'v1.2', info.filename )
		end)

		it( "gives a dotfile a name and no extension", function()
			local info = Path.parse( 'home/.hidden' )
			assert.are.same( { 'home' }, info.path )
			assert.is.equal( '.hidden', info.filename )
			assert.is.equal( '.hidden', info.name )
			assert.is_nil( info.ext )
			info = Path.parse( '.hidden.txt' )
			assert.is.equal( '.hidden', info.name )
			assert.is.equal( 'txt', info.ext )
		end)

		it( "gives a name ending with a dot no extension", function()
			local info = Path.parse( 'notes.' )
			assert.is.equal( 'notes.', info.filename )
			assert.is.equal( 'notes.', info.name )
			assert.is_nil( info.ext )
		end)

		it( "keeps '.' and '..' as folders", function()
			local info = Path.parse( 'a/..' )
			assert.are.same( { 'a', '..' }, info.path )
			assert.is_nil( info.filename )
			info = Path.parse( '.' )
			assert.are.same( { '.' }, info.path )
			assert.is_nil( info.filename )
			info = Path.parse( '../a.lua' )
			assert.are.same( { '..' }, info.path )
			assert.is.equal( 'a.lua', info.filename )
			assert.is.equal( '../a.lua', Path.buildPath( info ) )
		end)

		it( "keeps all but the last extension in the name", function()
			local info = Path.parse( 'a.tar.gz' )
			assert.is.equal( 'a.tar', info.name )
			assert.is.equal( 'gz', info.ext )
		end)

		it( "parses a Windows path", function()
			local info = Path.parse( 'lib\\ui\\a.png' )
			assert.is.equal( '\\', info.sep )
			assert.are.same( { 'lib', 'ui' }, info.path )
			assert.is.equal( 'a.png', info.filename )
		end)

		it( "parses a require string with separator '.'", function()
			local info = Path.parse( 'lib.dmc_ui.theme', '.' )
			assert.is_false( info.isAbs )
			assert.are.same( { 'lib', 'dmc_ui', 'theme' }, info.path )
			assert.is_nil( info.filename )
		end)

		it( "needs a string", function()
			assert.has.errors( function() Path.parse( nil ) end )
		end)

	end)


	describe( "Tests for buildPath() and buildRequire()", function()

		it( "builds a path and a require string", function()
			local info = Path.parse( 'lib/dmc_ui/theme.lua' )
			assert.is.equal( 'lib/dmc_ui/theme.lua', Path.buildPath( info ) )
			assert.is.equal( 'lib.dmc_ui.theme', Path.buildRequire( info ) )
		end)

		it( "keeps an absolute path absolute", function()
			local info = Path.parse( '/usr/local/x.lua' )
			assert.is.equal( '/usr/local/x.lua', Path.buildPath( info ) )
		end)

		it( "keeps the separator of a Windows path", function()
			local info = Path.parse( 'lib\\ui\\a.png' )
			assert.is.equal( 'lib\\ui\\a.png', Path.buildPath( info ) )
			assert.is.equal( 'lib/ui/a.png', Path.buildPath( info, '/' ) )
		end)

		it( "turns a require string into a path and back", function()
			local info = Path.parse( 'lib.dmc_ui.theme', '.' )
			assert.is.equal( 'lib.dmc_ui.theme', Path.buildRequire( info ) )
			assert.is.equal( 'lib/dmc_ui/theme', Path.buildPath( info ) )
		end)

		it( "puts dir before path", function()
			local parts = { dir={ 'app' }, path={ 'lib' }, filename='a.lua', name='a' }
			assert.is.equal( 'app/lib/a.lua', Path.buildPath( parts ) )
			assert.is.equal( 'app.lib.a', Path.buildRequire( parts ) )
		end)

		it( "builds no require string for an absolute path", function()
			local info = Path.parse( '/usr/x.lua' )
			assert.has.error.match( function() Path.buildRequire( info ) end, "path is absolute" )
		end)

		it( "builds no require string for a path with '.' or '..'", function()
			assert.has.error.match( function() Path.buildRequire( Path.parse( '../a.lua' ) ) end, "'%.%.' part" )
			assert.has.error.match( function() Path.buildRequire( Path.parse( './a.lua' ) ) end, "'%.' part" )
			assert.has.error.match( function() Path.buildRequire( Path.parse( 'a/../b.lua' ) ) end, "'%.%.' part" )
		end)

		it( "builds no require string for a part that contains the separator", function()
			assert.has.error.match( function() Path.buildRequire( Path.parse( 'app/v1.2/a.lua' ) ) end, "'v1%.2' contains" )
			assert.has.error.match( function() Path.buildRequire( Path.parse( 'a.tar.gz' ) ) end, "'a%.tar' contains" )
			assert.has.error.match( function() Path.buildRequire( Path.parse( 'home/.hidden' ) ) end, "'%.hidden' contains" )
			-- with another separator, a dot is fine
			assert.is.equal( 'app/v1.2/a', Path.buildRequire( Path.parse( 'app/v1.2/a.lua' ), '/' ) )
		end)

		it( "blames the caller for a path with no require string", function()
			local ok, err = pcall( function() Path.buildRequire( Path.parse( '/usr/x.lua' ) ) end )
			assert.is_false( ok )
			assert.is.truthy( err:find( 'lua_path_spec.lua', 1, true ) )
		end)

		it( "needs a table", function()
			assert.has.errors( function() Path.buildPath( 'a/b' ) end )
			assert.has.errors( function() Path.buildRequire( 'a.b' ) end )
		end)

	end)


	describe( "Tests for getPath()", function()

		it( "places a file in a parsed folder", function()
			local folder = Path.parse( '/app/assets/' )
			assert.is.equal( '/app/assets/images/a.png', folder:getPath( 'images/a.png' ) )
		end)

		it( "uses the folder of a parsed file", function()
			local file = Path.parse( 'lib/dmc_ui/theme.lua' )
			assert.is.equal( 'lib/dmc_ui/style.lua', file:getPath( 'style.lua' ) )
		end)

		it( "uses the separator of the folder", function()
			local folder = Path.parse( 'app\\assets\\' )
			assert.is.equal( 'app\\assets\\images\\a.png', folder:getPath( 'images/a.png' ) )
		end)

		it( "returns an absolute file path as it is", function()
			local folder = Path.parse( 'app/assets/' )
			assert.is.equal( '/tmp/a.png', folder:getPath( '/tmp/a.png' ) )
		end)

		it( "returns the folder for no file", function()
			local folder = Path.parse( 'app/assets/' )
			assert.is.equal( 'app/assets', folder:getPath() )
		end)

		it( "works with a table holding only dir", function()
			assert.is.equal( 'x/y/c/d.lua', Path.getPath( { dir={ 'x', 'y' } }, 'c/d.lua' ) )
		end)

	end)


end)
