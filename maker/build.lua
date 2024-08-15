local lib = (...)
lib = lib:gsub('%.build$', '')
local urfs = require(lib..".urfs")
local lfs = love.filesystem

local zapi = require(lib..".zapi")
local parser = require(lib..".minify")
local minify = function(s)
  local ast = parser.parse(s)
  parser.minify(ast)
  return parser.toLua(ast)
end

return function(maker, gamepath, point)
  --- The "build" object is used to customize what is included or excluded in the generated .love file.
  -- @module build
  -- @alias build
  local build = {}
  local files = { [""] = true }
  local written = {}

  --- Checks if the file path is included.
  -- @tparam string path Relative file path
  -- @treturn boolean True if the file will be included
  function build:isAllowed(path)
    return files[path] == true
  end
  
  --- Marks a specific file for inclusion.
  -- @tparam string path Relative path
  -- @see build:isAllowed
  function build:allow(path)
    files[path] = true
  end

  --- Marks a specific path for exclusion.
  -- @tparam string path Relative path
  -- @see build:ignoreMatch
  function build:ignore(path)
    files[path] = nil
  end

  --- Marks paths for exclusion based on pattern matching.
  -- @tparam string pattern Pattern matching expression
  -- @see build:ignore
  function build:ignoreMatch(pattern)
    for item in pairs(files) do
      if item:match(pattern) then
        files[item] = nil
      end
    end
  end
  
  --- Writes a virtual file that will be included in the builds.
  -- @tparam string path File path
  -- @tparam string content Textual content
  function build:write(path, content)
    path = '/'..path:gsub('^/', '')
    local full = (point..'/'..path):gsub('//', '/')
    assert(not lfs.getInfo(full , 'directory'), 'Cannot write to directory')
    written[path] = content
    files[path] = true
  end
  
  --- This is an internal function.
  -- @tparam string prefix Path prefix
  -- @tparam string path Relative path
  -- @tparam function func Callback function
  function build:recursive(prefix, path, func)
    local full = (prefix..'/'..path):gsub('//', '/')
    if lfs.getInfo(full, 'directory') then
      for _, item in pairs(lfs.getDirectoryItems(full)) do
        build:recursive(prefix, path..'/'..item, func)
      end
    end
    local sav = lfs.getSaveDirectory()
    if lfs.getRealDirectory(full) ~= sav then
      func(full, path)
    end
  end

  --- This is an internal function.
  function build:scan()
    if point ~= '' then
      urfs.mount(gamepath, point)
      assert(#lfs.getDirectoryItems(point) > 0, 'The mounted directory is empty:'..gamepath)
      --urfs.unmount(gamepath, point)
    end
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
    if point ~= '' then
      urfs.unmount(gamepath)
    end
  end
  
  --- Packages the project into a .love file.
  -- The "mode" argument is used to optionally minify or compile the included .lua files.
  -- @tparam string dest Absolute path where the generated .love file is saved
  -- @tparam[opt] string comment String comment appended to the .love file
  -- @tparam[opt] string mode Processing mode: "none", "minify" or "dump"
  -- @treturn boolean True if the .love file was saved successfully
  -- @treturn number Number of bytes written or an error message
  function build:save(dest, comment, mode)
    local file, err = io.open(dest, 'wb')
    if not file then
      return false, err
    end
    if point ~= '' then
      urfs.mount(gamepath, point)
    end
    local zip = zapi.newZipWriter(file)
    for path in pairs(files) do
      local data = written[path]
      local modified
      if not data then
        local full = ('/'..point..path):gsub('//', '/')
        local info = lfs.getInfo(full)
        if info and info.type == "file" then
          data = lfs.read(full)
          modified = info.modtime
          if full:match("%.lua$") or full:match("%.ser$") then
            if mode == "minify" then
              data = minify(data, full, "minify")
            elseif mode == "dump" then
              local func, msg = loadstring(data, full)
              assert(func, msg)
              data = string.dump(func, true)
            end
          end
        end
      end
      if data then
        if path:sub(1, 1) == "/" then path = path:sub(2,-1) end
        if path:sub(-1, -1) == "/" then path = path:sub(1,-2) end
        zip.addFile(path, data, modified)
      end
    end
    zip.finishZip(comment)
    file:flush()
    --local size = file:getSize()
    local size = file:seek('end')
    file:close()
    if point ~= '' then
      urfs.unmount(gamepath)
    end
    return true, size
  end

  build:scan()

  return build
end