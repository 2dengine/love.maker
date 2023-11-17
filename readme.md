# love.maker
love.maker is a library that can minify, compile and compress your LÖVE2D project folder.
love.maker uses URFS which provides access to the entire file system using absolute paths.
Lua script files are compiled using the "string.dump" function and are only compatible with the same version of LÖVE2D or LuaJIT.
Empty directories are not included in the generated .love project file.
love.maker was designed specifically for the LÖVE2D framework.

## Example

```Lua
-- destination path
local sav = love.filesystem.getSaveDirectory()
local proj = love.filesystem.getIdentity()

love.maker = require("maker")
local build = love.maker.newBuild("C://path/to/project/folder/")
build:save(sav.."/"..proj..".love")
```

## Credits
Library by 2dengine LLC (MIT License) https://github.com/2dengine/love.maker

Compression by Rami Sabbagh (MIT License) https://github.com/Rami-Sabbagh/LoveZip

Minification by Marcus 'ReFreezed' Thunström (MIT License) https://github.com/ReFreezed/DumbLuaParser

Un-Restricted File System by Ross Grams (MIT License)  https://github.com/rgrams/urfs

## Testing
Linux testing by gphg

Additional testing by the Love2D community https://love2d.org/forums/viewtopic.php?t=86893
