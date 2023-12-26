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
  local file, err = io.open(path, "rb")
  if not file then
    return nil, err
  end
  local comment
  local pos = file:seek("end", -22)
  for i = pos, 0, -1 do
    file:seek("set", i)
    if file:read(4) == "\80\75\5\6" then
      file:seek("set", i + 22)
      comment = file:read("*all")
      break
    end
  end
  file:close()
  return comment
end

return maker
