--!strict
-- Test-suite loader: resolves lib-js packages the way the Rojo DataModel does.
--
-- Packages require each other three ways, all mirroring how Rojo assembles
-- `packages/` into one `ReplicatedStorage/lib-js` container:
--   `@self/name`     — a sibling module in the same package directory
--   `../Pkg`         — a package by its DataModel node name (`ES17-Types`, ...)
--   `../../Pkg`      — same, from a `prototype/` subdirectory
--   `./Pkg`          — same, used by single-dir packages (`map` requires `./Symbol`)
-- Luau's own `require` only understands real paths, so this loader re-reads
-- each module through `loadstring` with a shim `require` in its environment.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

-- Repo root: walk up from this script's directory until `packages/` appears.
-- (`lune run tests/foo.luau` starts the shell in the repo root, but that is
-- not guaranteed, so the script's own path is the anchor.)
local function scriptPath(): string
	return (debug.info(1, "s"):gsub("%.[^./\\]*$", ""))
end

local ROOT: string
do
	local dir = scriptPath():gsub("[/\\][^/\\]*$", "")
	while dir ~= "" do
		if fs.isDir(`{dir}/packages`) then
			ROOT = dir
			break
		end
		dir = dir:gsub("[/\\][^/\\]*$", "")
	end
	assert(ROOT ~= nil, "tests/_loader: could not locate the repository root")
end

-- name -> "packages/<dir>", from each package's default.project.json
local PACKAGE_DIRS: { [string]: string } = {}
for _, dir in fs.readDir(`{ROOT}/packages`) do
	local manifest = `{ROOT}/packages/{dir}/default.project.json`
	if fs.isFile(manifest) then
		local tree = serde.decode("json", fs.readFile(manifest)) :: any
		PACKAGE_DIRS[tree.name] = `packages/{dir}`
	end
end

local cache: { [string]: any } = {}

local function dirname(path: string): string
	return (path:match("^(.*)/[^/]+$")) or "."
end

-- `packages/foo/src/prototype/bar.luau` -> `@self/bar` resolves to the
-- directory the requiring file lives in, exactly like Rojo's `@self`.
local function resolve(moduleDir: string, name: string): string?
	local rel = name:gsub("^@self/", "")
	local isSiblingRequire = rel ~= name

	local base = nil
	if rel:sub(1, 3) == "../" then
		base = rel:sub(4)
	elseif rel:sub(1, 2) == "./" then
		base = rel:sub(3)
	end

	-- `../ES17-Types`, `../../ECMAScript`, `./Symbol`: a package reference by
	-- its DataModel node name, from any depth inside another package.
	if base ~= nil then
		local pkgName = base:match("^([%w%-]+)$") or base:match("^%.%./([%w%-]+)$")
		if pkgName ~= nil and PACKAGE_DIRS[pkgName] ~= nil then
			return `{PACKAGE_DIRS[pkgName]}/src/init.luau`
		end
	end

	-- Plain relative / `@self` path: collapse `.` and `..` textually.
	local parts: { string } = {}
	for segment in (moduleDir .. "/" .. rel):gmatch("[^/]+") do
		if segment == ".." then
			table.remove(parts)
		elseif segment ~= "." then
			table.insert(parts, segment)
		end
	end
	local path = table.concat(parts, "/")

	if fs.isFile(`{ROOT}/{path}`) then
		return path
	end
	if fs.isFile(`{ROOT}/{path}.luau`) then
		return path .. ".luau"
	end
	if fs.isFile(`{ROOT}/{path}/init.luau`) then
		return path .. "/init.luau"
	end

	-- `@self/foo` from a package's `src/init.luau`: Rojo also resolves `@self`
	-- against the package root (the `src` node itself), so try one level up.
	if isSiblingRequire then
		local up = dirname(moduleDir)
		local retry = path:gsub("^" .. moduleDir:escape(), up, 1)
		if fs.isFile(`{ROOT}/{retry}.luau`) then
			return retry .. ".luau"
		end
	end
	return nil
end

-- Globals for loaded modules. Lune keeps `table`, `type`, `pcall`, ... in the
-- running environment, not in `_G`, so capture the live one.
local GLOBALS = getfenv(1) :: any

-- `loadModule` and `makeLoader` call each other, so one must be
-- forward-declared.
local loadModule: (path: string) -> any

-- One loader closure per requiring file, capturing its directory.
local function makeLoader(modulePath: string): (name: string) -> any
	local moduleDir = dirname(modulePath)
	return function(name: string): any
		local target = resolve(moduleDir, name)
		assert(target, `cannot resolve '{name}' from '{modulePath}'`)
		return loadModule(target)
	end
end

function loadModule(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	local chunk = assert(loadstring(fs.readFile(`{ROOT}/{path}`), "@" .. path))
	cache[path] = true -- cycle guard: a later `return` overwrites this
	local env = setmetatable({ require = makeLoader(path) }, { __index = GLOBALS })
	setfenv(chunk, env)
	local ok, result = pcall(chunk)
	assert(ok, result)
	cache[path] = result
	return result
end

-- Load a package's entry module by DataModel node name (`Object`, `Map`, ...).
local function loadPackage(name: string): any
	local dir = PACKAGE_DIRS[name]
	assert(dir, `unknown package '{name}'`)
	return loadModule(`{dir}/src/init.luau`)
end

return {
	loadPackage = loadPackage,
	loadFile = function(path: string): any
		return loadModule(path)
	end,
}
