# love.maker
love.maker is a library that can minify, compile and compress your LÖVE2D project folder.
This library includes URFS which provides access to the entire file system using absolute paths.
Lua script files are compiled using the "string.dump" function and are only compatible with the same version of LÖVE2D or LuaJIT.
Empty directories are not included in the generated .love project file.
This library was designed specifically for the LÖVE2D framework.

## Example

```Lua
love.maker = require("maker")
love.maker.setExtensions('lua', 'png', 'txt') -- include only the specifed extensions

local build = love.maker.newBuild("C://path/to/project/folder/")
build:ignore('/readme.txt') -- ignore specific files or folders
build:ignoreMatch('^/.git') -- ignore based on pattern matching
build:allow("/images/exception.jpg") -- whitelist a specific file

-- destination path
local sav = love.filesystem.getSaveDirectory()
local proj = love.filesystem.getIdentity()
local dest = sav.."/"..proj..".love"

build:save(dest, "DEMO") -- absolute path and comment/stamp
local comment = love.maker.getComment(dest) -- 
```

## Credits
Source code by 2dengine LLC (MIT License) https://github.com/2dengine/love.maker

Compression by Rami Sabbagh (MIT License) https://github.com/Rami-Sabbagh/LoveZip

Minification by Marcus 'ReFreezed' Thunström (MIT License) https://github.com/ReFreezed/DumbLuaParser

Un-Restricted File System by Ross Grams (MIT License)  https://github.com/rgrams/urfs

## Testing
Linux testing by gphg

Additional testing by the Love2D community https://love2d.org/forums/viewtopic.php?t=86893
