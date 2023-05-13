# love.maker
love.maker is a library for Love2d that allows you to customize, build and output a compiled or minified .love file anywhere.
The library is written in Lua with no external dependencies besides Love2d and is ideal for automation. 

## Example

```Lua
-- destination path
local sav = love.filesystem.getSaveDirectory()
local proj = love.filesystem.getIdentity()

love.maker = require("maker")
local build = love.maker.newBuild()
build:save(sav.."/"..proj..".love")
```

## Credits
RamiLego4Game (compression)
ReFreezed, stravant, aryajur (minification)
gphg (Linux testing)