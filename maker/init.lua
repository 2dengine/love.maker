local lib = (...)
lib = lib:gsub('%.init$', '')
local zapi = require(lib..".zapi")
local parser = require(lib..".minify")
local urfs = require(lib..".urfs")

local lfs = love.filesystem
local source = lfs.getSource()

local minify = function(s)
  local ast = parser.parse(s)
  parser.minify(ast)
  return parser.toLua(ast)
end

local maker = {}

function maker.setExtensions(...)
  maker.ext = { ... }
end

function maker.newBuild(gamepath)  
  gamepath = (gamepath or source)..'/'
  gamepath = gamepath:gsub('\\', '/')
  gamepath = gamepath:gsub('//', '/')
  
  local point = os.tmpname():gsub('[/%.]', '')
  point = point:gsub('\\', '/')
  point = point:gsub('^/', '')
  
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

  function build:recursive(prefix, path, func)
    local full = (prefix..'/'..path):gsub('//', '/')
    if lfs.getInfo(full, 'directory') then
      for _, item in pairs(lfs.getDirectoryItems(full)) do
        build:recursive(prefix, path..'/'..item, func)
      end
    end
    --if lfs.getRealDirectory(full) == build.base then
      func(full, path)
    --end
  end

  function build:scan()
    urfs.mount(gamepath, point)
    local allowed = maker.ext or {}
    for _, v in ipairs(allowed) do
      allowed[v:lower()] = true
    end
    build:recursive(point, '', function(full, path)
      if #allowed > 0 then
        local ext = path:match("^.+%.(.+)$")
        if not ext or allowed[ext:lower()] then
          files[path] = true
        end
      else
        files[path] = true
      end
    end)
    urfs.unmount(gamepath)
  end
  
  function build:save(dest, comment, mode)
    local file, err = io.open(dest, 'wb')
    if not file then
      return false, err
    end
    urfs.mount(gamepath, point)
    local zip = zapi.newZipWriter(file)
    for path in pairs(files) do
      local full = ('/'..point..path):gsub('//', '/')
      local info = lfs.getInfo(full)
      if info and info.type == "file" then
        local data = lfs.read(full)
        if full:match("%.lua$") or full:match("%.ser$") then
          if mode == "minify" then
            data = minify(data, full, "minify")
          elseif mode == "dump" then
            local func, msg = loadstring(data, full)
            assert(func, msg)
            data = string.dump(func, true)
          end
        end
        if path:sub(1, 1) == "/" then path = path:sub(2,-1) end
        if path:sub(-1, -1) == "/" then path = path:sub(1,-2) end
        zip.addFile(path, data, info.modtime)
      end
    end
    zip.finishZip(comment)
    file:flush()
    --local size = file:getSize()
    local size = file:seek('end')
    file:close()
    
    urfs.unmount(gamepath)
    return true, size
  end

  build:scan()

  return build
end

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
