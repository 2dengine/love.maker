# love.maker
love.maker is a library for Love2d that allows you to customize, build and output a compiled or minified .love file anywhere.
The library is written in Lua with no external dependencies besides Love2d and is ideal for automation. 

## Example

```Lua
-- destination path
local sav = love.filesystem.getSaveDirectory()
local proj = love.filesystem.getIdentity()

love.maker = require("maker")
local build = love.maker.newBuild("C://path/to/project/folder/")
build:save(sav.."/"..proj..".love")
```
## Limitations
* Folders located outside of the currently active Love2D directory are copied to the AppData folder before processing
* Empty directories are not included in the generated file
* Does not fuse games

## Credits
Library by 2dengine LLC (MIT License) https://github.com/Rami-Sabbagh/LoveZip

Compression by Rami Sabbagh (MIT License) https://github.com/Rami-Sabbagh/LoveZip

Minification by Marcus 'ReFreezed' Thunström (MIT License) https://github.com/ReFreezed/DumbLuaParser

## Testing
Linux testing by gphg

Additional testing by the Love2D community https://love2d.org/forums/viewtopic.php?t=86893