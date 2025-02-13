local lib = (...)
lib = lib:gsub('%.init$', '')
local build = require(lib..".build")

local lfs = love.filesystem
local source = lfs.getSource()
source = source:gsub('\\', '/')

--- The "maker" module is used to create .love files or read comments from existing .love files.
-- @module maker
-- @alias maker
local maker = {}

--- Sets the file extensions to be included in the .love file.
-- @tparam arguments ... List of file extensions
function maker.setExtensions(...)
  maker.ext = { ... }
end

--- Creates a new build from a specified project directory.
-- @tparam string gamepath Absolute path to your project
-- @treturn build New build object
function maker.newBuild(gamepath)  
  gamepath = (gamepath or source):gsub('\\', '/')
  
  local point = ''
  if gamepath and gamepath:gsub('/$', '') ~= source:gsub('/$', '') then
    point = os.tmpname():gsub('[/%.]', ''):gsub('\\', '/'):gsub('^/', '')
  end
  
  return build(maker, gamepath, point)
end

--- Returns the comment written to an existing .love file (ZIP file comment).
-- @tparam string path Absolute path to some .love file
-- @treturn string Previously saved comment or nil
-- @see build:save
function maker.getComment(path)
  path = path or source
  local file = assert(io.open(path, "rb"))
  assert(file:read(4) == "\80\75\3\4", "The specified resource is not a valid love package")
  
  local comment, offset
  local length = file:seek("end")
  for i = length - 22, math.max(length - 22 - 65535, 0), -1 do
    file:seek("set", i)
    if file:read(4) == "\80\75\5\6" then
      local ecdr = file:read(18)
      local lo, hi = ecdr:byte(17, 18)
      offset = i + 22
      comment = file:read(lo + hi*256)
      break
    end
  end
  file:close()
  return comment, offset
end

return maker
