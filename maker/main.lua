local lfs = love.filesystem
local sav = lfs.getSaveDirectory()
local src = lfs.getSource()
local lib = (...):match("(.-)[^%.]+$")
local zapi = require(lib.."zapi")
local minify = require(lib.."minify")

local function recursive(path, func)
  if lfs.getInfo(path, "directory") then
    for _, item in pairs(lfs.getDirectoryItems(path)) do
      recursive(path.."/"..item, func)
    end
  end
  if lfs.getRealDirectory(path) == src then
    func(path)
  end
end

local maker = {}

function maker.newBuild(...)
  local build = {}
  local files = { [""] = true }
  
  function build:allow(path)
    files[path] = true
  end

  function build:isAllowed(path)
    return files[path] == true
  end

  function build:ignore(path)
    files[path] = nil
  end

  function build:ignoreMatch(pattern)
    for item in pairs(files) do
      if item:match(pattern) then
        files[item] = nil
      end
    end
  end

  function build:save(dest, comment, mode)
    local tmp = os.tmpname():gsub("\\", "/")
    local file, err1 = lfs.newFile(tmp, "w")
    if not file then
      return false, err1
    end
    local zip = zapi.newZipWriter(file)
    for path in pairs(files) do
      local info = lfs.getInfo(path)
      if info and info.type == "file" then
        local data = lfs.read(path)
        if path:match("%.lua$") or path:match("%.ser$") then
          if mode == "minify" then
            data = minify(data, path, "minify")
          elseif mode == "dump" then
            data = string.dump(loadstring(data, path), true)
          end
        end
        if path:sub(1, 1) == "/" then path = path:sub(2,-1) end
        if path:sub(-1, -1) == "/" then path = path:sub(1,-2) end
        zip.addFile(path, data, info.modtime)
      end
    end
    zip.finishZip(comment)
    file:flush()
    local size = file:getSize()
    file:close()
    os.remove(dest)
    local ok, err2 = os.rename(sav..tmp, dest)
    os.remove(sav..tmp)
    return ok, err2 or size
  end
  
  local allowed = {...}
  if #allowed > 0 then
    for _, v in ipairs(allowed) do
      allowed[v:lower()] = true
    end
    recursive("", function(path)
      local ext = path:match("^.+%.(.+)$")
      if not ext or allowed[ext:lower()] then
        files[path] = true
      end
    end)
  else
    recursive("", function(path)
      files[path] = true
    end)
  end
  return build
end

function maker.getComment(path)
  path = path or lfs.getSource()
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