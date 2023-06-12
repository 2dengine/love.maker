local lfs = love.filesystem
local sav = lfs.getSaveDirectory()
local src = lfs.getSource()
local lib = (...)
local zapi = require(lib..".zapi")
local parser = require(lib..".minify")

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
  local build = {}
  local files = { [""] = true }
  
  function build:copy(s)
    -- generate a temporary folder
    local tmp = os.tmpname():gsub('[/%.]', '').."/"
    tmp = tmp:gsub('\\', '/')
    local d = sav..tmp
    local o = love.system.getOS()
    local cmd
    if o == 'Windows' then
      cmd = string.format('xcopy "%s" "%s" /e /h /d /y', s:gsub('/', '\\'), d:gsub('/', '\\'))
    else
      cmd = string.format('cp -R "%s" "%s"', s, d)
    end
    --print(cmd)
    -- execute copy
    local handle = io.popen(cmd)
    handle:read("*a")
    handle:close()
    return tmp
  end
  
  function build:cleanup(tmp)
    build:recursive(tmp, '', function(path, full)
      lfs.remove(full)
    end)
    lfs.remove(tmp)
  end
  
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
    local full = prefix..path
    if lfs.getInfo(full, "directory") then
      for _, item in pairs(lfs.getDirectoryItems(full)) do
        build:recursive(prefix, path.."/"..item, func)
      end
    end
    if lfs.getRealDirectory(full) == build.base then
      func(path, full)
    end
  end

  function build:save(dest, comment, mode)
    local tmp = os.tmpname():gsub('[/%.]', '')
    tmp = tmp:gsub('\\', '/')
    local file, err1 = lfs.newFile(tmp, "w")
    if not file then
      return false, err1
    end
    local prefix = build.prefix
    local zip = zapi.newZipWriter(file)
    for path in pairs(files) do
      local full = path
      if prefix then
        full = (prefix..path):gsub('//', '/')
      end
      local info = lfs.getInfo(full)
      if info and info.type == "file" then
        local data = lfs.read(full)
        if full:match("%.lua$") or full:match("%.ser$") then
          if mode == "minify" then
            data = minify(data, full, "minify")
          elseif mode == "dump" then
            data = string.dump(loadstring(data, full), true)
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
    local ok, err2 = os.rename(sav..'/'..tmp, dest)
    os.remove(sav..'/'..tmp)

    if build.prefix then
      --build:cleanup(build.prefix)
      build.prefix = nil
    end

    return ok, err2 or size
  end
  
  function build:scan()
    local prefix = build.prefix or ''
    local allowed = maker.ext
    if allowed and #allowed > 0 then
      for _, v in ipairs(allowed) do
        allowed[v:lower()] = true
      end
      build:recursive(prefix, '', function(path, full)
        local ext = path:match("^.+%.(.+)$")
        if not ext or allowed[ext:lower()] then
          files[path] = true
        end
      end)
    else
      build:recursive(prefix, '', function(path, full)
        files[path] = true
      end)
    end
  end
  
  build.base = src
  build.prefix = nil
  if gamepath then
    build.base = sav
    build.prefix = build:copy(gamepath)
  end
  build:scan()
  
  return build
end

function maker.getComment(path)
  path = path or src
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
