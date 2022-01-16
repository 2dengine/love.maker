# love.maker
love.maker is an automated distribution tool for Love2d that allows you to customize, build and output a minified .love file anywhere.

## Example

```Lua
-- destination path
local sav = love.filesystem.getSaveDirectory()
local proj = love.filesystem.getIdentity()
local dest = sav.."/"..proj..".love"

love.maker = require("maker.main")
local build = love.maker.newBuild("lua", "txt", "png", "zip") -- include ONLY the selected formats
build:ignore('/readme.txt') -- ignore specific files or folders
build:ignoreMatch('^/.git') -- ignore based on pattern matching
build:allow("/images/exception.jpg") -- whitelist a specific file
build:save(dest, "DEMO") -- absolute path and comment/stamp
local stamp = love.maker.getComment(dest) -- get the stamp
```

## Credits
RamiLego4Game (compression)
ReFreezed, stravant, aryajur (minification)