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

love.system.openURL(sav)

love.fuser = require("fuser.main")
love.fuser.windows(dest, "example", 64)
love.fuser.windows(dest, "example", 32)
love.fuser.macos(dest, "example")
love.fuser.linux(dest, "example")