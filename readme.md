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
### Compression
RamiLego4Game: https://github.com/Rami-Sabbagh/LoveZip (MIT)

### Minification
ReFreezed: https://github.com/ReFreezed/DumbLuaParser (MIT)
stravant: https://github.com/aryajur/lua-minify (MIT)
aryajur: https://github.com/stravant/LuaMinify (MIT)

### Testing
gphg (Linux)